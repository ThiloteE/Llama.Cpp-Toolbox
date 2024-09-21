# Toolbox-GUI.psm1
# Contains the GUI elements.

# todo # Assist with update of Transformers

# Llama.cpp-Toolbox GUI version
$global:version_GUI = "0.1.x"

Add-Type -AssemblyName System.Windows.Forms

$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = "Llama.cpp-Toolbox-$version"
$main_form.Width = 750
$main_form.Height = 300
$main_form.MinimumSize = New-Object System.Drawing.Size(750, 300)
$main_form.MaximumSize = New-Object System.Drawing.Size(750, 1000)

$menuStrip1 = New-object system.windows.forms.menustrip
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"
$fileMenu.ShortcutKeyDisplayString="Ctrl+F"

$configItem = New-Object System.Windows.Forms.ToolStripMenuItem
$configItem.Text = "Config"
$configItem.Add_Click({ConfigForm})

$updaterLlama  = New-Object System.Windows.Forms.ToolStripMenuItem
$updaterLlama.Text = "Update Llama.cpp"
$updaterLlama.ShortcutKeyDisplayString="Ctrl+l"
$updaterLlama.Add_Click({$note = "Updating Llama.cpp`n`nYou must set a branch in the Toolbox-Config to rebuild.`n`n Are you sure you want to proceed?"
    ;$update = "UpdateLlama";ConfirmUpdate}) # Updates llama.cpp only.


$updaterGui = New-Object System.Windows.Forms.ToolStripMenuItem
$updaterGui.Text = "Update Toolbox"
$updaterGui.ShortcutKeyDisplayString="Ctrl+g"
$updaterGui.Add_Click({$note = "Updating the Llama.cpp-Toolbox GUI.`n`nThe program will restart after updating.`n`n Are you sure you want to proceed?"
    ;$update = "UpdateToolbox";ConfirmUpdate}) # Updates the Toolbox only.

$menuStrip1.Items.Add($fileMenu)
$menuStrip1.Items.Add($configItem)
$fileMenu.DropDownItems.AddRange(@($configItem,$updaterLlama,$updaterGui))

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text   = "Help"
$helpMenu.ShortcutKeyDisplayString="F1"

$aboutItem  = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutItem.Text = "About"
$aboutItem.Add_Click({AboutForm})

$menuStrip1.Items.Add($helpMenu)
$helpMenu.DropDownItems.AddRange(@($aboutItem))

$main_form.Controls.Add($menuStrip1)

# Label for LLMs dropdown list.
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "LLMs:"
$Label.Location = New-Object System.Drawing.Point(110,33)
$Label.AutoSize = $true
$main_form.Controls.Add($Label)

# Dropdown list containing LLMs available to process.
$Global:ComboBox_llm = New-Object System.Windows.Forms.ComboBox
$ComboBox_llm.Width = 300
$ComboBox_llm.Location  = New-Object System.Drawing.Point(160,30)
$main_form.Controls.Add($ComboBox_llm)

# Dropdown list containing scripts to process using the selected LLM.
$Global:ComboBox2 = New-Object System.Windows.Forms.ComboBox
$ComboBox2.Width = 150
$ComboBox2.Location  = New-Object System.Drawing.Point(465,30)
$main_form.Controls.Add($ComboBox2)

# Button to process a script.
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Size(620,29)
$Button1.Size = New-Object System.Drawing.Size(100,23)
$Button1.Text = "Process"
$main_form.Controls.Add($Button1)

# 'Process' button action.
$Button1.Add_Click({
    $label3.Text = "";$TextBox2.Text = "" # Clear the text.
    $selectedDirectory = $ComboBox_llm.selectedItem # Selected LLM from dropdown list.
    $selectedScript = $ComboBox2.selectedItem # Selected script from dropdown list.
        If ($selectedScript -match "model list") {ModelList} # Only requires Combobox2
        If ($selectedDirectory -eq $null) {$Label3.Text = "Select an LLM and script to process."}
        Else {If ($selectedScript -eq $null) {$Label3.Text = "Select a script to process the LLM."}
            ElseIf ($selectedScript -match "quantize") {QuantizeModel}
            ElseIf ($selectedScript -match "convert") {ConvertModel}
            ElseIf (($selectedScript -match "server") -or ($selectedScript -match "cli")) {LlamaChat}
            ElseIf ($selectedScript -match "gguf_dump") {$selectedModel = $ComboBox_llm.selectedItem;$option = ($ComboBox2.selectedItem -split ' ', 2)[1].Trim();$print=1;ggufDump}
            ElseIf ($selectedScript -match "symlink") {SymlinkModel}
            else {$Label3.Text = "The script entered:$selectedScript was not handled."}
            }
    $print = 0 # Reset the flag so the screen wont show uncalled results from ggufDump.
    }
)

# Label for Status
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Text = "Status:"
$Label2.Location  = New-Object System.Drawing.Point(5,65)
$Label2.AutoSize = $true
$main_form.Controls.Add($Label2)

# Label to display Status
$Label3 = New-Object System.Windows.Forms.Label
$Label3.Text = ""
$Label3.Location  = New-Object System.Drawing.Point(60,65)
$Label3.AutoSize = $true
$main_form.Controls.Add($Label3)

function SetButton {
    # Check if the button already exists
    $existingButton = $main_form.Controls["BUL_Button"]

    $global:cfg = "rebuild"
    $global:rebuild = RetrieveConfig $global:cfg # get-set the flag for $rebuild.

    $buttonClickAction = {
        if($global:rebuild -eq "True"){
            $note = "Please be patient, this may take a while. $symlinkdir`n`nContinue?"
            $halt = Confirm # Inform the user this will take a while.
            if($halt -eq 0){BuildLlama}{}
        } else {
            # Function to 'update' from list of LLMs.
            $label3.Text = ""
            $TextBox2.Text = "" # Clear the text.
            $selectedDirectory = $ComboBox_llm.selectedItem # Selected LLM from dropdown list.
            If ($selectedDirectory -eq $null) {
                $Label3.Text = "LLM list updated, select an LLM to check git status."
            } Else {
                Set-Location $models\$selectedDirectory
                # Check for any updates using Git.
                $gitstatus = Invoke-Expression "git status"
                $TextBox2.Text = $gitstatus
                If ($gitstatus -match "up to date") {
                    $Label3.Text = "No changes to git detected."
                } Else {
                    $Label3.Text =  'Fetching changes...'
                    $gitstatus = Invoke-Expression "git pull"
                    $log_name = "$selectedDirectory"
                    Update-Log
                    $Label3.Text =  'Model updated!'
                }
            }
            ListModels
        }
    }

    if ($existingButton) {
        # Remove the existing button
        $main_form.Controls.Remove($existingButton)
    }
    # Button doesn't exist, create a new one
    $Button = New-Object System.Windows.Forms.Button
    $Button.Name = "BUL_Button" # Give the button a unique name
    $Button.Location = New-Object System.Drawing.Size(5,29)
    $Button.Size = New-Object System.Drawing.Size(100,23)
    $Button.Text = if($global:rebuild -eq "True"){"Rebuild"}else{"Update"}
    $main_form.Controls.Add($Button)

    if($global:rebuild -eq "True"){$label3.Text = "Remember to rebuild to use your updates."}
    # Add click event to the new button
    $Button.Add_Click($buttonClickAction)
    
}

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

# Request confirmation from the user.
function Confirm {
    $halt = 1 # Never procede without permission.
    $message = $note
    $title = "Confirm"
    $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $icon = [System.Windows.Forms.MessageBoxIcon]::Question
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {$halt=0;return $halt}
    if ($result -eq [System.Windows.Forms.DialogResult]::No) {$halt=1;return $halt}
}

# Update on request with confirmation.
function ConfirmUpdate {
    $message = $note
    $title = "Confirm Update"
    $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $icon = [System.Windows.Forms.MessageBoxIcon]::Question
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        if (Test-Path Function:\$update) {&$update}
        if ($repo -match "Toolbox"){
            If ($gitstatus -match "up to date") {$Label3.Text = "No changes to Llama.cpp-Toolbox detected."}
            else {Start-Process PowerShell -ArgumentList $path\LlamaCpp-Toolbox.ps1; [Environment]::Exit(1)}
        }
    }
    if ($result -eq [System.Windows.Forms.DialogResult]::No) {}
}

# Define the AboutForm to display information about the application.
function AboutForm {
    # Create a new form for displaying information about the tool
    $about_form = New-Object System.Windows.Forms.Form

    # Set properties of the form
    $about_form.Text = "About Llama.cpp-Toolbox"
    $about_form.Width = 500
    $about_form.Height = 200
    $about_form.MinimumSize = New-Object System.Drawing.Size(500, 150)
    $about_form.MaximumSize = New-Object System.Drawing.Size(600, 300)

    # Add a label to display the repo and version of Llama.cpp
    $label_about_name = New-Object System.Windows.Forms.Label
    $label_about_name.Text = "Llama.cpp-Version:"
    $label_about_name.Location = New-Object System.Drawing.Point(10, 10)
    $label_about_name.AutoSize = $true
    $label_about_version = New-Object System.Windows.Forms.Label
    $label_about_version.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
    $label_about_version.Text = (git rev-parse --short HEAD)
    $label_about_version.Location = New-Object System.Drawing.Point(115, 9)
    $label_about_version.AutoSize = $true

    $global:cfg = "repo"; $cfgRepo = RetrieveConfig $global:cfg # get-set the flag for repo.
    $global:cfg = "branch"; $cfgbranch = RetrieveConfig $global:cfg # get-set the flag for branch.
    $label_about_repo = New-Object System.Windows.Forms.label
    $label_about_repo.Text = "Repo: https://github.com/$cfgRepo $cfgbranch"
    $label_about_repo.Location = New-Object System.Drawing.Point(10, 30)
    $label_about_repo.AutoSize = $true

    # Add the labels to the form and set text for them
    $about_form.Controls.Add($label_about_name)
    $about_form.Controls.Add($label_about_version)
    $about_form.Controls.Add($label_about_repo)

    # Display the about form as a dialog box
    $about_form.ShowDialog()
}

function ConfigForm {
    # Read lines from the configuration file
    $lines = Get-Content $path\config.txt

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Config Llama.cpp-Toolbox"
    $form.Size = New-Object System.Drawing.Size(550, 300)
    
    # Create the botom Panel first. (form fills from botom up)
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.AutoSize = $true
    $panel.AutoScroll = $true
    $form.Controls.Add($panel)
    
    # Create the top ToolStrip last. (form fills from botom up)
    $toolStrip = New-Object System.Windows.Forms.ToolStrip
    $toolStrip.Dock = [System.Windows.Forms.DockStyle]::Top
    $toolStrip.AutoSize = $true
    $form.Controls.Add($toolStrip)

    # Create a ToolStripButton for Save
    $saveButton = New-Object System.Windows.Forms.ToolStripButton
    $saveButton.Text = "Save"
    $saveButton.Add_Click({
        foreach ($index in $script:textBoxes.Keys + $script:comboBoxes.Keys) {
            $parts = $lines[$index].Split('¦')
            if ($script:toggleButtons.ContainsKey($index)) {
                $parts[0] = if ($script:toggleButtons[$index].Text -eq "show") { "hide" } else { "show" }
            }
            if ($script:textBoxes.ContainsKey($index)) {
                $parts[1] = $script:textBoxes[$index].Text.Trim()
            } elseif ($script:comboBoxes.ContainsKey($index)) {
                $parts[1] = $script:comboBoxes[$index].Text.ToString().Trim()
            }
            $lines[$index] = $parts -join '¦'
        }
    
        # Save the updated content back to the file without adding a newline at the end
        $lines -join "`r`n" | Set-Content -Path "$path\config.txt" -NoNewline

        [System.Windows.Forms.MessageBox]::Show("Configuration saved successfully.", "Save Complete")
    
        # Refresh the form.
        ListScripts
        CreateFormControls
        RefreshBranchComboBox
    })
    $toolStrip.Items.Add($saveButton)

    $global:textBoxes = @{}
    $global:comboBoxes = @{}
    $global:toggleButtons = @{}
    $global:commitButtons = @{}
    $global:buttonIndices = @{}

    function CreateFormControls {
        $panel.Controls.Clear()
        $global:textBoxes.Clear()
        $global:comboBoxes.Clear()
        $global:toggleButtons.Clear()
        $global:commitButtons.Clear()
        $global:buttonIndices.Clear()

        $yPosition = 10
        
        foreach ($index in 0..($lines.Count - 1)) {
            $line = $lines[$index]
            if ($line -ne "" -and $line -notmatch "Toolbox" -and $line -notmatch "config.txt" -and $line -notmatch "Config-Version" -and $line -notmatch "help" -and $line -notmatch "rebuild"-and $line.Split('¦')[0].Trim() -ne "branch") {
                $parts =  $line.Split('¦')
                $global:labelText = $parts[0].Trim()
                $textBoxText = $parts[1].Trim()
                $comboBoxText = $parts[1].Trim()
                
                $label = New-Object System.Windows.Forms.Label
                $label.Text = $labelText
                $label.AutoSize = $true
                $label.Location = New-Object System.Drawing.Point(10, $yPosition)
                $panel.Controls.Add($label)

                if ($global:labelText -match "show|hide") {
                    $textBox = New-Object System.Windows.Forms.TextBox
                    $textBox.Text = $textBoxText
                    $textBox.Location = New-Object System.Drawing.Point(120, $yPosition)
                    $textBox.Width = 300
                    $global:textBoxes[$index] = $textBox
                    $panel.Controls.Add($textBox)
                    ToggleButton $index $yPosition $labelText
                } else {
                    if ($global:labelText -match "build|branch"){
                    $global:comboBox = New-Object System.Windows.Forms.ComboBox
                    $comboBox.SelectedText = $comboBoxText
                    $comboBox.Location = New-Object System.Drawing.Point(120, $yPosition)
                    $comboBox.Width = 300
                    $global:comboBoxes[$index] = $comboBox ; $panel.Controls.Add($comboBox)
                    Get-ComboBoxItems $global:labelText
                    } else {
                    $global:textBox = New-Object System.Windows.Forms.TextBox
                    $textBox.Text = $textBoxText
                    $textBox.Location = New-Object System.Drawing.Point(120, $yPosition)
                    $textBox.Width = 300
                    $global:textBoxes[$index] = $textBox ; $panel.Controls.Add($textBox)
                    }
                    CommitButton $index $yPosition
                }
                
                $yPosition += 30
            }
        }
    }

    CreateFormControls
    RefreshBranchComboBox
    $form.ShowDialog()
}

function ToggleButton($index, $yPos, $labelText) {
    $global:ButtonT = New-Object System.Windows.Forms.Button
    $global:buttonIndices[$ButtonT] = $index
    $ButtonT.Location = New-Object System.Drawing.Point(430, $yPos)
    $ButtonT.Size = New-Object System.Drawing.Size(80,23)
    $ButtonT.Text = if ($labelText -match "show") { "hide" } else { "show" }
    $panel.Controls.Add($ButtonT)
    
    $global:toggleButtons[$index] = $ButtonT
    $ButtonT.Add_Click({
        $this.Text = if ($this.Text -eq "show") { "hide" } else { "show" }
    })
}

function CommitButton($index, $yPosition) {
    $button = New-Object System.Windows.Forms.Button
    $global:buttonIndices[$button] = $index
    $button.Location = New-Object System.Drawing.Point(430, $yPosition)
    $button.Size = New-Object System.Drawing.Size(80, 23)
    $button.Text = "Commit"
    $panel.Controls.Add($button)

    # Directly assign to the dictionary
    $global:commitButtons[$index] = $button

    $button.Add_Click({
        $clickedButtonIndex = $global:buttonIndices[$this]
        $labelText = $lines[$clickedButtonIndex]
        $global:labelText = $labelText.Split('¦')[0].Trim()
        $value = if ($global:labelText -match "build|branch") {
            $global:comboBoxes[$clickedButtonIndex].Text
        } else {
            $global:textBoxes[$clickedButtonIndex].Text
        }
        # Replace with your actual commit action logic
        $action = DetermineAction $clickedButtonIndex $value
        PerformAction $action $value
    })
}

function CleanRepo ($text) {
    if ($text -match '([\w-]+/llama\.cpp)(\.git)?$') {
        return $Matches[1] + ".git"
    } else {
        Write-Error "The input string does not end with the required pattern."
        return $null
    }
}

function DetermineAction($index, $value) {
    $lineText = $lines[$index]
    #write-host "Determine $lineText $value"
    $global:cfgValue =  $value.Trim()
    $global:cfg = $lineText.Split('¦')[0].Trim()
    switch -Regex ($lineText) {
        "repo" {$global:cfgValue = CleanRepo $global:cfgValue ; if($global:cfgValue -eq ""){return "Error1"}else{Set-GitRepo $global:cfgValue; RefreshBranchComboBox ; return "RepoSet" }}
        "branch" { if($global:cfgValue -eq ""){return "Error2"}else{Set-GitBranch $global:cfgValue; RefreshBranchComboBox ; return "BuildLlama" }}
        "build" { EditConfig $global:cfg ; return "BuildLlama" }
        default { EditConfig $global:cfg ; return "DefaultAction" }
    }
}

function PerformAction($action, $value) {
    #write-host "Perform $action $value"
    switch ($action) {
        "Error1" { 
            [System.Windows.Forms.MessageBox]::Show("Input a git repo like this one 'ggerganov/llama.cpp.git'")
        }
        "Error2" { 
            [System.Windows.Forms.MessageBox]::Show("You must set a branch to be built.")
        }
        "RepoSet" { 
            [System.Windows.Forms.MessageBox]::Show("The repo for Llama.Cpp has been changed, you must set the branch to be built.")
        }
        "BuildLlama" { 
            # Build the new branch.
            $global:cfgValue = "True"; $global:cfg = "rebuild"; EditConfig $global:cfg # get-set the flag for $rebuild.
            [System.Windows.Forms.MessageBox]::Show("Llama.Cpp has been scheduled to be rebuilt.")
            SetButton
        }
        "DefaultAction" { 
            [System.Windows.Forms.MessageBox]::Show("Comitted record $global:cfg¦$value")
        }
    }
}

function RefreshBranchComboBox {
    $dev_branchComboBox = $null
    $dev_branchIndex = -1
    $release_branchComboBox = $null
    $release_branchIndex = -1
    
    Set-Location $path\llama.cpp
    $global:cfg = "repo"
    $repo = RetrieveConfig $global:cfg
    $checkBranch = (git branch --show-current)
    # if checkbranch is null then we are using the tag of a release.
    if($checkBranch -ne $null){$currentBranch = $checkBranch.Trim()}else{$global:cfg = "branch"; $currentBranch = RetrieveConfig $global:cfg }
    
    # Find the branch ComboBoxes
    foreach ($index in $global:comboBoxes.Keys) {
        $line = $lines[$index]
        if ($line -match "dev_branch") {
            $dev_branchComboBox = $global:comboBoxes[$index]
            $dev_branchIndex = $index
        }
        if ($line -match "release_branch") {
            $release_branchComboBox = $global:comboBoxes[$index]
            $release_branchIndex = $index
        }
    }

    if ($dev_branchComboBox -ne $null) {
        $dev_branchComboBox.Items.Clear()
        $dev_branches = git branch -a
        foreach ($dev_branch in $dev_branches) {
            $dev_branch = $dev_branch.Trim()
            
            if ($dev_branch -match "HEAD") {
                continue
            }
            $dev_branch = $dev_branch -replace '^\* ', ''
            if ($dev_branch -match "remotes/origin/(.+)") {
                $dev_branch = $matches[1]
            }
            $dev_branchComboBox.Items.Add($dev_branch.Trim())
        }
    }

    if ($release_branchComboBox -ne $null) {
        $release_branchComboBox.Items.Clear()
        $release_branches = git tag -l "b*" | Sort-Object -Descending
        foreach ($release_branch in $release_branches) {
            $release_branchComboBox.Items.Add($release_branch.Trim())
        }
    }

    # Determine if the current branch is a dev branch or a release branch
    $isDevBranch = $dev_branchComboBox.Items -contains $currentBranch
    $isReleaseBranch = $release_branchComboBox.Items -contains $currentBranch

    if ($isDevBranch) {
        $dev_branchComboBox.SelectedItem = $currentBranch
        $release_branchComboBox.Text = ""
    } elseif ($isReleaseBranch) {
        $dev_branchComboBox.Text = ""
        $release_branchComboBox.SelectedItem = $currentBranch
    } else {
        # If the current branch is neither in dev nor release, force latest release.
        $dev_branchComboBox.Text = ""
        $release_branchComboBox.Text = Get-NewRelease
    }

}

Export-ModuleMember -Function * -Variable * -Alias *