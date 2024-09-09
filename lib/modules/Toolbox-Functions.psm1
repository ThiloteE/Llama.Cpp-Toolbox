# Toolbox-Functions.psm1
# Contains the functions.

# Toolbox-Functions version
$version_func = "0.1.x"

# Update on request with confirmation, then restart GUI when it is updated.
function ConfirmUpdate(){
    $message = $note
    $title = "Confirm Update"
    $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $icon = [System.Windows.Forms.MessageBoxIcon]::Question
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        if (Test-Path Function:\$update) {&$update}
        if ($repo -match "3Simplex"){
            Set-Location $Path; git fetch; $gitstatus = Invoke-Expression "git status"
            $TextBox2.Text = "Llama.cpp: "+$TextBox2.Text + [System.Environment]::NewLine  + [System.Environment]::NewLine +  "Llama.cpp-Toolbox: "+$gitstatus
            If ($gitstatus -match "up to date") {
                $Label3.Text = $Label3.Text+" & No changes to Llama.cpp-Toolbox detected."
            }else{git pull; Start-Process PowerShell -ArgumentList $path\LlamaCpp-Toolbox.ps1; [Environment]::Exit(1)}
        }
    }
    if ($result -eq [System.Windows.Forms.DialogResult]::No) {}
}

# Get list of models
function ListModels{
    $subdirectories = Get-ChildItem -Path $models -Directory
    $ComboBox_llm.Items.Clear()
    foreach ($dir in $subdirectories) {
        $ComboBox_llm.Items.Add($dir.Name)
    }
    $files = Get-ChildItem -Path "$path\Converted\" -File
    foreach ($file in $files) {
        $ComboBox_llm.Items.Add($file.Name)
    }
}

# Get list of scripts from config.
function ListScripts{
    Get-Content -Path "$path\config.txt" | Where-Object {$_.TrimStart().StartsWith("show¦")} | ForEach-Object {
        $ComboBox2.Items.Add($_.Split('¦')[1].Trim())
    }
}

# Create and update .gitignore if something is tracked it will not be ignored.
function GitIgnore{
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

# Request confirmation from the user.
function Confirm(){
    $halt = 1 # Never procede without permission.
    $message = $note
    $title = "Confirm"
    $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $icon = [System.Windows.Forms.MessageBoxIcon]::Question
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {$halt=0;return $halt}
    if ($result -eq [System.Windows.Forms.DialogResult]::No) {$halt=1;return $halt}
}

# Convert the selected model from source file.
function ConvertModel{
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
function QuantizeModel{
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
function ModelList{
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
function ggufDump{
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

# Check for prerequisites and install as needed on first run or when CFG is not detected.
function PreReqs{
    if (python --version){$python = 1; Write-Host "(*) python is on path"}else{$python = 0; Write-Host "( ) python isn't ready"}
    if (pyenv){$pyenv = 1; Write-Host "(*) pyenv is ready"}else{$pyenv = 0; Write-Host "( ) pyenv isn't ready"}
    if (git help -g){$git = 1; Write-Host "(*) git is ready"}else{$git = 0; Write-Host "( ) git isn't ready"}
    if ($python -and $pyenv -and $git) {if (Test-Path "$path\llama.cpp"){}else{InstallToolbox}}
    else {
    if(-not $git){Read-Host "Installing git, any key to continue"; winget install --id Git.Git -e --source winget;InstallToolbox}
    if(-not $python){Read-Host "Installing python, any key to continue"; winget install -e --id Python.Python.3.11 --source winget
    }
    if(-not $pyenv){Read-Host "Installing pyenv, any key to continue"; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"}
    pyenv install 3.11
    pyenv rehash}
    CfgBuild
}

# Install the environment using git if it was not already done then run it.
function InstallToolbox{
    if ($path -notmatch "Llama.Cpp-Toolbox"){
        git clone https://github.com/3Simplex/Llama.Cpp-Toolbox.git
        while(!(Test-Path $path\Llama.Cpp-Toolbox\LlamaCpp-Toolbox.ps1)){Sleep 5}
        rm $path\LlamaCpp-Toolbox.ps1 # Remove the toolbox environment setup script continue with the installation.
        & $path\Llama.Cpp-Toolbox\LlamaCpp-Toolbox.ps1
        Exit
    }
    # The environment exists, continue.
}

# Install Llama.Cpp for the toolbox on first run.
function InstallLlama{
    Read-Host "Installing llama.cpp, any key to continue"
    cd $path
    mkdir $path\Converted
    git clone --progress --recurse-submodules https://github.com/3Simplex/llama.cpp.git
    pyenv local 3.11
    pip install cmake
    pyenv rehash
    python -m venv venv
    .\venv\Scripts\activate
    python -m pip install -r $path\llama.cpp\requirements.txt
    pyenv rehash
    deactivate
    if ($build -eq 'v') {
        cd $path\llama.cpp
        mkdir build
        cmake -B .\build -DGGML_VULKAN=ON -DGGML_NATIVE=ON
        cmake --build build --config Release -j $NumberOfCores
    } elseif ($build -eq 'c') {
        cd $path\llama.cpp
        mkdir build
        cmake -B .\build -DGGML_CUDA=ON -DGGML_NATIVE=ON
        cmake --build build --config Release -j $NumberOfCores
    } elseif ($build -eq 'cpu') {
        cd $path\llama.cpp
        mkdir build
        cmake -B .\build -DGGML_NATIVE=ON
        cmake --build build --config Release -j $NumberOfCores
    }
}

# Update Llama.cpp if repo is changed or if updates found in repo.
function UpdateLlama{
    $cfg = "repo"; $cfgRepo = RetrieveConfig $cfg # get-set the flag for repo.
    cd $path\llama.cpp
    if ($repo -ne $cfgRepo){$cfg = "repo"; $cfgValue = $repo; EditConfig $cfg # Update config with new value.
        git remote set-url origin https://github.com/$repo # Change repo using Git.
        $fetch = Invoke-Expression "git fetch" # Check for any changes using Git.
        $cfg = "branch"; $branch = RetrieveConfig $cfg # get-set the flag for $repo.
        git reset --hard origin/$branch # Remove changes from other repo/branch.
        BuildLlama # Get the changes and build them.
    } else {
    $fetch = Invoke-Expression "git fetch" # Check for any updates using Git.
    $gitstatus = Invoke-Expression "git status"
    $TextBox2.Text = $gitstatus
    If ($gitstatus -match "pull") {# If updates exist get and build them.
        BuildLlama
        }
    Else {$label3.Text = "No changes to llama.cpp detected."}
    }
}

# Build Llama as needed.
function BuildLlama{
    $cfg = "build"; $build = RetrieveConfig $cfg # get-set the flag for $build.
	$label3.Text = "New updates received. Updating, building and configuring..."
    $gitstatus = Invoke-Expression "git pull origin"
    $gitstatusf = $gitstatus -replace '\|', [System.Environment]::NewLine # Format the text from git pull.
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    if (Test-Path $path\logs){}else{mkdir $path\logs} #if the logs dir does not exist make it.
    $gitstatusf | Out-File -FilePath "$path\logs\$timestamp-$version-llamaCpp.txt" -Force
    $TextBox2.Text = $gitstatusf
    if($build -eq 'v') {
 		cd $path\llama.cpp
		rd -r build
		mkdir build
		cmake -B .\build -DGGML_VULKAN=ON -DGGML_NATIVE=ON
		cmake --build build --config Release -j $NumberOfCores
	} elseif ($build -eq 'c') {
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
$label3.Text = "Updating, building and configuring completed."
}

# Make Symlink for a selected model in the directory you designated in config.
function SymlinkModel{
    $selectedModel = $ComboBox_llm.selectedItem # Selected LLM from dropdown list.
    if ($selectedModel -match ".gguf"){
        $cfg = "symlinkdir"; $symlinkdir = RetrieveConfig $cfg # get-set the flag for $symlinkdir.
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
