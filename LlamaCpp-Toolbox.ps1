# LlamaCpp-Toolbox.ps1
# Initialize the program then install or run it.

# Llama.cpp-Toolbox version
$version = "0.26.x"

$path = $PSScriptRoot # The directory where LlamaCpp-Toolbox.ps1 is initialized.
Set-Location $path # Ensure we are starting on the right path.
$models = "$path\llama.cpp\models" # Define model path

# Get the physical core count for building, and inference.
$NumberOfCores = [Environment]::ProcessorCount / 2 # Faster but maybe not best method, instant result.
#$NumberOfCores = (Get-CimInstance –ClassName Win32_Processor).NumberOfCores # Slower method, use only with a cfg entry.

Import-Module C:\Users\3simplex\Studio\LCT-M\lib\modules\Toolbox-Config.psm1 -Verbose
Import-Module C:\Users\3simplex\Studio\LCT-M\lib\modules\Llama-Chat.psm1 -Verbose
Import-Module C:\Users\3simplex\Studio\LCT-M\lib\modules\Toolbox-Functions.psm1 -Verbose
Import-Module C:\Users\3simplex\Studio\LCT-M\lib\modules\Toolbox-GUI.psm1 -Verbose

# Determine if the program should be run or installed.
function Main {
    if (Test-Path "$path\config.txt") { # If installed and config.txt exists run the program.
        GitIgnore # Rebuild the list each init, if something is tracked it will not be ignored.
        ListScripts # Rebuild the list each init.
        ListModels # Rebuild the list each init.
        $main_form.ShowDialog() # Start the GUI.
    }
    else {
        PreReqs # If all PreReqs exist run the installer.
    }
} Main # Run the program.