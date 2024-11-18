# Optimizer version
$global:Optimizer_Ver = 0.1.2

function TestPort{
    $startPort = 10000
    $endPort = 20000

    #Write-Host "Searching for available port between $StartPort and $EndPort..."
    
    for ($Tport = $StartPort; $Tport -le $EndPort; $Tport++) {
        $tcpListener = $null
        try {
            $tcpListener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
            $tcpListener.Start()
            
            # If we get here, the port is available
            return $Tport
        }
        catch {
            # Port is in use, continue to next port
            continue
        }
        finally {
            if ($tcpListener -ne $null) {
                $tcpListener.Stop()
            }
        }
    }
    
    throw "No available ports found between $StartPort and $EndPort"
}

function Get-OptimumArgs ($executable, $selectedModel, $minCtx, $maxCtx, $maxNGL) {
    $testPort = TestPort
    $modelPath = "$path\Converted\$selectedModel"
    $logsPath = "$path\logs\inference"
    $serverExePath = "$path\llama.cpp\build\bin\Release\$executable"

    # Function to run the server and monitor its output
    function Test-Configuration ($contextLength, $ngl) {
        $serverArgs = "-m $modelPath -ngl $ngl -t 16 --port $testPort -c $contextLength"
        $logFile = "$logsPath\llama-server.log"
    
        try {
            "" | Out-File -FilePath $logFile -Force
        }
        catch {
            Write-Host "Warning: Could not create new log file. Using fallback method."
            $logFile = "$logsPath\llama-server.log"
            "" | Out-File -FilePath $logFile -Force
        }

        try {
            $process = Start-Process -FilePath $serverExePath -ArgumentList $serverArgs -PassThru -RedirectStandardError $logFile -NoNewWindow

            $timeout = 30
            $startTime = Get-Date
        
            while (!$process.HasExited -and ((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
                Start-Sleep -Milliseconds 500
            
                try {
                    $logContent = Get-Content -Path $logFile -Raw
                    if ($logContent -match "main: model loaded") {
                        Write-Host "Success: NGL $ngl with context length $contextLength works"
                        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                        return $true
                    }
                    if ($logContent -match "Error|OutOfDeviceMemory") {
                        Write-Host "Failure: NGL $ngl with context length $contextLength is too high"
                        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                        return $false
                    }
                }
                catch {
                    Write-Host "Warning: Could not read log file. Continuing to monitor process."
                }
            }

            Write-Host "Timeout or unclear result for NGL $ngl with context length $contextLength"
            if (!$process.HasExited) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
            return $false
        }
        catch {
            Write-Host "Error occurred: $_"
            return $false
        }
        finally {
            if (Test-Path $logFile) {
                Remove-Item $logFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Function to find optimal context length for a given NGL
    function Find-OptimalContextLength ($ngl, $floor, $ceiling) {
        # Ensure floor and ceiling are multiples of 1024
        $floor = [math]::Ceiling($floor / 1024) * 1024
        $ceiling = [math]::Floor($ceiling / 1024) * 1024
    
        Write-Host "Finding optimal context length for NGL $ngl"
        Write-Host "Testing floor value: $floor"
        $floorWorks = Test-Configuration $floor $ngl
        if (!$floorWorks) {
            Write-Host "Floor value doesn't work for NGL $ngl"
            return 0
        }

        Write-Host "Testing ceiling value: $ceiling"
        $ceilingWorks = Test-Configuration $ceiling $ngl
        if ($ceilingWorks) {
            Write-Host "Ceiling value works for NGL $ngl"
            return $ceiling
        }

        $lastWorkingValue = $floor
        $lowestFailingValue = $ceiling

        # Binary search with 1024 step alignment
        while (($lowestFailingValue - $lastWorkingValue) -gt 1024) {
            $mid = [math]::Floor(($lastWorkingValue + ($lowestFailingValue - $lastWorkingValue) / 2) / 1024) * 1024
        
            Write-Host "Testing context length: $mid"
            if (Test-Configuration $mid $ngl) {
                $lastWorkingValue = $mid
            } else {
                $lowestFailingValue = $mid
            }
        }
    
        return $lastWorkingValue
    }

    # Main execution
    # Clean up any existing processes
    Get-Process -Name "llama-server" -ErrorAction SilentlyContinue | Stop-Process -Force

    # Find optimal NGL and context length
    $optimalNGL = 0
    $optimalCTX = 0
    
    # Start with maximum NGL and work down if necessary
    for ($ngl = $maxNGL; $ngl -ge 0; $ngl--) {
        Write-Host "Testing NGL: $ngl"
        $ctx = Find-OptimalContextLength $ngl $minCtx $maxCtx
        
        if ($ctx -ge $minCtx) {
            $optimalNGL = $ngl
            $optimalCTX = $ctx
            break
        }
    }

    if ($optimalCTX -eq 0) {
        Write-Host "Could not find a working configuration"
        return "0,0"
    }

    # Output results
    #Read-Host "Optimal configuration found: NGL=$optimalNGL, Context Length=$optimalCTX"

    # Final cleanup
    Get-Process -Name "llama-server" -ErrorAction SilentlyContinue | Stop-Process -Force

    return "$optimalCTX,$optimalNGL"
}

Export-ModuleMember -Function * -Variable * -Alias *