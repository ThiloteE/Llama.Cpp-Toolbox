# Toolbox-Config.psm1
# Contains the configuration functions.

# Toolbox-Config version
$version_cfg = "0.1.x"

# The config text for this release.
$cfgText = "Llama.Cpp-Toolbox¦$version
config.txt¦This file stores variables to be used for updates & customization. If this file is modified incorrectly, regret happens.
help¦Separate arguments with a space like this...llama-quantize.exe Q4_0 --leave-output-tensor
build¦default
repo¦3Simplex/llama.cpp.git
branch¦master
symlinkdir¦$path\Symlinks
maxCtx¦4096
show¦symlink
show¦model list
show¦llama-server 8080
show¦convert_hf_to_gguf.py
show¦convert_gptj_to_gguf.py
show¦convert_legacy_llama.py
show¦convert_legacy_llama.py bpe
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
show¦gguf_dump.py dump
show¦gguf_dump.py keys
show¦gguf_dump.py architecture
show¦gguf_dump.py context_length
show¦gguf_dump.py block_count
show¦gguf_dump.py chat_template"

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

# Set the build flags for the config.
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

Export-ModuleMember -Function * -Variable * -Alias *