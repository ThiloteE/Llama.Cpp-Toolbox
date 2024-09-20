# Toolbox-Functions.psm1
# Contains the functions.

# Toolbox-Functions version
$global:version_func = "0.1.x"

# Check the version, run UpdateConfig if needed.
function VersionCheck {
    $global:cfg = "rebuild"; $global:rebuild = RetrieveConfig $global:cfg # get-set the flag for $rebuild.
    $global:cfg = "Llama.Cpp-Toolbox"; $global:cfgVersion = RetrieveConfig $global:cfg # get-set the flag for old Toolbox version.
    if ($version -ne $global:cfgVersion){
    $global:cfgValue = $version ; EditConfig $global:cfg # Update config with new value.
    # Get the version of the config text, if it matches the file we can skip this update.
    $global:cfg = "Config-Version"; $global:cfgVersion = RetrieveConfig $global:cfg # get-set the flag for version.
    if ($cfgVersion -ne $version_cfg){
        $global:cfgValue = $version_cfg ; EditConfig $global:cfg # Update config with new value.
        UpgradeConfig
        } # Update the config with new functionality as needed.
    }
}

# Get list of models
function ListModels {
    $subdirectories = Get-ChildItem -Path $models -Directory
    if($ComboBox_llm.Items -ne $null){$ComboBox_llm.Items.Clear()}
    foreach ($dir in $subdirectories) {
        $ComboBox_llm.Items.Add($dir.Name)
    }
    $files = Get-ChildItem -Path "$path\Converted\" -File
    foreach ($file in $files) {
        $ComboBox_llm.Items.Add($file.Name)
    }
}

# Get list of scripts from config.
function ListScripts {
    $ComboBox2.Items.Clear()
    Get-Content -Path "$path\config.txt" | Where-Object {$_.TrimStart().StartsWith("show¦")} | ForEach-Object {
        $ComboBox2.Items.Add($_.Split('¦')[1].Trim())
    }
}

# Get list of combobox items for ConfigForm.
function Get-ComboBoxItems ($global:labelText) {
    $comboBox.Items.Clear()
    if ($labelText -eq "build"){$items = @("cpu", "vulkan", "cuda")}
    foreach ($item in $items) {
        $comboBox.Items.Add($item)
    }

}

# Create and update .gitignore if something is tracked it will not be ignored.
function GitIgnore {
    Set-Location $Path
    New-Item -ItemType File -Path "$Path\.gitignore" -Force # Remove the old file to keep it updated with potential changes to git tracking.
    $newList = @()
    $data = git status --porcelain
    foreach ($item in $data) {
      if ($item -match "\?\?") {
        $parts = $item.Trim("\?\? ").Trim('"')
        $newList += $parts
      }
    }
    Set-Content -Path $path\.gitignore -Value $newList
}

# Convert the selected model from source file.
function ConvertModel {
	# Navigate to the directory where llama.cpp resides
	Set-Location -Path $path
	# Activate the virtual environment.
	.\venv\Scripts\activate
	# Select the model to convert.
    $selectedModel = $ComboBox_llm.selectedItem # Selected LLM from dropdown list.
    if ($ComboBox2.selectedItem -match "bpe"){$option = "--vocab-type bpe"}
    else{$option=''} # did they burn --outtype? It's still an option but stopped working.
    $convertScript = ($ComboBox2.selectedItem -split ' ', 2)[0].Trim() # Selected script for conversion.
    if (Test-Path $path\Converted\$selectedModel-f16.gguf){$note = "Existing file will be overwritten.";$halt = Confirm} # If the file exists then ask to overwrite.
    if (!$halt){
        if($halt -eq 0){Remove-Item $path\Converted\$selectedModel-f16.gguf}
        # Navigate to the directory containing conversion scripts.
        if ($convertScript -eq "convert_legacy_llama.py"){Set-Location $path\llama.cpp\examples}
        else{Set-Location $path\llama.cpp}
        $label3.Text = "Converting $selectedModel..."
        if ($convertScript -eq "convert_gptj_to_gguf.py"){try{accelerate}catch{pip install accelerate} Set-Location $path\lib\scripts; $command = "python $convertScript $models\$selectedModel"}
        else {$command = "python $convertScript $models\$selectedModel --outfile $path\Converted\$selectedModel-f16.gguf $option"}
        try {
            Invoke-Expression -Command "$command" # "Try" processing, run the command.
        } catch [Exception] {
            $TextBox2.Text = $_.Exception.Message  # Update textbox with error message
            $label3.Text = "Process failed..."
        }
        if ($_.Exception.Message){}
        else{
            $label3.Text = "$selectedModel Converted."
            $TextBox2.Text = "Model successfully exported to $path\Converted\$selectedModel-f16.gguf"
            ListModels}
    }
    deactivate # Deactivate (venv) python environment.
}

# Quantize the selected model from f16 or f32.
function QuantizeModel {
    # Navigate to the build directory where llama-quantize.exe resides
    Set-Location -Path $path\llama.cpp\build\bin\Release

    # Get selected model from dropdown list 1 ($ComboBox_llm)
    $selectedModel = $ComboBox_llm.selectedItem
    
    if ($selectedModel -match ".gguf") {
        # Get the new models name and prepare it to be used with the option later.
        if ($selectedModel -match "-f16"){$renameModel = ($ComboBox_llm.selectedItem -split "-f16", 2)[0].Trim()}
        if ($selectedModel -match "-f32"){$renameModel = ($ComboBox_llm.selectedItem -split "-f32", 2)[0].Trim()}
        # Extract parts from the selected item in the combobox.
        $executable = ($ComboBox2.selectedItem).Split(' ')[0] # The executable to run.
        $outtype = ($ComboBox2.selectedItem).Split(' ')[1] # The outtype which will also be used in the name.
        $nthreads = [Environment]::ProcessorCount #$NumberOfCores
        $args = "" # Empty list to be filled with all the args the user wants to apply.
            
        # Get arguments prepared
        foreach ($arg in (($ComboBox2.selectedItem).Split(' '))){
            if (($arg -ne $executable)-and($arg -ne $outtype)) {
                $args += "$arg "
            }
        }
        # Write-Host .\llama-quantize.exe $args.Trim() $path\Converted\$selectedModel $path\Converted\$renameModel-$outtype.gguf $outtype $nthreads # debug
        # Quantize the selected model with the new name, selected option and arguments.
        try { & .\llama-quantize.exe $args.Trim() $path\Converted\$selectedModel $path\Converted\$renameModel-$outtype.gguf $outtype $nthreads}
        catch [Exception] {$label3.Text = "Quantizing failed...";$TextBox2.Text = $_.Exception.Message}

        # Update the GUI
        if ($_.Exception.Message) {}
        else {
            $label3.Text = "$selectedModel Quantized using the following args: "+$args.Trim()+" $outtype $nthreads"
            $TextBox2.Text = "Model successfully exported to $path\Converted\$renameModel-$outtype.gguf"
            ListModels
        }
    }

    # If the selected model was not a gguf we can't do anything with it!
    else {
        $label3.Text = "Quantizing failed..."
        $TextBox2.Text = "You must select a .gguf model, either -f16 or -f32"
    }
}

# Get a list of models.
function ModelList {
    $fileList = Get-ChildItem -Path $path\Converted

    $label3.Text = "List of gguf models..."
    $option = "name"
    foreach ($file in $fileList) {
        $selectedModel = $file.Name
        # $model = ggufDump # I hate this slow and trash filled crap.
        $model = $file.Name -replace ("(-f\d+)|(-bf\d+)|(-iQ\d_.*)|(\.iQ\d_.*)|(-Q\d_.*)|(\.Q\d_.*)|(-gguf.*)|(\.gguf.*)","")
        if($list -notmatch $model){$list = $list +"$($model);`n"}
        }
    $TextBox2.Text = $list
}

# Pull metadata from any gguf using the gguf_dump script.
function ggufDump {
    # gguf_dump needs a $option and a $selectedModel to fucntion, send that when calling ggufDump.
    # use ($print = 1) if you want it to update the gui with data.
    if ($selectedModel -match ".gguf"){
        # Navigate to the directory where llama.cpp resides
        Set-Location -Path $path
        # Activate the virtual environment.
        .\venv\Scripts\activate
        # Path to the Python script
        $scriptPath = "$path\llama.cpp\gguf-py\scripts\gguf_dump.py"

        # Target directory containing GGUF files
        $ggufDir = "$path\Converted\"
        #$selectedModel = $ComboBox_llm.selectedItem #selectedModel is set where gguf_dump is called. # Selected LLM from dropdown list. 
        #$option = ($ComboBox2.selectedItem -split ' ', 2)[1].Trim() #option is set where gguf_dump is called.
    
        # Build the full path to the GGUF file
        $filePath = Join-Path $ggufDir $selectedModel

        # Run the Python script with JSON output and capture the result
        $fileContent = python $scriptPath --json --no-tensors $filePath
    
        $jsonData = ConvertFrom-Json -InputObject $fileContent
        $metadata = $jsonData.metadata
        $matchingKey = ($metadata | Get-Member -Name *"$option").Name | Where-Object { $_ -like "*$option*" } | Select-Object -First 1
        $label3Text = $matchingKey
        try {if ($metadata | Get-Member -Name $matchingKey){
            if ($metadata.$matchingKey.value){
                $value = $metadata.$matchingKey.value -replace "\n", "\n"}}}
            catch{
                if ($option -eq "dump"){
                $label3Text = "gguf_dump..."
                $value = $fileContent
                } elseif ($option -eq "keys"){
                $label3Text = "Metadata keys..."
                $value = $metadata
                } else {
                $label3Text = "$option does not exist, available metadata keys below."
                $value = $metadata
                }}
            finally{if ($print){$TextBox2.Text = $value; $label3.Text = $label3Text}}
        deactivate # Deactivate (venv) python environment.
        return $value
    }else{$label3.Text = "Failed...";$TextBox2.Text = "You must select a .gguf model to process."}
}

# Update Toolbox if updates found in repo.
function UpdateToolbox {
    cd $path
    $fetch = Invoke-Expression "git fetch" # Check for any updates using Git.
    $gitstatus = Invoke-Expression "git status"
    $TextBox2.Text = $gitstatus
    If ($gitstatus -match "pull") {# If updates exist get and build them.
        $label3.Text = "Updating..."
        $log_name = "Toolbox" # Send this to Log-GitUpdate for the file name.
        $gitstatus = Invoke-Expression "git pull"
        Update-Log
        Start-Process PowerShell -ArgumentList $path\LlamaCpp-Toolbox.ps1; [Environment]::Exit(1)
        }
    Else {$label3.Text = "No changes to Toolbox detected."}
}

# Update Llama.cpp if repo is changed or if updates found in repo.
function UpdateLlama {
    # The user needs to select a branch to build, thats when the flag is set true.
    $global:cfgValue = "False"; $global:cfg = "rebuild"; EditConfig $global:cfg # get-set the flag for $rebuild.
    cd $path\llama.cpp
    git checkout master
    $branch = Get-GitBranch
    $global:cfg = "branch"
    Set-GitBranch $branch.Trim()
    $fetch = Invoke-Expression "git fetch" # Check for any updates using Git.
    $gitstatus = Invoke-Expression "git status"
    $TextBox2.Text = $gitstatus
    $log_name = "llamaCpp" # Send this to Log-GitUpdate for the file name.
    If ($gitstatus -match "pull") {# If updates exist get and build them.
        $label3.Text = "Updating..."
        $gitstatus = Invoke-Expression "git pull"
        Update-Log
        $label3.Text = "Update completed, set a new branch to build."
        }
    Else {$label3.Text = "No changes to llama.cpp detected."}
    SetButton
}

# Install Llama.Cpp for the toolbox on first run.
function InstallLlama {
    Read-Host "Installing llama.cpp, any key to continue"
    Set-Location -Path $path
    mkdir $path\Converted
    git clone --progress --recurse-submodules https://github.com/ggerganov/llama.cpp.git
    pyenv local 3.11
    pip install cmake
    pyenv rehash
    python -m venv venv
    .\venv\Scripts\activate
    python -m pip install -r $path\llama.cpp\requirements.txt
    pyenv rehash
    deactivate
    Set-Location -Path $path\llama.cpp
    $branch = Get-NewRelease # Get the latest release version.
    Set-GitBranch $branch # Set the cfg to this branch then build it.
    BuildLlama
    Main # Everything is ready to start the GUI.
}

# Build Llama as needed.
function BuildLlama {
    $label3.Text = “The build flag clears after a rebuild is complete. Building..."
    $global:cfg = "build"; $build = RetrieveConfig $global:cfg # get-set the flag for $build.
    if($build -eq 'vulkan') {
 		cd $path\llama.cpp
		rd -r build
		mkdir build
		cmake -B .\build -DGGML_VULKAN=ON -DGGML_NATIVE=ON
		cmake --build build --config Release -j $NumberOfCores
	} elseif ($build -eq 'cuda') {
		cd $path\llama.cpp
		rd -r build
		mkdir build
		cmake -B .\build -DGGML_CUDA=ON -DGGML_NATIVE=ON
		cmake --build build --config Release -j $NumberOfCores
	} elseif ($build -eq 'cpu') {
		cd $path\llama.cpp
		rd -r build
		mkdir build
		cmake -B .\build -DGGML_NATIVE=ON
		cmake --build build --config Release -j $NumberOfCores
	}

$global:cfgValue = "False"; $global:cfg = "rebuild"; EditConfig $global:cfg # get-set the flag for $rebuild.
SetButton
$label3.Text = "Build completed."
}

# Determine the branch in use.
function Get-GitBranch {
    $gitBranch = (git branch | ? { $_ -match '\*' }) -replace '\*', ''
    return $gitBranch.Trim()
}

# Display and log the changes, after asigning a $log_name and using $gitstatus = Invoke-Expression "git pull".
function Update-Log {
    $gitstatusf = $gitstatus -replace '\|', [System.Environment]::NewLine # Format the text from git pull.
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    if (Test-Path $path\logs){}else{mkdir $path\logs} #if the logs dir does not exist make it.
    $gitstatusf | Out-File -FilePath "$path\logs\$timestamp-$version-$log_name.txt" -Force
    $TextBox2.Text = $gitstatusf
    }

# Change the branch to use, $branch is set when changed in ConfigForm.
function Set-GitBranch ($branch) {
    $global:cfg = "branch" ; $global:cfgValue = $branch.Trim(); EditConfig $global:cfg # Update config with new value.
    git submodule deinit -f --all
    git checkout $branch # Change branch using Git.
    git reset --hard $branch # Remove changes from other repo/branch.
    git submodule update --init --recursive
    $label3.Text = "Branch changed, remember to rebuild..."
}

# Change the repo to use, $repo is set when changed in ConfigForm.
function Set-GitRepo ($repo) {
    cd $path\llama.cpp
    $global:cfg = "repo" ; $global:cfgValue = $repo.Trim(); EditConfig $global:cfg # Update config with new value.
    git remote set-url origin https://github.com/$repo # Change repo using Git.
    $fetch = Invoke-Expression "git fetch" # Check for any changes using Git.
    git submodule deinit -f --all
    git reset --hard origin/master # Remove changes from other repo/branch.
    git submodule update --init --recursive
    UpdateLlama
    $label3.Text = "Repo changed, remember to rebuild..."
}

# Llama.Cpp releases use "b####" tags.
# Search all tags that start with 'b', sort them in descending order, select the most recent one.
function Get-NewRelease{
    
    $latestBTag = git tag -l "b*" | Sort-Object -Descending | Select-Object -First 1

    if ($latestBTag) {
        return $latestBTag
    }
}

# Make Symlink for a selected model in the directory you designated in config.
function SymlinkModel {
    $selectedModel = $ComboBox_llm.selectedItem # Selected LLM from dropdown list.
    if ($selectedModel -match ".gguf"){
        $global:cfg = "symlinkdir"; $symlinkdir = RetrieveConfig $global:cfg # get-set the flag for $symlinkdir.
        $note = "Admin permission required to create symlink in... $symlinkdir`n`nContinue?" ; $halt = Confirm # If the file exists then ask to overwrite.
        if($halt -eq 0){
            if(test-path $symlinkdir){}else{$note = "Create symlink directory in... $symlinkdir`n`nContinue?" ; $halt = Confirm ; if($halt -eq 0){mkdir $symlinkdir}}
            $command = "New-Item -Path $symlinkdir -Name $selectedModel -Value $path\Converted\$selectedModel -ItemType SymbolicLink"
            Start-Process -FilePath powershell.exe -ArgumentList "-ExecutionPolicy Bypass -Command $command" -Verb RunAs # Requests admin permission.
        }
        $errormsg = $Error[0].Exception.Message
        $output = "mklink $selectedModel $path\Converted\$selectedModel"
        if($halt-eq 1){$label3.Text = "Symlink provided!"}
        else{if ($errormsg){$label3.Text = $errormsg}
            else{$label3.Text = "Symlink created!"}}
        $TextBox2.Text = $output  # Provides a cmd prompt command which requires admin permission for the user even if they don't approve the automated symlink.
    }else{$label3.Text = "Failed...";$TextBox2.Text = "Select a .gguf to create a symlink"}
}

Export-ModuleMember -Function * -Variable * -Alias *
