# Llama-Chat.psm1
# Contains chat functionality.
# TODO count 1

# To chat with the chosen LLM.
# You may use use llama-server or llama-cli.
# Llama.cpp-Toolbox will automaticly manage the options for threads, ngl, context.
# The option for number of threads is retrieved from the PC then inserted after all args.
# The value for number of GPU layers is retrieved from the model, if the model fails to load it will try to offload layers to CPU until it runs using your setting for minimum context.
# The value for maximum context is retrieved from the model, your config setting for minimum context will be used when trying to find an optimum value for NGL and Context.
# Config.txt: For llama-server, choose your port then place args after the port "llama-server 8080 your_args"
# Config.txt: For llama-cli, place args after the script name "llama-cli your_args"
# TODO, llama-cli is not handled yet, should this just be opened in a new PS window?

# Llama-Chat version
$global:Llama_Chat_Ver = 0.2.1

function LlamaChat ($selectedModel, $selectedScript) {
    if ($selectedModel -match ".gguf") {}else{break} # Only process the .gguf models
    $logsPath = "$path\logs\inference"
    if(!(Test-Path $logsPath)){mkdir $logsPath}
    # Extract parts from the selected item in the combobox.
    $executable = $selectedScript.Split(' ')[0] # The executable to run.
    $selectedModel # Selected LLM from dropdown list.
    $nthreads = [Environment]::ProcessorCount #$NumberOfCores
    
    $originalArgs = "" # Initialize the var.
    # First, ensure $args is properly initialized
    if ($executable -match "llama-server") {
        $port = $selectedScript.Split(' ')[1]
        $originalArgs = "--port $port "
    } else {
        $originalArgs = ""
    }

    # Prepare arguments from provided text.
    foreach ($arg in ($selectedScript.Split(' '))) {
        if (($arg -ne $executable) -and ($arg -ne $port)) {
            $originalArgs += "$arg "
        }
    }

    function Get-ChatsSettings ($selectedModel) {
        # Define path for chat-settings.json file
        $settingsFilePath = Join-Path -Path "$path\lib\settings" -ChildPath "chat-settings.json"
    
        # Check if settings file exists and try to parse content
        if (Test-Path -Path $settingsFilePath) {
            try {
                $jsonData = Get-Content -Path $settingsFilePath -Raw | ConvertFrom-Json
            
                Write-Host "All models in JSON:" -ForegroundColor Cyan
                $jsonData.models | ForEach-Object {
                    Write-Host "  Model name: $($_.name)" -ForegroundColor Green
                }
            
                Write-Host "`nLooking for model: $selectedModel" -ForegroundColor Yellow
            
                $modelSettings = $jsonData.models | Where-Object { $_.name -eq $selectedModel }
            
                if ($modelSettings) {
                    Write-Host "Found matching model settings!" -ForegroundColor Green
                    return $modelSettings
                } else {
                    Write-Host "No settings found for model: $selectedModel" -ForegroundColor Red
                }
            } catch {
                Write-Warning "Failed to parse chat settings: $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Settings file not found at: $settingsFilePath"
        }
        return $null
    }

    # Function to safely extract parameter values
    function Get-ParameterValue {
        param(
            [string]$argsString,
            [string]$paramName
        )
    
        if ($argsString -match "\s$paramName\s+(\S+)") {
            return $matches[1]
        }
        return $null
    }

    $ChatSettings = Get-ChatsSettings $selectedModel
    $Optimal_CTX = $ChatSettings.Optimal_CTX
    $Optimal_NGL = $ChatSettings.Optimal_NGL

    # Extract -c and -ngl values more reliably
    $extractedCTX = Get-ParameterValue -argsString $originalArgs -paramName "-c"
    $extractedNGL = Get-ParameterValue -argsString $originalArgs -paramName "-ngl"

    if ($extractedCTX) { $Optimal_CTX = $extractedCTX }
    if ($extractedNGL) { $Optimal_NGL = $extractedNGL }

    # For debugging
    Write-Host "Args string: $originalArgs"
    Write-Host "Extracted CTX: $Optimal_CTX"
    Write-Host "Extracted NGL: $Optimal_NGL"

    if($Optimal_CTX -ne $null){
        Set-Location -Path $path\logs\inference # Logs will be saved here.
        $logPath = "$path\logs\inference\$selectedModel.log"
        $modelPath = "$path\Converted\$selectedModel"
        $llamaExePath = "$path\llama.cpp\build\bin\Release\$executable"
        $arguments = "$originalArgs --log-file $logPath -c $Optimal_CTX -ngl $Optimal_NGL -t $nthreads" # Set the dynamic args.
        $command = "$llamaExePath -m $modelPath $arguments" # Write the command to run.
        $TextBox2.Text = "Set-Location -Path $path\logs; $command" # Provide the command for the user to review.

        function Start-LlamaServer {
            param(
                [string]$modelPath,
                [string]$llamaExePath,
                [string]$arguments,
                [int]$contextLength,
                [int]$ngl,
                [int]$nthreads,
                [string]$logPath
            )

            $serverArgs = "-m $modelPath $arguments --log-file $logPath -c $contextLength -ngl $ngl -t $nthreads"
    
            try {
                "" | Out-File -FilePath $logPath -Force
                $process = Start-Process -FilePath $llamaExePath -ArgumentList $serverArgs -PassThru -NoNewWindow
        
                $timeout = 30
                $startTime = Get-Date
        
                while (!$process.HasExited -and ((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
                    Start-Sleep -Milliseconds 500
            
                    try {
                        $logContent = Get-Content -Path $logPath -Raw
                        if ($logContent -match "main: model loaded") {
                            Write-Host "Server started successfully"
                            return $process
                        }
                        if ($logContent -match "Error|OutOfDeviceMemory") {
                            throw "Server failed to start: Memory or other error detected"
                        }
                    }
                    catch {
                        Write-Host "Warning: Could not read log file. Continuing to monitor process."
                    }
                }
        
                throw "Server startup timed out or failed"
            }
            catch {
                if ($process -and !$process.HasExited) {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                }
                throw
            }
        }

        #$ChatSettings = Get-ChatsSettings $selectedModel
        try {
            $process = Start-LlamaServer `
                -modelPath "$path\Converted\$selectedModel" `
                -llamaExePath "$path\llama.cpp\build\bin\Release\$executable" `
                -args $arguments `
                -contextLength $ChatSettings.Optimal_CTX `
                -ngl $ChatSettings.Optimal_NGL `
                -nthreads $nthreads `
                -logPath "$path\logs\inference\$selectedModel.log"
    
            $TextBox2.Text = "Server started successfully"
        }
        catch {
            $label3.Text = "Loading failed..."
            $TextBox2.Text = $_.Exception.Message
            Write-Host $_.Exception.Message
        }

    }
    else {
        $option = "metadata" # Request all metadata.
        $print = 0 # Do not print.
        $value = ggufDump $selectedModel $option $print # Set the option needed to retrieve all metadata then retrieve the following values.
        $global:cfg = "minCtx"; $cfgCTX = RetrieveConfig $global:cfg # get-set the flag for $cfgCTX then retrieve it's value.
        $minCtx = [int]$cfgCTX # The users prefered minimum usable context value.
        
        # Retrieve maximum context length
        if($value -match "context"){$matchingKey = ($value | Get-Member -Name *"context_length").Name | Where-Object { $_ -like "*context_length*" } | Select-Object -First 1
            if ($value | Get-Member -Name $matchingKey){
                if ($value.$matchingKey.value){
                    $maxContext = $value.$matchingKey.value
                }
            }
        }
        # Retrieve max number of Gpu Layers "ngl"
        if($value -match "block_count"){$matchingKey = ($value | Get-Member -Name *"block_count").Name | Where-Object { $_ -like "*block_count*" } | Select-Object -First 1
            if ($value | Get-Member -Name $matchingKey){
                if ($value.$matchingKey.value){
                    $maxNGL = $value.$matchingKey.value + 1
                }
            }
        }

        while (!$runningProcesses -and $NGL -ne 0 ){
            $optimumArgs = Get-OptimumArgs $executable $selectedModel $minCtx $maxContext $maxNGL
            #write-host $optimumArgs
            $context = $optimumArgs.Split(',')[0]
            $NGL = $optimumArgs.Split(',')[1]
            Set-Location -Path $path\logs\inference # Logs will be saved here.
            $logPath = "$path\logs\inference\$selectedModel.log"
            $modelPath = "$path\Converted\$selectedModel"
            $llamaExePath = "$path\llama.cpp\build\bin\Release\$executable"

            function StopProcess{
                # Check if the process is still running.
                $runningProcesses = Get-Process | Where-Object { $_.Name -like "*$executable*" }
                $processName = $executable

                # Check if the process exists.
                if ($runningProcesses | Where-Object { $_.ProcessName -eq $processName }) {
                    # Stop old process if it's still running.
                    Get-Process | Where-Object {$_.Name -like "*$executable*"} | Stop-Process 
                    Start-Sleep -Seconds 5
                }
            }

            #cls # Clear the screen
            $arguments = "$originalArgs --log-file $logPath -c $context -ngl $NGL -t $nthreads" # Set the dynamic args.
            $command = "$llamaExePath -m $modelPath $arguments" # Write the command to run.
            $TextBox2.Text = "Set-Location -Path $path\logs; $command" # Provide the command for the user to review.
            try {$job = Start-Job -ScriptBlock { Invoke-Expression $args[0] } -ArgumentList $command # Try the command.
                    $jobId = $job.Id
                    Wait-Job -Job $job -Timeout 20 -ErrorAction SilentlyContinue
            }
            catch [Exception] {$label3.Text = "Loading failed..." ; $TextBox2.Text = $_.Exception.Message
                if ($_.Exception.Message){Write-Host $_.Exception.Message}
            }

            function SaveSettings ($selectedModel,$context,$NGL) {
                $optimalCTX = $context
                $optimalNGL = $NGL

                # Define path for chat-settings.json file
                if (!(Test-Path -Path "$path\lib\settings")) {
                    mkdir "$path\lib\settings" | Out-Null
                }

                $settingsFile = Join-Path -Path "$path\lib\settings" -ChildPath "chat-settings.json"

                # Load existing settings or create a new array if the file doesn't exist
                if (Test-Path -Path $settingsFile) {
                    $data = Get-Content -Path $settingsFile -Raw | ConvertFrom-Json
                } else {
                    $data = @{ models = @() }
                }

                # Add new model settings to the models array
                $data.models += @{
                    name = $selectedModel
                    optimal_CTX = $optimalCTX
                    optimal_NGL = $optimalNGL
                }

                ConvertTo-Json -InputObject $data | Set-Content -Path $settingsFile

                Write-Host "Saved optimal configuration for model $selectedModel to chat-settings.json"
            }

            # Check if the process is still running.
            $runningProcesses = Get-Process | Where-Object { $_.Name -like "*$executable*" }
            $processName = $executable

            # If the process exists show the UI, otherwise try again.
            if ($runningProcesses | Where-Object { $_.ProcessName -eq $processName }) {
                $label3.Text = "$selectedModel Loaded."
                Start-Process "http://localhost:$port"
                Write-Host "The process '$processName' is running."
            } else {
                $NGL = $NGL - 1
                Write-Host "The process '$processName' is not running."
            }

            # If the model can be used 
            if($NGL -eq 0){$label3.Text = "$selectedModel failed to load."
            Write-Warning "This model could not be loaded."
            break
            }
            else{SaveSettings $selectedModel $context $NGL ; return $runningProcesses ; break}
        }
    }
}

Export-ModuleMember -Function * -Variable * -Alias *