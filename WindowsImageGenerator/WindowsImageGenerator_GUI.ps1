$Started = $false
$wshell = New-Object -ComObject Wscript.Shell
if (!(Test-Path "C:\Program Files (x86)\7-Zip\7z.exe")) {
    $wshell.Popup("Can not find the 7Zip command line tool (C:\Program Files (x86)\7-Zip\7z.exe). This is essential. Please install the non portable Windows version from 7Zip & try again.",0,"Error",16)
    exit
}
Function mainBody($ISOPath, $DestinationFolder) {    
    try {
        $Label5.Text = "Script has started. FYI, many steps will take a very long time."
        # Assumes that the script is run from the same location as it is actually in. This will always happen when run by the batch script
        $ScriptLocation = Get-Location
        $ScriptLocation = $ScriptLocation.Path
        Set-Location $DestinationFolder
        # The list of volumes before mounting ISO
        $volumesBefore = Get-Volume
        # Mount ISO Assumes default file associations are present
        Invoke-Item $ISOPath
        $Label5.Text = "Checking if ISO has mounted"
        # Volumes present after mounting ISO
        $volumeAfter = Get-Volume
        # Compare the volumes
        $DriveLetter = Compare-Object -ReferenceObject $volumesBefore -DifferenceObject $volumeAfter -Property DriveLetter
        $count = 0
        # If we can't see the ISO mount straight away
        while (($null -eq $DriveLetter) -and ($count -lt 5)) {
            Start-Sleep 2
            $count++
            $volumeAfter = Get-Volume
            $DriveLetter = Compare-Object -ReferenceObject $volumesBefore -DifferenceObject $volumeAfter -Property DriveLetter
        }
        
        if ($null -eq $DriveLetter) {
            $Label5.Text = "ERROR: The ISO has not mounted properly OR was already inserted. Please eject the ISO (right click on the newly added CD drive and click eject) and try again"
            return
        }
        elseif ($DriveLetter.DriveLetter.length -gt 1) {
            $Label5.Text = "ERROR: Detected more than one drive was added. Please eject the ISO (right click on the newly added CD drive and click eject)"
            return
        }
        
        # Converts to String instead of Char PS is fidly about that for some reason
        $drive = "" + $DriveLetter.DriveLetter[0]
        $Label5.Text = "Extracting the (install.esd) base image file from the ISO"
        if (Test-Path  .\install.esd) {
            Remove-Item .\install.esd
        }
        # Take install file from iso
        Copy-Item -Path $drive`:\sources\install.esd -Destination .
        $Label5.Text = "Looking inside the install.esd file, to find the Windows 10 Home and Windows 10 Pro images"
        $WIMContents = dism /Get-WimInfo /WimFile:.\install.esd
        
        # Find Windows 10 Pro and Home images (install.esd has all the editions of Win10)
        for ($i = 0; $i -lt $WIMContents.Count; $i++) {
            if ($WIMContents[$i] -eq "Name : Windows 10 Pro") {
                $ProIndex = $WIMContents[$i - 1].replace("Index : ", "") - 1
            }
            if ($WIMContents[$i] -eq "Name : Windows 10 Home") {
                $HomeIndex = $WIMContents[$i - 1].replace("Index : ", "") - 1
            }
        }
        if (Test-Path  .\Windows10ProNew.wim) {
            Move-Item .\Windows10ProNew.wim .\Windows10ProOld.wim
        }
        if (Test-Path  .\Windows10HomeNew.wim) {
            Move-Item .\Windows10HomeNew.wim .\Windows10HomeOld.wim
        }
        $HomeIndex = $HomeIndex + 1
        $ProIndex = $ProIndex + 1
        
        if (Test-Path  .\Home) {
            Move-Item .\Home .\HomeOld
        }
        if (Test-Path  .\Pro) {
            Move-Item .\Pro .\ProOld
        }
        
        mkdir Pro
        mkdir Home
        $Label5.Text = "Starting to process the Windows 10 Home image"
        Set-Location Home
        try {
            $Label5.Text = "Trying to use 7zip to extract the Home image (PLEASE ensure 7zip is installed if not already)"
            & 'C:\Program Files (x86)\7-Zip\7z.exe' x ..\install.esd $HomeIndex
            if (Get-ChildItem $ScriptLocation\AdministrativeFiles) {
                Get-ChildItem $ScriptLocation\AdministrativeFiles | ForEach-Object {
                    Copy-Item $ScriptLocation\AdministrativeFiles\$_ .
                }
            }
            else {
                $Label5.Text = "Can not find AdministrativeFiles folder (This folder should be in the same place as the script). This means that the install will not be automated!!"
            }
            if (Get-ChildItem $ScriptLocation\FilesToInstall) {
                Get-ChildItem $ScriptLocation\FilesToInstall | ForEach-Object {
                    Copy-Item $ScriptLocation\FilesToInstall\$_ .
                }
            }
            $Label5.Text = "Using DISM to convert the Home folder (which contains the extracted files) back into a image. "
            Dism /Capture-Image /ImageFile:../Win10HomeNew.wim /CaptureDir:$HomeIndex /Name:Win10Home
        }
        catch {
            $Label5.Text = "Error handling Windows Home image"
            Write-Error "Error handling Windows Home image."
        }
        $Label5.Text = "Starting to process Windows 10 Pro"
        Set-Location ..\Pro
        try {
            $Label5.Text = "Trying to use 7zip to extract the Pro image (PLEASE ensure 7zip is installed if not already)"
            & 'C:\Program Files (x86)\7-Zip\7z.exe' x ..\install.esd $ProIndex
            if (Get-ChildItem $ScriptLocation\AdministrativeFiles) {
                Get-ChildItem $ScriptLocation\AdministrativeFiles | ForEach-Object {
                    Copy-Item $ScriptLocation\AdministrativeFiles\$_ .
                }
            }
            else {
                $Label5.Text = "Can not find AdministrativeFiles folder (This folder should be in the same place as the script). This means that the install will not be automated!!"
            }
            if (Get-ChildItem $ScriptLocation\FilesToInstall) {
                Get-ChildItem $ScriptLocation\FilesToInstall | ForEach-Object {
                    Copy-Item $ScriptLocation\FilesToInstall\$_ .
                }
            }
            $Label5.Text = "Using DISM to convert the Pro folder (which contains the extracted files) back into a image. "
            Dism /Capture-Image /ImageFile:../Win10ProNew.wim /CaptureDir:$ProIndex /Name:Win10Pro
        }
        catch {
            $Label5.Text = "Error handling Windows Pro image."
            Write-Error "Error handling Windows Pro image."
        }
        Set-Location $DestinationFolder
        Set-Location $ScriptLocation
        return
    }
    catch {
        $Label5.Text = "A error occured: " + $_.Exception.Message
        Write-Error $_.Exception
        return
    }
}
#****** Instigate the window itself
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = 'Windows Image Generator'
$main_form.Width = 600
$main_form.Height = 400
$main_form.AutoSize = $true
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
$Label3.Text = "Software to install:"
$Label3.Location = New-Object System.Drawing.Point(20, 140)
$Label3.AutoSize = $true
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
    if (($Started -eq $false) -and ($textBox2.Text -ne "") -and ($textBox.Text -ne "") ) {
        $Started = $true
        $temp = mainBody $textBox.Text $textBox2.Text;
        $Started = $false
        return
    }
    elseif ($Started -eq $true) {
        $wshell.Popup("The generator is already running. Please wait.",0,"Info",64)
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
$Label4.Text = "Status:"
$Label4.Location = New-Object System.Drawing.Point(20, 260)
$Label4.AutoSize = $true
$main_form.Controls.Add($Label4)
$Label5 = New-Object System.Windows.Forms.Label
$Label5.Text = ""
$Label5.MaximumSize = New-Object System.Drawing.Size(400, 0);
$Label5.Location = New-Object System.Drawing.Point(65, 260)
$Label5.AutoSize = $true
$main_form.Controls.Add($Label5)
#****** Show the form
$main_form.ShowDialog()