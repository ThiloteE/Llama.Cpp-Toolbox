# Add required assemblies for WinForms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Verify-RunningProcesses {
    $verifiedProcesses = @{}
    $runningProcesses = Get-RunningLlamaProcesses

    foreach ($process in $runningProcesses.GetEnumerator()) {
        $processInfo = $process.Value
        if (!$processInfo.Process.HasExited) {
            try {
                $null = Get-Process -Id $processInfo.Process.Id -ErrorAction Stop
                $verifiedProcesses[$process.Key] = $processInfo
            }
            catch {
                Write-Host "Removing non-existent process from tracking: $($processInfo.Model)"
            }
        }
        else {
            Write-Host "Removing exited process from tracking: $($processInfo.Model)"
        }
    }

    $global:RunningProcesses = $verifiedProcesses
    return $verifiedProcesses
}

function Stop-LlamaProcess {
    param([string]$processId)
    
    $runningProcesses = Get-RunningLlamaProcesses
    if ($runningProcesses.ContainsKey($processId)) {
        $processInfo = $runningProcesses[$processId]
        try {
            $process = Get-Process -Id $processInfo.Process.Id -ErrorAction Stop
            $process | Stop-Process -Force -ErrorAction Stop
            $global:RunningProcesses.Remove($processId)
            Write-Host "Successfully stopped process: $($processInfo.Model)"
            return $true
        }
        catch {
            Write-Host "Error stopping process: $_"
            $global:RunningProcesses.Remove($processId)
            return $false
        }
    }
    return $false
}

function Show-ProcessManagerDialog {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Process Manager"
    $form.Size = New-Object System.Drawing.Size(400,200)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F0F0")

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(360,20)
    $label.Text = "Select a process to stop:"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($label)

    $dropdown = New-Object System.Windows.Forms.ComboBox
    $dropdown.Location = New-Object System.Drawing.Point(10,50)
    $dropdown.Size = New-Object System.Drawing.Size(360,20)
    $dropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $dropdown.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($dropdown)

    $stopButton = New-Object System.Windows.Forms.Button
    $stopButton.Location = New-Object System.Drawing.Point(200,100)
    $stopButton.Size = New-Object System.Drawing.Size(75,23)
    $stopButton.Text = "Stop"
    $stopButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $stopButton.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $form.Controls.Add($stopButton)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(295,100)
    $closeButton.Size = New-Object System.Drawing.Size(75,23)
    $closeButton.Text = "Close"
    $closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $closeButton.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $closeButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($closeButton)

    $form.CancelButton = $closeButton

    function Refresh-ProcessList {
        $dropdown.Items.Clear()
        $script:dropdownMapping = @{}
        
        $verifiedProcesses = Verify-RunningProcesses
        
        if ($verifiedProcesses.Count -gt 1) {
            $dropdown.Items.Add("Stop All Processes")
        }
        
        foreach ($process in $verifiedProcesses.GetEnumerator()) {
            $processInfo = $process.Value
            $dropdownText = if ($null -ne $processInfo.Port) {
                "$($processInfo.Model) (Port: $($processInfo.Port))"
            } else {
                "$($processInfo.Model)"
            }
            $dropdown.Items.Add($dropdownText)
            $script:dropdownMapping[$dropdownText] = $process.Key
        }
        
        if ($verifiedProcesses.Count -eq 0) {
            $stopButton.Enabled = $false
            $dropdown.Enabled = $false
            $label.Text = "No running processes found."
        } else {
            $dropdown.Enabled = $true
            $label.Text = "Select a process to stop:"
        }
    }

    Refresh-ProcessList

    $stopButton.Enabled = $false
    $dropdown.Add_SelectedIndexChanged({
        $stopButton.Enabled = $true
    })

    $stopButton.Add_Click({
        $selectedItem = $dropdown.SelectedItem
        if ($selectedItem) {
            if ($selectedItem -eq "Stop All Processes") {
                $verifiedProcesses = Verify-RunningProcesses
                $processIds = @($verifiedProcesses.Keys)
                $successCount = 0
                
                foreach ($processId in $processIds) {
                    if (Stop-LlamaProcess -processId $processId) {
                        $successCount++
                    }
                }
                
                [System.Windows.Forms.MessageBox]::Show(
                    "Stopped $successCount out of $($processIds.Count) processes.",
                    "Process Manager",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                $processId = $script:dropdownMapping[$selectedItem]
                if (Stop-LlamaProcess -processId $processId) {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Successfully stopped the selected process.",
                        "Process Manager",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information)
                } else {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Failed to stop the selected process.",
                        "Process Manager",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            
            # Refresh the process list after stopping processes
            Refresh-ProcessList
        }
    })

    $closeButton.Add_Click({
        $form.Close()
    })

    $form.ShowDialog()
    $form.Dispose()
}

# Export the functions
Export-ModuleMember -Function Show-ProcessManagerDialog, Stop-LlamaProcess, Verify-RunningProcesses