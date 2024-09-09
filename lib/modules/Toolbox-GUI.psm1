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
$main_form.Controls.Add($menuStrip1)

$menuStrip1 = New-object system.windows.forms.menustrip

$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text   = "File"
$fileMenu.ShortcutKeyDisplayString="Ctrl+F"
$menuStrip1.Items.Add($fileMenu)

$configItem = New-Object System.Windows.Forms.ToolStripMenuItem
$configItem.Text   = "Config"

$updaterLlama  = New-Object System.Windows.Forms.ToolStripMenuItem
$updaterLlama.Text = "Update Llama.cpp"
$updaterLlama.ShortcutKeyDisplayString="Ctrl+l"
$updaterLlama.Add_Click({$note = "This could break the Llama.cpp-Toolbox GUI.`n`nUpdate Toolbox gets a recent known working version of llama.cpp.`n`n Are you sure you want to proceed?"
    ;$update = "UpdateLlama";$repo = "ggerganov/llama.cpp.git";ConfirmUpdate}) # Change repo if not already used.

$updaterGui = New-Object System.Windows.Forms.ToolStripMenuItem
$updaterGui.Text = "Update Toolbox"
$updaterGui.ShortcutKeyDisplayString="Ctrl+g"
$updaterGui.Add_Click({$note = "Updating the Llama.cpp-Toolbox GUI.`n`nUpdate Toolbox also gets a recent known working version of llama.cpp.`n`n Are you sure you want to proceed?"
    ;$update = "UpdateLlama";$repo = "3Simplex/llama.cpp.git";ConfirmUpdate}) # Change repo if not already used.

$fileMenu.DropDownItems.AddRange(@($configItem,$updaterLlama,$updaterGui))

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text   = "Help"
$helpMenu.ShortcutKeyDisplayString="F1"
$menuStrip1.Items.Add($helpMenu)

$aboutItem  = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutItem.Text = "About"
$aboutItem.Add_Click({AboutBox})
$helpMenu.DropDownItems.AddRange(@($aboutItem))

# Label for LLMs dropdown list.
$Label_llm = New-Object System.Windows.Forms.Label
$Label_llm.Text = "LLMs:"
$Label_llm.Location = New-Object System.Drawing.Point(110,33)
$Label_llm.AutoSize = $true
$main_form.Controls.Add($Label_llm)

# Dropdown list containing LLMs available to process.
$ComboBox_llm = New-Object System.Windows.Forms.ComboBox
$ComboBox_llm.Width = 300
$ComboBox_llm.Location  = New-Object System.Drawing.Point(160,30)
$main_form.Controls.Add($ComboBox_llm)


# Dropdown list containing scripts to process using the selected LLM.
$ComboBox2 = New-Object System.Windows.Forms.ComboBox
$ComboBox2.Width = 150
$ComboBox2.Location  = New-Object System.Drawing.Point(465,30)
$main_form.Controls.Add($ComboBox2)

# Button to process a script.
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Size(620,29)
$Button1.Size = New-Object System.Drawing.Size(100,23)
$Button1.Text = "Process"
$main_form.Controls.Add($Button1)

# 'Process' button action. (confirmed)
$Button1.Add_Click({
    $label3.Text = "";$TextBox2.Text = "" # Clear the text.
    $selectedDirectory = $ComboBox_llm.selectedItem # Selected LLM from dropdown list.
    $selectedScript = $ComboBox2.selectedItem # Selected LLM from dropdown list.
        If ($selectedScript -match "model list") {ModelList} # Only requires Combobox2
        If ($selectedDirectory -eq $null) {$Label3.Text = "Select an LLM and script to process."}
        Else {If ($selectedScript -eq $null) {$Label3.Text = "Select a script to process the LLM."}
            ElseIf ($selectedScript -match "llama-quantize.exe") {QuantizeModel}
            ElseIf ($selectedScript -match "convert") {ConvertModel}
            ElseIf ($selectedScript -match "gguf_dump.py") {$selectedModel = $ComboBox_llm.selectedItem;$option = ($ComboBox2.selectedItem -split ' ', 2)[1].Trim();$print=1;ggufDump}
            ElseIf ($selectedScript -match "symlink") {SymlinkModel}
            ElseIf ($selectedScript -match "llama-server") {LlamaChat}
            ElseIf ($selectedScript -match "llama-cli") {LlamaChat}
            else {$Label3.Text = "The script entered:$selectedScript was not handled."}
            }
    $print = 0 # Reset the flag so the screen wont show uncalled results.
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
        $output = Invoke-Expression "git pull origin"
        $TextBox2.Text = $output
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

# Define the AboutBox.
function AboutBox{
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
    $label_about_version.Text = (git rev-parse --verify HEAD)
    $label_about_version.Location = New-Object System.Drawing.Point(33, 9)
    $label_about_version.AutoSize = $true

    $cfg = "repo"; $cfgRepo = RetrieveConfig $cfg # get-set the flag for version.
    $label_about_repo = New-Object System.Windows.Forms.label
    $label_about_repo.Text = "Repo: https://github.com/$cfgRepo"
    $label_about_repo.Location = New-Object System.Drawing.Point(10, 50)
    $label_about_repo.AutoSize = $true

    # Add the labels to the form and set text for them
    $about_form.Controls.Add($label_about_name)
    $about_form.Controls.Add($label_about_version)
    $about_form.Controls.Add($label_about_repo)

    # Display the about form as a dialog box
    $about_form.ShowDialog()
}

# Within the menu item named "Config" create a dynamicly populated window.
$cfgWindow = New-Object System.Windows.Forms.Form

$configItem.Add_Click({
    $cfgText = Get-Content -Path "$path\config.txt"
    foreach ($line in $cfgText) {
        if (!($line.StartsWith("#"))) { # Ignore lines starting with "#"
            $labelCfg = New-Object System.Windows.Forms.Label
            $labelCfg.Text = $line.Trim()
            $cfgWindow.Controls.Add($labelCfg)
        }
    }
})

Export-ModuleMember -Function * -Variable * -Alias *
