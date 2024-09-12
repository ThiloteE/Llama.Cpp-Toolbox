# LlamaCpp-Toolbox.ps1
# Initialize the program then install or run it.
# This also acts as the toolbox environment setup script.

# Llama.cpp-Toolbox version
$global:version = "0.26.restart-test"

# The directory where LlamaCpp-Toolbox.ps1 is initialized.
$global:path = $PSScriptRoot 

# Ensure we are starting on the right path.
Set-Location $path 

# Define model path
$global:models = "$path\llama.cpp\models" 

# Get the physical core count for building, and inference.
$global:NumberOfCores = [Environment]::ProcessorCount / 2 # Faster but maybe not best method, instant result.

# Importing modules, debug with -Verbose
Import-Module $path\lib\modules\Toolbox-Config.psm1 
Import-Module $path\lib\modules\Llama-Chat.psm1
Import-Module $path\lib\modules\Toolbox-Functions.psm1
Import-Module $path\lib\modules\Toolbox-GUI.psm1

# Check for prerequisites and install as needed on first run or when CFG is not detected.
function PreReqs {
    if (python --version){$python = 1; Write-Host "(*) python is on path"}else{$python = 0; Write-Host "( ) python isn't ready"}
    if (pyenv){$pyenv = 1; Write-Host "(*) pyenv is ready"}else{$pyenv = 0; Write-Host "( ) pyenv isn't ready"}
    if (git help -g){$git = 1; Write-Host "(*) git is ready"}else{$git = 0; Write-Host "( ) git isn't ready"}
    if ($python -and $pyenv -and $git) {if (Test-Path "$path\lib\modules\Toolbox-GUI.psm1"){}else{InstallToolbox}}
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
function InstallToolbox {
    if ($path -notmatch "Llama.Cpp-Toolbox"){
        git clone https://github.com/3Simplex/Llama.Cpp-Toolbox.git
        while(!(Test-Path $path\Llama.Cpp-Toolbox\LlamaCpp-Toolbox.ps1)){Sleep 5}
        rm $path\LlamaCpp-Toolbox.ps1 # Remove the toolbox environment setup script continue with the installation.
        & $path\Llama.Cpp-Toolbox\LlamaCpp-Toolbox.ps1
        Exit
    }# The Toolbox environment exists, continue.
}

# Determine if the program should be run or installed.
function Main {
    if (Test-Path "$path\config.txt") { # If installed and config.txt exists run the program.
        VersionCheck # Edit the config if the program is updated.
        GitIgnore # Rebuild the list each init, if something is tracked it will not be ignored.
        ListScripts # Rebuild the list each init.
        ListModels # Rebuild the list each init.
        $main_form.ShowDialog() # Start the GUI.
    }
    else {
        PreReqs # If all PreReqs exist run the installer.
    }
} Main # Run the program.