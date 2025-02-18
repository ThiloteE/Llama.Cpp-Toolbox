# Llama-Chat.psm1
# Contains chat functionality.

# To chat with the chosen LLM.
# You may use use llama-server or llama-cli.
# Llama.cpp-Toolbox will automaticly manage the options for threads, ngl, context.
# The option for number of threads is retrieved from the PC then inserted after all args.
# The value for number of GPU layers is retrieved from the model, if the model fails to load it will try to offload layers to CPU until it runs using your setting for minimum context.
# The value for maximum context is retrieved from the model, your config setting for minimum context will be used when trying to find an optimum value for NGL and Context.
# For llama-server, choose your port then place args after the port "llama-server 8080 your_args"
# For llama-cli, place args after the script name "llama-cli your_args"

# Llama-Chat version
# Contains chat functionality with separate process management
$global:Llama_Chat_Ver = 0.2.5

# Add a hashtable to keep track of running processes
$global:RunningProcesses = @{}

# Function to get chat settings for a specific model
function Get-ChatsSettings {
    param([string]$selectedModel)
    
    # Define path for chat-settings.json file
    $settingsFilePath = Join-Path -Path "$path\lib\settings" -ChildPath "chat-settings.json"

    # Check if settings file exists and try to parse content
    if (Test-Path -Path $settingsFilePath) {
        try {
            $jsonData = Get-Content -Path $settingsFilePath -Raw | ConvertFrom-Json
            
            Write-Host "Looking for model: $selectedModel" -ForegroundColor Yellow
            
            $modelSettings = $jsonData.models | Where-Object { $_.name -eq $selectedModel }
            
            if ($modelSettings) {
                Write-Host "Found matching model settings." -ForegroundColor Green
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

function LlamaChat ($selectedModel, $selectedScript, $ProcessArray) {
    if ($selectedModel -match ".gguf") {
    
        $logsPath = "$path\logs\inference"
        if(!(Test-Path $logsPath)){mkdir $logsPath}
    
        $executable = $selectedScript.Split(' ')[0]
        $nthreads = $NumberOfCores
    
        $originalArgs = ""
        if ($executable -match "llama-server") {
            $port = $selectedScript.Split(' ')[1]
            $originalArgs = "--port $port "
        }
    
        foreach ($arg in ($selectedScript.Split(' '))) {
            if (($arg -ne $executable) -and ($arg -ne $port)) {
                $originalArgs += "$arg "
            }
        }

        $originalArgs = $originalArgs.Trim()

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

        function Start-LlamaChatProcess {
            param(
                [string]$modelPath,
                [string]$llamaExePath,
                [string]$arguments,
                [string]$logPath
            )

            try {
                # Create a unique identifier for this process
                $processId = [guid]::NewGuid().ToString()
            
                # Start the process in a new window
                $process = Start-Process -FilePath $llamaExePath `
                                        -ArgumentList "-m $modelPath $arguments --log-file $logPath" `
                                        -PassThru `
                                        -WindowStyle Normal
                  
                # Wait briefly to check if the process started successfully
                Start-Sleep -Seconds 3
                if ($process.HasExited) {
                    if ($process.ExitCode -ne 0) {
                        Write-Warning "Process exited with error: "$process.ExitCode
                    }
                    throw $process.StandardError
                }
                else {
                    # Add the process to our tracking hashtable
                    $global:RunningProcesses[$processId] = @{
                        Process = $process
                        Model = $selectedModel
                        Port = $port
                        LogPath = $logPath
                    }
                return $processId
                }
            }
            catch {
                Write-Warning "Failed to start process: $_"
                return $null
            }
        }

        function Stop-LlamaProcess {
            param([string]$processId)
        
            if ($global:RunningProcesses.ContainsKey($processId)) {
                $processInfo = $global:RunningProcesses[$processId]
                if (!$processInfo.Process.HasExited) {
                    Stop-Process -Id $processInfo.Process.Id -Force
                }
                $global:RunningProcesses.Remove($processId)
                return $true
            }
            return $false
        }

        # Use extracted -c and -ngl values from original args if provided.
        $extractedCTX = Get-ParameterValue -argsString $originalArgs -paramName "-c"
        $extractedNGL = Get-ParameterValue -argsString $originalArgs -paramName "-ngl"

        if ($extractedCTX) { $contextLength = $extractedCTX }
        if ($extractedNGL) { $ngl = $extractedNGL }

        # Get chat settings and prepare arguments
        if(!$extractedCTX -and !$extractedNGL) {$ChatSettings = Get-ChatsSettings $selectedModel}

        if ($ChatSettings) {
            $cfgCutLayers = Get-ConfigValue -Key "cutLayers" # get the value for $cfgCutLayers.
            $contextLength = $ChatSettings.Optimal_CTX
            $ngl = $ChatSettings.Optimal_NGL - $cfgCutLayers
        } else {
            $option = "metadata" # Request all metadata.
            $print = 0 # Do not print.
            $value = ggufDump $selectedModel $option $print # Set the option needed to retrieve all metadata then retrieve the following values.
            $cfgCTX = Get-ConfigValue -Key "minCtx" # get the value for $cfgCTX.
            $minCtx = [int]$cfgCTX # The users prefered minimum usable context value.
        
            if (!$contextLength -or !$ngl) {
                # Retrieve maximum context length
                if($value -match "context"){$matchingKey = ($value | Get-Member -Name *"context_length").Name | Where-Object { $_ -like "*context_length*" } | Select-Object -First 1
                    if ($value | Get-Member -Name $matchingKey){
                        if ($value.$matchingKey.value){
                            $maxCtx = $value.$matchingKey.value
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

                # determine if user needs an NGL
                $build = Get-ConfigValue -Key "build" # get the value for $build.
                if ($build -match "cpu"){$maxNGL = 0}

                # Determine optimal settings
                $TestArgs = Get-OptimumArgs "llama-server" $selectedModel $minCtx $maxCtx $maxNGL
                $contextLength = $TestArgs.Split(',')[0]
                $ngl = $TestArgs.Split(',')[1]
                SaveSettings $selectedModel $contextLength $ngl
            }
        }

        # determine if user needs an NGL
        $build = Get-ConfigValue -Key "build" # get the value for $build.
        if ($build -match "cpu"){$ngl = 0}

        # Start the process
        $processId = Start-LlamaChatProcess `
            -modelPath "$path\Converted\$selectedModel" `
            -llamaExePath "$path\llama.cpp\build\bin\Release\$executable" `
            -arguments "$originalArgs -c $contextLength -ngl $ngl -t $nthreads" `
            -logPath "$path\logs\inference\$selectedModel.log"
    
        if ($processId) {
            $label3.Text = "$selectedModel started successfully."
            $TextBox2.Text = "$executable $originalArgs -c $contextLength -ngl $ngl -t $nthreads --log-file $path\logs\inference\$selectedModel.log"
            if ($port) {
                Start-Process "http://localhost:$port"
            }
            return $processId
        } else {
            $label3.Text = "$selectedModel failed to start."
            $TextBox2.Text = "$executable $originalArgs -c $contextLength -ngl $ngl -t $nthreads --log-file $path\logs\inference\$selectedModel.log"
            return $null
        }
    }else{$label3.Text = "Failed...";$TextBox2.Text = "You must select a .gguf model to load."}
}

# Function to list all running processes
function Get-RunningLlamaProcesses {
    return $global:RunningProcesses
}

# Function to stop a specific process
function Stop-SpecificLlamaProcess {
    param([string]$processId)
    return Stop-LlamaProcess -processId $processId
}

# Function to stop all running processes
function Stop-AllLlamaProcesses {
    $processIds = @($global:RunningProcesses.Keys)
    foreach ($processId in $processIds) {
        Stop-LlamaProcess -processId $processId
    }
}

# Make sure to clean up processes when the module is removed
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Stop-AllLlamaProcesses
}

Export-ModuleMember -Function LlamaChat, Get-RunningLlamaProcesses, Stop-SpecificLlamaProcess, Stop-AllLlamaProcesses, Get-ChatsSettings -Variable *