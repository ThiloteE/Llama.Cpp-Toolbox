# Llama-Chat.psm1
# Contains chat functionality.
# TODO count 2

# To chat with the chosen LLM.
# You may use use llama-server or llama-cli.
# Llama.cpp-Toolbox will automaticly manage the options for threads, ngl, context.
# The option for number of threads is retrieved from the PC then inserted after all args.
# The option for number of GPU layers is retrieved from the model, if the model fails to load it will try to offload layers to CPU until it runs.
# The option for context is retrieved from the model, your config setting for max context is compared and the lower setting will be used. (TODO: should be a per model setting.)
# Config.txt: For llama-server, choose your port then place args after the port "llama-server 8080 your_args"
# Config.txt: For llama-cli, place args after the script name "llama-cli your_args"

# Llama-Chat version
$Llama_Chat_Ver = 0.1.0

function LlamaChat {
    # Extract parts from the selected item in the combobox.
    $executable = ($ComboBox2.selectedItem).Split(' ')[0] # The executable to run.
    $nthreads = [Environment]::ProcessorCount #$NumberOfCores
    if ($executable -match "llama-server"){$port = ($ComboBox2.selectedItem).Split(' ')[1];$args = "--port $port "} # The port which will be used to run the web client.
    else{$args = ""} # Empty list to be filled with all the args the user wants to apply.
            
    # Preparing the arguments from Config.txt, skip the exe and the port add the rest
    foreach ($arg in (($ComboBox2.selectedItem).Split(' '))){
        if (($arg -ne $executable)-and($arg -ne $port)) {
            $args += "$arg "
        }
    }
    $global:selectedModel = $ComboBox_llm.selectedItem # Selected LLM from dropdown list.
    $global:cfg = "maxCtx"; $cfgCTX = RetrieveConfig $global:cfg # get-set the flag for $cfgCTX then retrieve it's value.
    $global:option = "metadata"; $value = ggufDump $value # Set the option needed to retrieve all metadata then retrieve the following values.
    # Retrieve context length
    if($value -match "context"){$matchingKey = ($value | Get-Member -Name *"context_length").Name | Where-Object { $_ -like "*context_length*" } | Select-Object -First 1
        if ($value | Get-Member -Name $matchingKey){
            if ($value.$matchingKey.value){
                $maxContext = $value.$matchingKey.value
                if($maxContext -ge $cfgCTX){$context = $cfgCTX}
                else {$context = $maxContext}
            }
        }
    }
    # Retrieve max number of Gpu Layers "ngl"
    if($value -match "block_count"){$matchingKey = ($value | Get-Member -Name *"block_count").Name | Where-Object { $_ -like "*block_count*" } | Select-Object -First 1
        if ($value | Get-Member -Name $matchingKey){
            if ($value.$matchingKey.value){
                $NGL = $value.$matchingKey.value + 1
            }
        }
    }
    Set-Location -Path $path\logs # Logs will be saved here.
    $modelPath = "$path\Converted\$selectedModel"
    $llamaExePath = "$path\llama.cpp\build\bin\Release\$executable"

    # Check if the process is still running.
    $runningProcesses = Get-Process | Where-Object { $_.Name -like "*$executable*" }
    $processName = $executable

    # Check if the process exists.
    if ($runningProcesses | Where-Object { $_.ProcessName -eq $processName }) {
        # Stop old process if it's still running.
        Get-Process | Where-Object {$_.Name -like "*$executable*"} | Stop-Process 
        Start-Sleep -Seconds 5
    }

    while($NGL -gt 1){cls # Clear the screen
        $label3.Text = "Trying -ngl $NGL" # Inform the user how many layers we are trying to use.
        $arguments = "$args -c $context -ngl $NGL -t $nthreads" # Set the dynamic args.
        $command = "$llamaExePath -m $modelPath $arguments" # Write the command to run.
        $TextBox2.Text = "Set-Location -Path $path\logs; $command" # Provide the command for the user to review.
        try {$job = Start-Job -ScriptBlock { Invoke-Expression $args[0] } -ArgumentList $command # Try the command.
             $jobId = $job.Id
             Wait-Job -Job $job -Timeout 20 -ErrorAction SilentlyContinue
             Start-Sleep -Seconds 3
        }
        catch [Exception] {$label3.Text = "Loading failed..." ; $TextBox2.Text = $_.Exception.Message
            if ($_.Exception.Message){Write-Host $_.Exception.Message}
        }
        # Check if the process is still running.
        $runningProcesses = Get-Process | Where-Object { $_.Name -like "*$executable*" }
        $processName = $executable

        # If the process exists show the UI, otherwise try again.
        if ($runningProcesses | Where-Object { $_.ProcessName -eq $processName }) {
            $label3.Text = "$selectedModel Loaded."
            Start-Process "http://localhost:$port"
            Write-Host "The process '$processName' is running."
            break
        } else {
            $NGL = $NGL - 1
            Write-Host "The process '$processName' is not running."
        }
    } if($NGL -eq 1){$label3.Text = "$selectedModel failed to load." ; Write-Warning "This model could not be loaded."}
}

Export-ModuleMember -Function * -Variable * -Alias *