# Toolbox-GUI.psm1
# Contains the GUI elements.

# todo # Within the menu item named "Config" create a dynamicly populated window with a label for each line of the "config.txt" file.
# todo # Assist with update of Transformers

# Llama.cpp-Toolbox GUI version
$version_GUI = "0.1.x"

Add-Type -AssemblyName System.Windows.Forms

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

$configItem = New-Object System.Windows.Forms.ToolStripMenuItem
$configItem.Text   = "Config"
$configItem.Add_Click({ConfigForm})

$updaterLlama  = New-Object System.Windows.Forms.ToolStripMenuItem
$updaterLlama.Text = "Update Llama.cpp"
$updaterLlama.ShortcutKeyDisplayString="Ctrl+l"
$updaterLlama.Add_Click({$note = "Updating the Llama.cpp backend repo.`n`nYou must change to another repo or branch in the Toolbox-Config to rebuild.`n`n Are you sure you want to proceed?"
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
    $selectedDirectory = $ComboBox_llm.selectedItem # Selected LLM from dropdown list.
    If ($selectedDirectory -eq $null) {$Label3.Text = "List updated, select an LLM to check git status."}
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
        $gitstatus = Invoke-Expression "git pull"
        $log_name = "$selectedDirectory"
        Update-Log
        $Label3.Text =  'Model updated!'
            }
        }
    ListModels}
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

    $cfg = "repo"; $cfgRepo = RetrieveConfig $cfg # get-set the flag for repo.
    $cfg = "branch"; $cfgbranch = RetrieveConfig $cfg # get-set the flag for branch.
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

# Define the ConfigForm to display a dynamicly populated window.
function ConfigForm {
    # Read lines from the configuration file
    $lines = Get-Content $path\config.txt

    # Create a new WinForms application
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Config Llama.cpp-Toolbox"
    $form.Size = New-Object System.Drawing.Size(750, 300)

    # Create a panel to hold the controls
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.AutoSize = $true # Automatically resize with content.
    $panel.AutoScroll = $true # Include scrollbar
    $form.Controls.Add($panel)

    # Iterate through each line of the configuration file
    foreach ($line in $lines) {
        if ($line -ne "") { # Ignore blank lines
            # Parse the line into label and textbox values
            $parts = $line.Split('¦')
            $labelText = $parts[0].Trim()
            $textBoxText = $parts[1].Trim()

            # Create a label and textbox control
            $label = New-Object System.Windows.Forms.Label
            $label.Text = $labelText
            $label.AutoSize = $true
            $label.Location = New-Object System.Drawing.Point(10, $yPosition)

            $textBox = New-Object System.Windows.Forms.TextBox
            $textBox.Text = $textBoxText
            $textBox.Location = New-Object System.Drawing.Point(120, $yPosition)
            $textBox.Width = 300

            # Add the controls to the panel
            $panel.Controls.Add($label)
            $panel.Controls.Add($textBox)
        
            # Update yPosition for the next control
            $yPosition += $label.Height + 5  # Add a margin between controls
        }
    }

    # Show the WinForms application
    $form.ShowDialog()
}

Export-ModuleMember -Function * -Variable * -Alias *