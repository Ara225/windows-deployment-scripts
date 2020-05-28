Function mainBody($ISOPath, $DestinationFolder, $ListOfSoftware) {    
    try {
        # Assumes that the script is run from the same location as it is actually in. This will always happen when run by the batch script
        $ScriptLocation = Get-Location
        $ScriptLocation = $ScriptLocation.Path
        Write-Output $([datetime]::Now.ToString()) + "Script has started. FYI, many steps will take a very long time." >>$ScriptLocation\ImageGenerator.log
        Set-Location $DestinationFolder
        # The list of volumes before mounting ISO
        $volumesBefore = Get-Volume
        # Mount ISO Assumes default file associations are present
        Invoke-Item $ISOPath
        Write-Output "$([datetime]::Now.ToString()) Checking if ISO has mounted" >>$ScriptLocation\ImageGenerator.log
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
            Write-Output "$([datetime]::Now.ToString()) ERROR: The ISO has not mounted properly OR was already inserted. Please eject the ISO (right click on the newly added CD drive and click eject) and try again" >>$ScriptLocation\ImageGenerator.log
            return
        }
        elseif ($DriveLetter.DriveLetter.length -gt 1) {
            Write-Output "$([datetime]::Now.ToString()) ERROR: Detected more than one drive was added. Please eject the ISO (right click on the newly added CD drive and click eject)" >>$ScriptLocation\ImageGenerator.log
            return
        }
        
        # Converts to String instead of Char PS is fidly about that for some reason
        $drive = "" + $DriveLetter.DriveLetter[0]
        Write-Output "$([datetime]::Now.ToString()) Extracting the (install.esd) base image file from the ISO" >>$ScriptLocation\ImageGenerator.log

        if (Test-Path  .\install.esd) {
            Remove-Item .\install.esd
        }
        # Take install file from iso
        Copy-Item -Path $drive`:\sources\install.esd -Destination .
        Write-Output "$([datetime]::Now.ToString()) Looking inside the install.esd file, to find the Windows 10 Home and Windows 10 Pro images" >>$ScriptLocation\ImageGenerator.log

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
            Remove-Item .\Home
        }
        if (Test-Path  .\Pro) {
            Remove-Item .\Pro
        }
        
        mkdir Pro
        mkdir Home
        Write-Output "$([datetime]::Now.ToString()) Starting to process the Windows 10 Home image" >>$ScriptLocation\ImageGenerator.log

        Set-Location Home
        try {
            Write-Output "$([datetime]::Now.ToString()) Trying to use 7zip to extract the Home image (PLEASE ensure 7zip is installed if not already)" >>$ScriptLocation\ImageGenerator.log

            & 'C:\Program Files (x86)\7-Zip\7z.exe' x ..\install.esd $HomeIndex >>$ScriptLocation\ImageGenerator.log
            if (Get-ChildItem $ScriptLocation\AdministrativeFiles) {
                Get-ChildItem $ScriptLocation\AdministrativeFiles | ForEach-Object {
                    Copy-Item $ScriptLocation\AdministrativeFiles\$_ .
             Write-Output "$([datetime]::Now.ToString()) Copied " + $ScriptLocation\AdministrativeFiles\$_ >>$ScriptLocation\ImageGenerator.log
                }
            }
            else {
                Write-Output "$([datetime]::Now.ToString()) Can not find AdministrativeFiles folder (This folder should be in the same place as the script). This means that the install will not be automated!!" >>$ScriptLocation\ImageGenerator.log
            }
            if ($ListOfSoftware.Count -ne 0) {
                mkdir Software
                for ($i = 0; $i -lt $ListOfSoftware.Count; $i++) {
                    Copy-Item  $ListOfSoftware[$i] .\Software
             Write-Output "$([datetime]::Now.ToString()) Copied " + $ListOfSoftware[$i] >>$ScriptLocation\ImageGenerator.log
                }
            }
            elseif (Get-ChildItem $ScriptLocation\FilesToInstall) {
                mkdir Software
                Get-ChildItem $ScriptLocation\FilesToInstall | ForEach-Object {
                    Copy-Item $ScriptLocation\FilesToInstall\$_ .\Software
             Write-Output "$([datetime]::Now.ToString()) Copied " + $ScriptLocation\FilesToInstall\$_ >>$ScriptLocation\ImageGenerator.log
                }
            }
            Write-Output "$([datetime]::Now.ToString()) Using DISM to convert the Home folder (which contains the extracted files) back into a image. " >>$ScriptLocation\ImageGenerator.log

            Dism /Capture-Image /ImageFile:..\Win10HomeNew.wim /CaptureDir:$HomeIndex /Name:Win10Home >>$ScriptLocation\ImageGenerator.log
        }
        catch {
            Write-Output "$([datetime]::Now.ToString()) Error handling Windows Home image" >>$ScriptLocation\ImageGenerator.log
            Write-Output $_.Exception  >>$ScriptLocation\ImageGenerator.log
        }
        Write-Output "$([datetime]::Now.ToString()) Starting to process Windows 10 Pro" >>$ScriptLocation\ImageGenerator.log

        Set-Location ..\Pro
        try {
            Write-Output "$([datetime]::Now.ToString()) Trying to use 7zip to extract the Pro image (PLEASE ensure 7zip is installed if not already)" >>$ScriptLocation\ImageGenerator.log

            & 'C:\Program Files (x86)\7-Zip\7z.exe' x ..\install.esd $ProIndex >>$ScriptLocation\ImageGenerator.log
            if (Get-ChildItem $ScriptLocation\AdministrativeFiles) {
                Get-ChildItem $ScriptLocation\AdministrativeFiles | ForEach-Object {
                    Copy-Item $ScriptLocation\AdministrativeFiles\$_ .
             Write-Output "$([datetime]::Now.ToString()) Copied " + $ScriptLocation\AdministrativeFiles\$_ >>$ScriptLocation\ImageGenerator.log
                }
            }
            else {
                Write-Output "$([datetime]::Now.ToString()) Can not find AdministrativeFiles folder (This folder should be in the same place as the script). This means that the install will not be automated!!" >>$ScriptLocation\ImageGenerator.log

            }
            if ($ListOfSoftware.Count -ne 0) {
                mkdir Software
                for ($i = 0; $i -lt $ListOfSoftware.Count; $i++) {
                    Copy-Item  $ListOfSoftware[$i] .\Software
             Write-Output "$([datetime]::Now.ToString()) Copied " + $ListOfSoftware[$i] >>$ScriptLocation\ImageGenerator.log
                }
            }
            elseif (Get-ChildItem $ScriptLocation\FilesToInstall) {
                mkdir Software
                Get-ChildItem $ScriptLocation\FilesToInstall | ForEach-Object {
                    Copy-Item $ScriptLocation\FilesToInstall\$_ .\Software
             Write-Output "$([datetime]::Now.ToString()) Copied " + $ScriptLocation\FilesToInstall\$_ >>$ScriptLocation\ImageGenerator.log
                }
            }
            Write-Output "$([datetime]::Now.ToString()) Using DISM to convert the Pro folder (which contains the extracted files) back into a image. " >>$ScriptLocation\ImageGenerator.log
            Dism /Capture-Image /ImageFile:..\Win10ProNew.wim /CaptureDir:$ProIndex /Name:Win10Pro >>$ScriptLocation\ImageGenerator.log
            Write-Output "$([datetime]::Now.ToString()) Completed converting Pro to .wim" >>$ScriptLocation\ImageGenerator.log

        }
        catch {
            Write-Output "$([datetime]::Now.ToString()) Error handling Windows Pro image." >>$ScriptLocation\ImageGenerator.log
            Write-Output $_.Exception  >>$ScriptLocation\ImageGenerator.log
        }
        Set-Location $DestinationFolder
        Set-Location $ScriptLocation
        Write-Output "$([datetime]::Now.ToString()) Error handling Windows Pro image." >>$ScriptLocation\ImageGenerator.log
        return
    }
    catch {
        Write-Output "$([datetime]::Now.ToString())" + $_.Exception  >>$ScriptLocation\ImageGenerator.log
        return
    }
}