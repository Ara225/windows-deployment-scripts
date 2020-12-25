$ScratchFolder = "C:\scratch"
$WsusContent = "C:\wsus\WsusContent"
$WDSRoot = "C:\"
$FileNameSafeDate = (Get-Date).ToString().Replace(':', '-').Replace("/", "-").Replace(" ", "_")

function logger{
    param (
        $TextToLog
    )
    Tee-Object -InputObject $TextToLog -FilePath $ScriptLocation\ImageUpdater.log -Append 
}

$ScriptLocation = Get-Location
$ScriptLocation = $ScriptLocation.Path

if (Test-Path $ScriptLocation\ImageUpdater1.log) {
    logger -TextToLog "$(Get-Date) INFO: Removing ImageUpdater1.log\n"
    Remove-Item $ScriptLocation\ImageUpdater1.log
}
if (Test-Path $ScriptLocation\ImageUpdater.log) {
    logger -TextToLog "$(Get-Date) INFO: Moving ImageUpdater.log to ImageUpdater1.log\n"
    Move-Item $ScriptLocation\ImageUpdater.log $ScriptLocation\ImageUpdater1.log
}
function Update-WindowsImage {
    param (
        $Folders,
        $MountPath,
        $Count
    )
    $FailedUpdates = @()
    foreach ($folder in $Folders) {
        try {
            logger -TextToLog $folder.FullName
            Add-WindowsPackage -PackagePath $folder.FullName -Path $MountPath -ErrorAction Stop
        }
        catch {
            logger -TextToLog $_.ToString();
            $FailedUpdates.Add($folder) 
        }
    }
    $Count = $Count - 1
    if ($Count -gt 1) {
        Update-WindowsImage -Folders $FailedUpdates -MountPath $MountPath -Count $Count
    }
}

 # Below Based on from  https://github.com/breich/UpdateWdsFromWsus
function Update-WdsFromWsus() {
    # Make sure temp path exists
    if( (Test-Path -Path $ScratchFolder ) -eq $false ) {
        logger -TextToLog "$(Get-Date) INFO: Temp Folder $ScratchFolder doesn't exist, creating it."
        $createPath = New-Item -Path $ScratchFolder -ItemType directory
        if( $createPath -eq $false ) {
            logger -TextToLog "$(Get-Date) ERROR: Failed to create scratch path $ScratchFolder. Returning from the fuction."
            return $false
        }
    }

    logger -TextToLog "$(Get-Date) INFO: Getting list of install images from WDS"
    $Images = Get-WdsInstallImage

    # Update each image.
    foreach( $Image in $Images ) {
        Update-WdsImage -Image $Image -Scratch $ScratchFolder -WsusContent $WsusContent
    }
}

<# 
    .SUMMARY Updates a specific image in the WDS repository.
#>
function Update-WdsImage() {
    Param(
        $Image,
        $ScratchFolder,
        $WsusContent
    )

    try {
        $ExportDestination = "$ScratchFolder\" + $image.FileName
        $ImageName = $Image.ImageName
        $ExportFileName = $Image.FileName.split("|")[0] +"|"+(Get-Date).ToFileTime()
        $ImageGroup = $Image.ImageGroup
        $Index = $Image.Index 
        $Description = "Updated at " + (Get-Date).ToShortDateString() + " via script"
    
        logger -TextToLog "$(Get-Date) INFO: Updating " $ImageName " (" $Image.FileName ")"
    
        # Export image from WDS
        logger -TextToLog "$(Get-Date) INFO: .... Exporting $ImageName to $ExportDestination"
        Export-WdsInstallImage  -Destination $ExportDestination -ImageName $ImageName -ImageGroup $ImageGroup -ErrorAction Stop
    }
    catch {
        logger -TextToLog "$(Get-Date) ERROR: .... Exporting $ImageName to $exportDestination failed. Quitting."
        logger -TextToLog $_.ToString();
        return $false;
    }
    
    try {
        # Create Mount path
        $MountPath = "$ScratchFolder\$ImageName$((Get-Date).ToFileTime())"
        if( ( Test-Path -Path $MountPath ) -eq $false ) {
            logger -TextToLog "$(Get-Date) INFO: .... Mount Folder $MountPath doesn't exist, creating it."
            New-Item -Path $MountPath -ItemType directory -ErrorAction Stop
            
        }
        logger -TextToLog "$(Get-Date) INFO: .... Mounting $ImageName to $MountPath. Please be patient."
        $mount = Mount-WindowsImage -ImagePath $exportDestination -Path $MountPath -Index $Index -CheckIntegrity -ErrorAction Stop
     }
     catch {
        logger -TextToLog "$(Get-Date) ERROR: .... Failed to mount $ImageName to $MountPath. Quitting."
        logger -TextToLog $_.ToString();
        return $false
     }

    try {
        logger -TextToLog "$(Get-Date) INFO: Adding WSUS Packages from ""$WsusContent"" to Windows Image Mounted at ""$MountPath"" "
        $updateFolders = Get-ChildItem -Path $WsusContent -ErrorAction Stop
    }
    catch {
        logger -TextToLog "Unable to get contents of $WsusContent"
        logger -TextToLog $_.ToString();
        return $false
    }

    Update-WindowsImage -Folders $FailedUpdates -MountPath $MountPath -Count 3

    try {
        # Dismount
        logger -TextToLog "$(Get-Date) INFO: .... Dismounting and saving $ImageName."
        Dismount-WindowsImage -Path $MountPath -Save -ErrorAction Stop
    }
    catch {
        logger -TextToLog "$(Get-Date) ERROR: Failed to dismount and save changes to $ImageName. Quitting."
        logger -TextToLog $_.ToString();
        return $false
    }

    try {
        # Delete Mount Path
        logger -TextToLog "$(Get-Date) INFO: .... Deleting mount path $MountPath"
        cmd /c del $MountPath /Q 
        Move-Item $exportDestination $WDSRoot -ErrorAction Stop
    }
    catch {
        logger -TextToLog "$(Get-Date) ERROR: Failed to tidy up"
        logger -TextToLog $_.ToString();
        return $false
    }

    try {
        logger -TextToLog "$(Get-Date) INFO: .... Importing image to WDS"
        # The Import needs to be called differently depending on whether or not there's an UnattendFile.
        # If Import-WdsInstallImage is called with an empty or null UnattendFile, import fails.
        if( $Image.UnattendFile -eq $null -or $Image.UnattendFile -eq "" ) {
            $import = Import-WdsInstallImage -ImageGroup $Image.ImageGroup -Path "$WDSRoot\$($image.FileName)" -NewImageName $ImageName -Multicast -TransmissionName $ImageName -DisplayOrder 0 -NewDescription $Description -ErrorAction Stop
        } else {
            $import = Import-WdsInstallImage -ImageGroup $Image.ImageGroup -UnattendFile $Image.UnattendFile -Path "$WDSRoot\$($image.FileName)" -ImageName $ImageName -NewImageName $ImageName -Multicast -TransmissionName $ImageName -DisplayOrder 0 -NewDescription $Description -ErrorAction Stop
        }
    }
    catch {
        logger -TextToLog "$(Get-Date) ERROR: Failed to import modified image to server. Quitting."
        logger -TextToLog $_.ToString();
        return $false
    }
}

Update-WdsFromWsus
timeout.exe /T 30