Add-Type -AssemblyName System.Windows.Forms
$version = "0.24.1"
###### FIXME count 1 ######

$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = "Llama.cpp-Toolbox-$version"
$main_form.Width = 750
$main_form.Height = 300
$main_form.MinimumSize = New-Object System.Drawing.Size(750, 300)
$main_form.MaximumSize = New-Object System.Drawing.Size(750, 1000)

$menuStrip1 = New-object system.windows.forms.menustrip
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text   = "File"
$fileMenu.ShortcutKeyDisplayString="Ctrl+F"

$updaterLlama  = New-Object System.Windows.Forms.ToolStripMenuItem
$updaterLlama.Text = "Update Llama.cpp"
$updaterLlama.ShortcutKeyDisplayString="Ctrl+l"
$updaterLlama.Add_Click({$note = "This could break the Llama.cpp-Toolbox GUI.`n`nUpdate Toolbox gets a recent known working version of llama.cpp.`n`n Are you sure you want to proceed?"
    ;$update = "UpdateLlama";$repo = "ggerganov/llama.cpp.git";ConfirmUpdate}) # Change repo if not already used.

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

$updaterGui = New-Object System.Windows.Forms.ToolStripMenuItem
$updaterGui.Text = "Update Toolbox"
$updaterGui.ShortcutKeyDisplayString="Ctrl+g"
$updaterGui.Add_Click({$note = "Updating the Llama.cpp-Toolbox GUI.`n`nUpdate Toolbox also gets a recent known working version of llama.cpp.`n`n Are you sure you want to proceed?"
    ;$update = "UpdateLlama";$repo = "3Simplex/llama.cpp.git";ConfirmUpdate}) # Change repo if not already used.

$menuStrip1.Items.Add($fileMenu)
$fileMenu.DropDownItems.AddRange(@($updaterLlama,$updaterGui))

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text   = "Help"
$helpMenu.ShortcutKeyDisplayString="F1"

$aboutItem  = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutItem.Text = "About"
$aboutItem.Add_Click({AboutBox})

$menuStrip1.Items.Add($helpMenu)
$helpMenu.DropDownItems.AddRange(@($aboutItem))

$main_form.Controls.Add($menuStrip1)

# The directory where LlamaCpp-Toolbox.ps1 is initialized. 
$path = $PSScriptRoot
Set-Location $Path # Ensure we are starting on the right path.

# Define model path
$models = "$path\llama.cpp\models"

# Label for LLMs dropdown list.
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "LLMs:"
$Label.Location = New-Object System.Drawing.Point(110,33)
$Label.AutoSize = $true
$main_form.Controls.Add($Label)

# Dropdown list containing LLMs available to process.
$ComboBox1 = New-Object System.Windows.Forms.ComboBox
$ComboBox1.Width = 300
$ComboBox1.Location  = New-Object System.Drawing.Point(160,30)
$main_form.Controls.Add($ComboBox1)

# Get list of models
function ListModels {
    $subdirectories = Get-ChildItem -Path $models -Directory
    $ComboBox1.Items.Clear()
    foreach ($dir in $subdirectories) {
        $ComboBox1.Items.Add($dir.Name)
    }
    $files = Get-ChildItem -Path "$path\Converted\" -File
    foreach ($file in $files) {
        $ComboBox1.Items.Add($file.Name)
    }
}

# Dropdown list containing scripts to process using the selected LLM.
$ComboBox2 = New-Object System.Windows.Forms.ComboBox
$ComboBox2.Width = 150
$ComboBox2.Location  = New-Object System.Drawing.Point(465,30)
$main_form.Controls.Add($ComboBox2)

# Get list of scripts from config.
function ListScripts {
    Get-Content -Path "$path\config.txt" | Where-Object {$_.TrimStart().StartsWith("show¦")} | ForEach-Object {
        $ComboBox2.Items.Add($_.Split('¦')[1].Trim())
    }
}

# The config text for this release.
$cfgText = "Llama.Cpp-Toolbox¦$version
config.txt¦This file stores variables to be used for updates & customization. If this file is modified incorrectly, regret happens.
build¦master
repo¦3Simplex/llama.cpp.git
branch¦master
symlinkdir¦$path\Symlinks
show¦symlink
show¦model list
show¦convert-hf-to-gguf.py
show¦convert_gptj_to_gguf.py
show¦convert-legacy-llama.py
show¦convert-legacy-llama.py bpe
show¦llama-quantize.exe Q2_K
show¦llama-quantize.exe Q2_K_S
show¦llama-quantize.exe Q3_K
show¦llama-quantize.exe Q3_K_S
show¦llama-quantize.exe Q3_K_M
show¦llama-quantize.exe Q3_K_L
show¦llama-quantize.exe Q4_0
show¦llama-quantize.exe Q4_1
show¦llama-quantize.exe Q4_K
show¦llama-quantize.exe Q4_K_S
show¦llama-quantize.exe Q4_K_M
show¦llama-quantize.exe Q5_0
show¦llama-quantize.exe Q5_1
show¦llama-quantize.exe Q5_K
show¦llama-quantize.exe Q5_K_S
show¦llama-quantize.exe Q5_K_M
show¦llama-quantize.exe Q6_K
show¦llama-quantize.exe Q8_0
show¦llama-quantize.exe IQ4_NL
show¦llama-quantize.exe IQ4_XS
show¦llama-quantize.exe IQ3_XXS
show¦llama-quantize.exe IQ3_XS
show¦llama-quantize.exe IQ3_S
show¦llama-quantize.exe IQ3_M
show¦llama-quantize.exe IQ2_XXS
show¦llama-quantize.exe IQ2_XS
show¦llama-quantize.exe IQ2_S
show¦llama-quantize.exe IQ2_M
show¦llama-quantize.exe IQ1_S
show¦llama-quantize.exe IQ1_M
show¦gguf-dump.py dump
show¦gguf-dump.py keys
show¦gguf-dump.py architecture
show¦gguf-dump.py context_length
show¦gguf-dump.py head_count
show¦gguf-dump.py chat_template"

# Restore the config text.
function RestoreConfig{Add-Content -Path $path\config.txt -Value $cfgText} # Regenerate config if deleted.

# Retrieve a specific value within config.
function RetrieveConfig($cfg){
    $lines = Get-Content -Path $path\config.txt
    foreach ($line in $lines) {
        if ($cfg -eq $line.Split('¦')[0].Trim()) {
            $cfgValue = $line.Split('¦')[1].Trim()
            return $cfgValue  # Return the retrieved value
            break }  # Exit loop after finding the first match
        }
}

# Change a specific value within config.
function EditConfig($cfg){
    $lines = Get-Content -Path $path\config.txt
    foreach ($line in $lines) {
        if ($line.StartsWith($cfg+'¦')) {
            # Store the modified line in a temporary variable
            $tempLine = $line -replace '(?<=¦).*', $cfgValue
            # Replace the original line with the modified one
            $line = $tempLine
        }
        $newlines = $newlines+$line+"`n"
    }

    # Save the updated content back to the file
    Set-Content -Path $path\config.txt -Value $newlines
}

# Update the config text when new version is retrieved.
#FIXME edit config on update. Goodluck.
$cfg = "Llama.cpp-Toolbox"; $cfgVersion = RetrieveConfig $cfg # get-set the flag for version.
$Alines = $cfgText -split [Environment]::NewLine
function UpdateConfig{
    foreach ($line in $Alines){
        $cfg = $line.Split('¦')[0].Trim();
        $cfgValue = $line.Split('¦')[1].Trim();
        EditConfig $cfg
        }
}
#if ($version -ne $cfgVersion){UpdateConfig} # If it needs to be done do it. #Move this into the init when completed.

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


# Button to process a script.
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Size(620,29)
$Button1.Size = New-Object System.Drawing.Size(100,23)
$Button1.Text = "Process"
$main_form.Controls.Add($Button1)

# 'Process' button action. (confirmed)
$Button1.Add_Click({
    $label3.Text = "";$TextBox2.Text = "" # Clear the text.
    $selectedDirectory = $ComboBox1.selectedItem # Selected LLM from dropdown list.
    $selectedScript = $ComboBox2.selectedItem # Selected LLM from dropdown list.
        If ($selectedScript -match "model list") {ModelList} # Only requires Combobox2
        If ($selectedDirectory -eq $null) {$Label3.Text = "Select an LLM and script to process."}
        Else {If ($selectedScript -eq $null) {$Label3.Text = "Select a script to process the LLM."}
            ElseIf ($selectedScript -match "llama-quantize.exe") {QuantizeModel}
            ElseIf ($selectedScript -match "convert") {ConvertModel}
            ElseIf ($selectedScript -match "gguf-dump.py") {$selectedModel = $ComboBox1.selectedItem;$option = ($ComboBox2.selectedItem -split ' ', 2)[1].Trim();$print=1;ggufDump}
            ElseIf ($selectedScript -match "symlink") {SymlinkModel}
            else {$Label3.Text = "The script entered:$selectedScript was not handled."}
            }
    $print = 0 # Reset the flag so the screen wont show uncalled results.
    }
)

# Label  for Status
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Text = "Status:"
$Label2.Location  = New-Object System.Drawing.Point(5,65)
$Label2.AutoSize = $true
$main_form.Controls.Add($Label2)

# Label  to display Status
$Label3 = New-Object System.Windows.Forms.Label
$Label3.Text = ""
$Label3.Location  = New-Object System.Drawing.Point(60,65)
$Label3.AutoSize = $true
$main_form.Controls.Add($Label3)

# Button to check for update.
$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(5,29)
$Button.Size = New-Object System.Drawing.Size(100,23)
$Button.Text = "Update"
$main_form.Controls.Add($Button)

# 'Update' button action.
$Button.Add_Click({
    # Function to update from list of LLMs.
    $label3.Text = "";$TextBox2.Text = "" # Clear the text.
    $selectedDirectory = $ComboBox1.selectedItem # Selected LLM from dropdown list.
    If ($selectedDirectory -eq $null) {$Label3.Text = "Select LLM to process."}
    Else {
        Set-Location $models\$selectedDirectory
        # Check for any updates using Git.
        $gitstatus = Invoke-Expression "git status"
        $TextBox2.Text = $gitstatus
        If ($gitstatus -match "up to date") {
        $Label3.Text = "No changes to git detected."
            }
        Else {
        $Label3.Text =  'Fetching changes...'
        $output = Invoke-Expression "git pull origin"
        $TextBox2.Text = $output
        $Label3.Text =  'Model updated!'
            }
        }
    }
)

# Textbox for output.
$TextBox2 = New-Object System.Windows.Forms.TextBox
$TextBox2.Anchor = "Top, Left, Bottom"  # Resize with the form
$TextBox2.Multiline = $true
$TextBox2.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$TextBox2.Location  = New-Object System.Drawing.Point(10,120)
$TextBox2.MinimumSize = New-Object System.Drawing.Size(700, 130)  # Adjust width and minimum height
$main_form.Controls.Add($TextBox2)

# Label for LLMs to download.
$Label4 = New-Object System.Windows.Forms.Label
$Label4.Text = "Git Clone LLM from URL:"
$Label4.Location = New-Object System.Drawing.Point(5,93)
$Label4.AutoSize = $true
$main_form.Controls.Add($Label4)

# Textbox for LLMs URL.
$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Width = 320
$TextBox1.Location  = New-Object System.Drawing.Point(140,90)
$main_form.Controls.Add($TextBox1)

# Button to clone an LLM.
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Size(480,88)
$Button2.Size = New-Object System.Drawing.Size(100,23)
$Button2.Text = "Clone"
$main_form.Controls.Add($Button2)


# 'Clone' button action.
$Button2.Add_Click({
    # Function to clone from url.
    $label3.Text = "";$TextBox2.Text = "" # Clear the text.
    Set-Location $models
    $pattern = "(?<=.*)http\S+"
    $TextBox1.Text -match $pattern
    $cleanURL= $Matches[0]
    If ($cleanURL -ne $null) {
    $label3.Text = "Cloning..."
    git clone --progress $cleanURL
    $label3.Text = "Completed."
    }
    Else{$label3.Text = "No URL found."}
    ListModels
    }

)

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
    $selectedModel = $ComboBox1.selectedItem # Selected LLM from dropdown list.
    if ($ComboBox2.selectedItem -match "bpe"){$option = "--outtype f16 --vocab-type bpe"}
    else{$option='--outtype f16'}
    $convertScript = ($ComboBox2.selectedItem -split ' ', 2)[0].Trim() # Selected script for conversion.
    if (Test-Path $path\Converted\$selectedModel-f16.gguf){$note = "Existing file will be overwritten.";$halt = Confirm} # If the file exists then ask to overwrite.
    if (!$halt){
        if($halt -eq 0){Remove-Item $path\Converted\$selectedModel-f16.gguf}
        # Navigate to the directory containing conversion scripts.
        if ($convertScript -eq "convert-legacy-llama.py"){Set-Location $path\llama.cpp\examples}
        else{Set-Location $path\llama.cpp}
        $label3.Text = "Converting $selectedModel..."
        if ($convertScript -eq "convert_gptj_to_gguf.py"){try{accelerate}catch{pip install accelerate}$command = "python $convertScript $models\$selectedModel"}
        else {$command = "python $convertScript $models\$selectedModel $option"}
        try {
            & $command # "Try" processing, run the command.
        } catch [Exception] {
            $TextBox2.Text = $_.Exception.Message  # Update textbox with error message
            $label3.Text = "Process failed..."
        }
        if ([Exception]){}
        else{
            $label3.Text = "$selectedModel Converted."
            $TextBox2.Text = "Model successfully exported to $path\Converted\$selectedModel-f16.gguf"
	        # Move the file to be quantized
	        Move-Item $path\llama.cpp\models\$selectedModel\ggml-model-f16.gguf $path\Converted\$selectedModel-f16.gguf
            ListModels}
    }
    deactivate # Deactivate (venv) python environment.
}

# Quantize the selected model from f16 or f32.
function QuantizeModel{
	# Navigate to the build directory where llama-quantize.exe resides
	Set-Location -Path $path\llama.cpp\build\bin\Release
    $selectedModel = $ComboBox1.selectedItem # Selected LLM from dropdown list.
    if ($selectedModel -match ".gguf"){
        if ($selectedModel -match "-f16"){$renameModel = ($ComboBox1.selectedItem -split "-f16", 2)[0].Trim()}
        if ($selectedModel -match "-f32"){$renameModel = ($ComboBox1.selectedItem -split "-f32", 2)[0].Trim()}
        $option = ($ComboBox2.selectedItem  -split ' ', 2)[1].Trim()
        $label3.Text = "Quantizing $selectedModel..."
        try { & ".\llama-quantize.exe $path\Converted\$selectedModel $path\Converted\$renameModel-$option.gguf $option"
        } catch [Exception] {$label3.Text = "Quantizing failed...";$TextBox2.Text = $_.Exception.Message}else{$label3.Text = "$selectedModel Quantized."}
        ListModels}
    else{$label3.Text = "Quantizing failed...";$TextBox2.Text = "You must select a .gguf model, either -f16 or -f32"}
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

# Pull metadata from any gguf using the gguf-dump script.
function ggufDump{
    # gguf-dump needs a $option and a $selectedModel to fucntion, send that when calling ggufDump.
    # use ($print = 1) if you want it to update the gui with data.
    if ($selectedModel -match ".gguf"){
        # Navigate to the directory where llama.cpp resides
        Set-Location -Path $path
        # Activate the virtual environment.
        .\venv\Scripts\activate
        # Path to the Python script
        $scriptPath = "$path\llama.cpp\gguf-py\scripts\gguf-dump.py"

        # Target directory containing GGUF files
        $ggufDir = "$path\Converted\"
        #$selectedModel = $ComboBox1.selectedItem #selectedModel is set where gguf-dump is called. # Selected LLM from dropdown list. 
        #$option = ($ComboBox2.selectedItem -split ' ', 2)[1].Trim() #option is set where gguf-dump is called.
    
        # Build the full path to the GGUF file
        $filePath = Join-Path $ggufDir $selectedModel

        # Run the Python script with JSON output and capture the result
        $fileContent = Python $scriptPath --json --no-tensors $filePath
    
        $jsonData = ConvertFrom-Json -InputObject $fileContent
        $metadata = $jsonData.metadata
        $matchingKey = ($metadata | Get-Member -Name *"$option").Name | Where-Object { $_ -like "*$option*" } | Select-Object -First 1
        $label3Text = $matchingKey
        try {if ($metadata | Get-Member -Name $matchingKey){
            if ($metadata.$matchingKey.value){
                $value = $metadata.$matchingKey.value -replace "\n", "\n"}}}
            catch{
                if ($option -eq "dump"){
                $label3Text = "gguf-dump..."
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

function CfgBuild{
    try {
        if ((nvcc --version) -and (vulkaninfo --summary)){
        $pattern = '(^\bc?$)|(^\bv?$)|(^\bcpu?$)'
        #$pattern = '[vc]|cpu'
        while ($build -cnotmatch $pattern) {clear; $build = Read-Host "Build for use with vulkan cuda or cpu? (v/c/cpu)"}
        }
    } catch {
        try {if (nvcc --version){$build = 'c'}
        } catch {Write-Host "( ) Nvidia CudaToolkit required for NVIDIA GPU build"}
        try {if (vulkaninfo --summary){$build = 'v'}
        } catch {Write-Host "( ) AMD VulkanSDK required for AMD GPU build"}
    } finally {
    if ($build -ne 'v' -and $build -ne 'c'){$build = 'cpu'; Write-Host "(*) Build for CPU Only"}
    if($build -eq 'c') {Write-Host "(*) Nvidia CudaToolkit"}
    if ($build -eq 'v') {Write-Host "(*) AMD VulkanSDK"}
    # Add config.txt file to store variables.
    New-Item -ItemType File -Path $path\config.txt
    RestoreConfig # Fill in the config.txt file from this release.
    $cfg = "build"; $cfgValue = $build; EditConfig $cfg # Update config with new build value.
    if (Test-Path "$path\llama.cpp"){}else{InstallLlama}
    }
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
function InstallLlama {
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
        cmake --build build --config Release -j 8
    } elseif ($build -eq 'c') {
        cd $path\llama.cpp
        mkdir build
        cmake -B .\build -DGGML_CUDA=ON -DGGML_NATIVE=ON
        cmake --build build --config Release -j 8
    } elseif ($build -eq 'cpu') {
        cd $path\llama.cpp
        mkdir build
        cmake -B .\build -DGGML_NATIVE=ON
        cmake --build build --config Release -j 8
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
    $gitstatusf | Out-File -FilePath "$path\logs\$timestamp-$version-llamaCpp.txt" -Force
    $TextBox2.Text = $gitstatusf
    if($build -eq 'v') {
 		cd $path\llama.cpp
		rd -r build
		mkdir build
		cmake -B .\build -DGGML_VULKAN=ON -DGGML_NATIVE=ON
		cmake --build build --config Release -j 8
	} elseif ($build -eq 'c') {
		cd $path\llama.cpp
		rd -r build
		mkdir build
		cmake -B .\build -DGGML_CUDA=ON -DGGML_NATIVE=ON
		cmake --build build --config Release -j 8
	} elseif ($build -eq 'cpu') {
		cd $path\llama.cpp
		rd -r build
		mkdir build
		cmake -B .\build -DGGML_NATIVE=ON
		cmake --build build --config Release -j 8
	}
$label3.Text = "Updating, building and configuring completed."
}

# Make Symlink for a selected model in the directory you designated in config.
function SymlinkModel{
    $selectedModel = $ComboBox1.selectedItem # Selected LLM from dropdown list.
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

# If installed and config.txt exists run the program.
if (Test-Path "$path\config.txt"){
    GitIgnore #rebuild the list each init, if something is tracked it will not be ignored.
    ListScripts #rebuild the list each init
    ListModels #rebuild the list each init
    $main_form.ShowDialog()}
else {PreReqs} # If all PreReqs exist run the installer.
