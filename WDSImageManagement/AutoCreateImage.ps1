$InputPath = "G:\WDSStuff"
$OutputPath = "C:\ScratchFolder"
$ScratchPath = "C:\ScratchFolder"
$UnattendFile = "C:\ScratchFolder\unattend.xml"

$ISOs = Get-ChildItem -Path $InputPath -Filter "*.iso"
foreach ($ISO in $ISOs) {
    try {
        Write-Host "Found $($ISO.FullName)"
        Dismount-DiskImage -ImagePath $ISO.FullName
        Mount-DiskImage -ImagePath $ISO.FullName -PassThru
        $ISOMountPoint = Get-DiskImage -ImagePath $ISO.FullName | Get-Volume 
        $ISODriveLetter = $ISOMountPoint.DriveLetter
        Write-Host "Extracting the (install.esd) base image file from the ISO"
        if (Test-Path  $ScratchPath\install.esd) {
            cmd /c del $ScratchPath\install.esd /Q  
        }
        # Take install file from iso
        Copy-Item -Path $ISODriveLetter`:\sources\install.esd -Destination $ScratchPath\install.esd
        Set-ItemProperty -Path $ScratchPath\install.esd -Name IsReadOnly -Value $false
        takeown /F $ScratchPath\install.esd
        Write-Host "Looking inside the install.esd file, to find the Windows 10 Home and Windows 10 Pro images"
        $WIMContents = dism /Get-WimInfo /WimFile:$ScratchPath\install.esd
        
        # Find Windows 10 Pro and Home images (install.esd has all the editions of Win10)
        for ($i = 0; $i -lt $WIMContents.Count; $i++) {
        Write-Host $WIMContents[$i]
            if ($WIMContents[$i] -eq "Name : Windows 10 Pro") {
                Write-Host "Found a Windows 10 Pro image"
                Write-Host $i

                $ProIndex = $WIMContents[$i-1].replace("Index : ", "")
            }
            if ($WIMContents[$i] -eq "Name : Windows 10 Home") {
                Write-Host "Found a Windows 10 Home image"
                Write-Host $i
                $HomeIndex = $WIMContents[$i-1].replace("Index : ", "")
            }
        }

        if (($ProIndex -eq $null) -and ($HomeIndex -eq $null)) {
           Write-Error "ISO contains neither Windows 10 Home or Windows 10 Pro. Ignoring the ISO"
           continue
        }
        $FileNameSafeDate = (Get-Date).ToString().Replace(':', '-').Replace("/", "-").Replace(" ", "_")
        if ($ProIndex -ne $null) {
            $ProOutputPath = "$OutputPath\Windows10ProBuiltAt$FileNameSafeDate.wim"
            $ProOutputName = "Windows10ProBuiltAt_$FileNameSafeDate"
            Write-Host "Exporting Home image from install.esd"
            Dism /Export-Image /SourceImageFile:"$ScratchPath\install.esd" /SourceIndex:$ProIndex /DestinationImageFile:"$ProOutputPath" /DestinationName:"$ProOutputName" /Compress:max
            Write-Host "Importing Pro image into WDS"
            Import-WdsInstallImage -ImageGroup "Desktops" -Path $ProOutputPath -NewImageName $ProOutputName -Multicast -TransmissionName $ProOutputName -DisplayOrder 0 -UnattendFile "$UnattendFile"
        }
        if ($HomeIndex -ne $null) {
            $HomeOutputPath = "$OutputPath\Windows10HomeBuiltAt$FileNameSafeDate.wim"
            $HomeOutputName = "Windows10HomeBuiltAt_$FileNameSafeDate"
            Write-Host "Exporting Home image from install.esd"
            Dism /Export-Image /SourceImageFile:"$ScratchPath\install.esd" /SourceIndex:$HomeIndex /DestinationImageFile:"$HomeOutputPath" /DestinationName:"$HomeOutputName" /Compress:max
            Write-Host "Importing Home image into WDS"
            Import-WdsInstallImage -ImageGroup "Desktops" -Path $HomeOutputPath -NewImageName $HomeOutputName -Multicast -TransmissionName $HomeOutputName -DisplayOrder 0 -UnattendFile "$UnattendFile"
        }
        Dismount-DiskImage -ImagePath "$($ISO.FullName)"
        if (Test-Path  $ScratchPath\$ISO.) {
            cmd /c del $ScratchPath\install.esd /Q  
        }
    }
    catch {
        Write-Host "Error occured " $error
        Dismount-DiskImage -ImagePath "$($ISO.FullName)"
        throw
    }
}
Read-Host -Prompt "Press enter to continue"
