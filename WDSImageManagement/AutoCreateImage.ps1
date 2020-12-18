$InputPath = "C:\Users\User2\Downloads\"
$OutputPath = "G:\git"
$ScratchPath = "G:\git"

$ISOs = Get-ChildItem -Path $InputPath -Include "*.iso" -File
foreach ($ISO in $ISOs) {
    try {
        Write-Host "Found $ISO"
        $MountPath = Mount-DiskImage -ImagePath $ISO -PassThru
        $ISOMountPoint = Get-DiskImage -DevicePath $MountPath.CimInstanceProperties["DevicePath"].Value | Get-Volume 
        $ISODriveLetter = $ISOMountPoint.DriveLetter
        Write-Host "Extracting the (install.esd) base image file from the ISO"
        if (Test-Path  $ScratchPath\install.esd) {
            Remove-Item $ScratchPath\install.esd
        }
        # Take install file from iso
        Copy-Item -Path $ISODriveLetter`:\sources\install.esd -Destination $ScratchPath\install.esd
        Write-Host "Looking inside the install.esd file, to find the Windows 10 Home and Windows 10 Pro images"
        $WIMContents = dism /Get-WimInfo /WimFile:.\install.esd
        
        # Find Windows 10 Pro and Home images (install.esd has all the editions of Win10)
        for ($i = 0; $i -lt $WIMContents.Count; $i++) {
            if ($WIMContents[$i] -eq "Name : Windows 10 Pro") {
                Write-Host "Found a Windows 10 Pro image"
                $ProIndex = $WIMContents[$i-1].replace("Index : ", "") - 1
            }
            if ($WIMContents[$i] -eq "Name : Windows 10 Home") {
                Write-Host "Found a Windows 10 Home image"
                $HomeIndex = $WIMContents[$i-1].replace("Index : ", "") - 1
            }
        }
        if ($ProIndex -ne $null) {
           Write-Error "ISO contains neither Windows 10 Home or Windows 10 Pro. Ignoring the ISO"
           continue
        }
        $FileNameSafeDate = (Get-Date).ToString().Replace(':', '-').Replace("/", "-").Replace(" ", "_")
        if ($ProIndex -ne $null) {
            $ProOutputPath = "$OutputPath\Windows10ProBuiltAt$FileNameSafeDate.wim"
            $ProOutputName = "Windows 10 Pro Built At $FileNameSafeDate"
            Export-WindowsImage -SourceImagePath $ScratchPath\install.esd -SourceIndex $ProIndex -DestinationImagePath $ProOutputPath -DestinationName $ProOutputName
            Import-WdsInstallImage -ImageGroup "Desktops" -Path $ProOutputPath -NewImageName $ProOutputName -Multicast -TransmissionName $ProOutputName MultiCast -DisplayOrder 0 -UnattendFile "./unattend.xml"
        }
        if ($HomeIndex -ne $null) {
            $HomeOutputPath = "$OutputPath\Windows10HomeBuiltAt$FileNameSafeDate.wim"
            $HomeOutputName = "Windows 10 Home Built At $FileNameSafeDate"
            Export-WindowsImage -SourceImagePath $ScratchPath\install.esd -SourceIndex $HomeIndex -DestinationImagePath $HomeOutputPath -DestinationName $HomeOutputName
            Import-WdsInstallImage -ImageGroup "Desktops" -Path $HomeOutputPath -NewImageName $HomeOutputName -Multicast -TransmissionName $HomeOutputName MultiCast -DisplayOrder 0 -UnattendFile "./unattend.xml"
        }
    }
    catch {
        Write-Host "Error occured " $error
    }
}