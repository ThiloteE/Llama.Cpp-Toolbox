# Toolbox-Config.psm1
# Contains the configuration functions.

# Toolbox Config Text Version
$global:version_cfg = "0.1.0"

# The config text for this release.
$script:cfgText = "Llama.Cpp-Toolbox¦$version
Config-Version¦$global:version_cfg
config.txt¦This file stores variables to be used for updates & customization. If this file is modified incorrectly, regret happens.
help¦Separate arguments with a space like this...llama-quantize.exe Q4_0 --leave-output-tensor
rebuild¦False
build¦default
repo¦ggerganov/llama.cpp.git
branch¦master
dev_branch¦default
release_branch¦default
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

# Upgrade the config text when new version is retrieved.
function UpgradeConfig {
    # Get the new config text "cfgText" for this version to compare with the users older version of config.txt
    $lines1 = $script:cfgText -split [Environment]::NewLine
    # Get the old config.txt to compare with the newer "cfgText" for this version.
    $lines2 = Get-Content -Path $path\config.txt

    $output = @() # Create array to contain lines which will be written.
    $linesRead = @{} # Create array to contain all lines we looked at.
    $addedEntries = @{} # Create array to contain all lines we added.

    # Check each line of the original config file for missing lines from the new config text.
    foreach ($line1 in $lines1) {
        $foundMatch = $false
        $key = $line1.Split('¦')[0].Trim()
        # Separate handling for any line that does not start with "show" or "hide", these are the settings.
        if ($key -notmatch "(show|hide)"){
            foreach ($line2 in $lines2) {
                $key2 = $line2.Split('¦')[0].Trim()
                if ($key2 -eq $key) {
                    if (!$addedEntries.ContainsKey($key)) {
                        $output += $line2 # If a match exists keep it, this may have been modified by the user.
                        $addedEntries[$key] = $true # Mark that we added a record.
                    }
                    $foundMatch = $true # Mark that we found a match, then continue looking for more to add.
                    break
                }
            }
            if (!$foundMatch -and !$addedEntries.ContainsKey($key)) {
                $output += $line1 # If no match exists add the new configuration option.
                $addedEntries[$key] = $true
            }
        }
        else { # Separate handling for any line which starts with "show" or "hide", these are the menu items.
            $showHideKey = $line1.Split('¦')[1].Trim().Split(' ')[0].Trim()
            $foundMatch = $false
            foreach ($line2 in $lines2) {
                # Look for new entries that also exist in the original config that have not been added already.
                if ($line2.Split('¦')[1].Trim().Split(' ')[0].Trim() -eq $showHideKey -and !$linesRead.ContainsKey($line2)) {
                    $output += $line2 # If a match exists, keep it, as it may have been modified by the user.
                    $linesRead[$line2] = 1 # Mark the line that's added so we don't copy it.
                    $foundMatch = $true # Mark that we found a match, then continue looking for more to add.
                    break
                }
            }
            if (!$foundMatch -and !$linesRead.ContainsKey($line1)) {
                $output += $line1 # Add the new missing entry.
                $linesRead[$line1] = 1 # Mark the line that's added so we don't copy it.
            }
        }
    }

    # Save the updated content back to the file without adding a newline at the end
    $output -join "`r`n" | Set-Content -Path "$path\config.txt" -NoNewline
}

# Restore the config text.
function RestoreConfig {Add-Content -Path $path\config.txt -Value $script:cfgText} # Regenerate config if deleted.

# Retrieve a specific value within config.
function RetrieveConfig ($global:cfg) {
    $lines = Get-Content -Path $path\config.txt
    foreach ($line in $lines) {
        if ($global:cfg -eq $line.Split('¦')[0].Trim()) {
            $global:cfgValue = $line.Split('¦')[1].Trim()
            return $global:cfgValue  # Return the retrieved value
            break }  # Exit loop after finding the first match
        }
}

# Change a specific value within config.
function EditConfig ($global:cfg) {
    $lines = Get-Content -Path "$path\config.txt"
    $newlines = for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.StartsWith($global:cfg+'¦')) {
            # Replace the original line with the modified one
            ($line -replace '(?<=¦).*', $global:cfgValue).Trim()
        } else {
            $line
        }
    }
    # Save the updated content back to the file without adding a newline at the end
    $newlines -join "`r`n" | Set-Content -Path "$path\config.txt" -NoNewline
}

# Set the build flags for the config.
function CfgBuild {
$build = 'cpu' # This is now configurable in the GUI.
# Add config.txt file to store variables.
New-Item -ItemType File -Path $path\config.txt
RestoreConfig # Fill in the config.txt file from this release.
$global:cfg = "build"; $global:cfgValue = $build; EditConfig $global:cfg # Update config with new build value.
if (Test-Path "$path\llama.cpp"){}else{InstallLlama}

}

Export-ModuleMember -Function * -Variable * -Alias *