$ScriptLocation = Get-Location
$ScriptLocation = $ScriptLocation.Path
# Remove old log file
if (Test-Path $ScriptLocation\ImageGenerator.log) {
    Remove-Item $ScriptLocation\ImageGenerator.log
}
Write-Output "GUI opened, image making process not started" >>$ScriptLocation\ImageGenerator.log
$InitScript = [scriptblock]::Create("Set-Location " + $($ScriptLocation) + " ;Import-module .\mainBody.ps1 -Force")

$JobId = $null
$wshell = New-Object -ComObject Wscript.Shell
if (!(Test-Path "C:\Program Files (x86)\7-Zip\7z.exe")) {
    $wshell.Popup("Can not find the 7Zip command line tool (C:\Program Files (x86)\7-Zip\7z.exe). This is essential. Please install the non portable Windows version from 7Zip & try again.",0,"Error",16)
    exit
}
#****** Instigate the window itself
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = 'Windows Image Generator'
$main_form.Width = 600
$main_form.Height = 400
$main_form.AutoSize = $true
$main_form.FormBorderStyle
#****** The header
$Header = New-Object System.Windows.Forms.Label
$Header.Text = "Windows Image Generator"
$Header.Location = New-Object System.Drawing.Point(150, 10)
$Header.AutoSize = $true
$Header.Font = "Arial, 15pt"
$main_form.Controls.Add($Header)
#****** Row 1: ISO selection
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Windows 10 ISO to Use:"
$Label.Location = New-Object System.Drawing.Point(20, 60)
$Label.AutoSize = $true
$main_form.Controls.Add($Label)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Width = 270
$textBox.Location = New-Object System.Drawing.Point(150, 60)
$textBox.Enabled = $false
$main_form.Controls.Add($textBox)
$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Point(440, 60)
$Button.Text = "Pick ISO File"
$Button.AutoSize = $true
$main_form.Controls.Add($Button)
# Instigate a file dialog with filter to ISO file
$opens = New-Object System.Windows.Forms.OpenFileDialog
$opens.Filter = "ISO Files|*.iso"
# Code to react to click on the button by showing the dialog
$Button.Add_Click({
        $opens.ShowDialog()
        $textBox.Text = $opens.FileName
    })
#****** Row 2: Output folder selection
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Text = "Output Folder:"
$Label2.Location = New-Object System.Drawing.Point(20, 100)
$Label2.AutoSize = $true
$main_form.Controls.Add($Label2)
$textBox2 = New-Object System.Windows.Forms.TextBox
$textBox2.Width = 270
$textBox2.Location = New-Object System.Drawing.Point(150, 100)
$textBox2.Enabled = $false
$main_form.Controls.Add($textBox2)
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Point(440, 100)
$Button2.Text = "Select Output Folder"
$Button2.AutoSize = $true
$main_form.Controls.Add($Button2)
# Folder selection box
$opens2 = New-Object System.Windows.Forms.FolderBrowserDialog 
$opens2.Description = "Choose the folder you want the WIM files to end up in."
$opens2.RootFolder = "MyComputer"
$Button2.Add_Click({
        $opens2.ShowDialog()
        $textBox2.Text = $opens2.SelectedPath
    })
#****** Row 3: Select software to install into the image
$Label3 = New-Object System.Windows.Forms.Label
$Label3.Text = "Software to install into the image.`n`nOptional: uses files from FilesToInstall if left blank. Preferably .msi files"
$Label3.Location = New-Object System.Drawing.Point(20, 140)
$Label3.AutoSize = $true
$Label3.MaximumSize = New-Object System.Drawing.Size(130, 0);
$main_form.Controls.Add($Label3)
$ListBox = New-Object System.Windows.Forms.ListBox
$ListBox.Location = New-Object System.Drawing.Point(150, 140)
$ListBox.Width = 270
$main_form.Controls.Add($ListBox)
$Button3 = New-Object System.Windows.Forms.Button
$Button3.Location = New-Object System.Drawing.Point(440, 140)
$Button3.Text = "Add Software"
$Button3.AutoSize = $true
$main_form.Controls.Add($Button3)
$opens3 = New-Object System.Windows.Forms.OpenFileDialog
$opens3.Multiselect = $true
$opens3.Filter = "Software Installers|*.msi;*.exe|All Files|*"
# Add each one of the files to the list in the list box
$Button3.Add_Click({
        $opens3.ShowDialog()
        foreach ($item in $opens3.FileNames) {
            $ListBox.Items.Add($item)
        }
    })
#****** Row 4: Control buttons
$Button4 = New-Object System.Windows.Forms.Button
$Button4.Location = New-Object System.Drawing.Point(190, 240)
$Button4.Text = "Create Image"
$Button4.AutoSize = $true
$Button4.BackColor = "ForestGreen"
$Button4.ForeColor = "White"
$Button4.Add_Click( {
    if (($JobId -eq $null) -and ($textBox2.Text -ne "") -and ($textBox.Text -ne "") ) {
        $JobId = Start-Job -ScriptBlock { param($p1, $p2, $p3)
            mainBody $p1 $p2 $p3
            } -ArgumentList $textBox.Text,$textBox2.Text,$ListBox.Items -InitializationScript $InitScript
            Write-Host $textBox.Text
            Write-Host $textBox2.Text
        return
    }
    elseif ($JobId -ne $null) {
        $job = Get-Job $JobId.Id
        if ($job.State -eq "Running") {
            $wshell.Popup("The generator is already running. Please wait.",0,"Info",64)
            return
        }
        elseif  (($textBox2.Text -ne "") -and ($textBox.Text -ne "")) {
            $JobId = Start-Job -ScriptBlock { param($p1, $p2, $p3)
                mainBody $p1 $p2 $p3
                } -ArgumentList $textBox.Text,$textBox2.Text,$ListBox.Items -InitializationScript $InitScript
            return
        }
    }
    if ($textBox.Text -eq "") {
        $wshell.Popup("Please select the path to the ISO file. This should be a Windows 10 ISO file downloaded from Microsoft",0,"Error",48)
    }
    if ($textBox2.Text -eq "") {
        $wshell.Popup("Please select the output folder. This is the folder you want the generated .wim files to end up in.",0,"Error",48)
    }
})
$main_form.Controls.Add($Button4)

$Button5 = New-Object System.Windows.Forms.Button
$Button5.Location = New-Object System.Drawing.Point(290, 240)
$Button5.Text = "Help"
$Button5.AutoSize = $true
$Button5.Add_Click( {
    Invoke-Item help.html
})
$main_form.Controls.Add($Button5)
#****** Row 5: Script status
$Label4 = New-Object System.Windows.Forms.Label
$Label4.Text = "Status of the image generation process (see $ScriptLocation\ImageGenerator.log for full details. FYI Many steps take 30mins):"
$Label4.Location = New-Object System.Drawing.Point(20, 270)
$Label4.AutoSize = $true
$main_form.Controls.Add($Label4)
$Label5 = New-Object System.Windows.Forms.Label
$Label5.Text = "Not started"
$Label5.MaximumSize = New-Object System.Drawing.Size(570, 0);
$Label5.Location = New-Object System.Drawing.Point(30, 287)
$Label5.AutoSize = $true
$main_form.Controls.Add($Label5)
$timer=New-Object System.Windows.Forms.Timer
$timer.Interval=10
$timer.add_Tick([scriptblock]::Create("`$Label5.Text =  Get-Content  $($ScriptLocation)\ImageGenerator.log -Tail 1; Get-Content  $($ScriptLocation)\ImageGenerator.log -Tail 1 >>C:\dd.txt"))
$timer.Start()
#****** Show the form
$main_form.ShowDialog()