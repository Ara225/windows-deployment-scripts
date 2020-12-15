function logger{
    param (
        $TextToLog
    )
    Tee-Object -InputObject $TextToLog -FilePath $ScriptLocation\ImageUpdater.log -Append
}
$ScriptLocation = Get-Location
$ScriptLocation = $ScriptLocation.Path

if (!Test-Path $ScriptLocation\Images.json) { 
    logger -TextToLog "$(Get-Date) ERROR: Cannot find Images.json in current folder ($ScriptLocation)\n"
    exit
}

if (!Test-Path $ScriptLocation\DefaultUnattend.xml) { 
    logger -TextToLog "$(Get-Date) ERROR: Cannot find DefaultUnattend.xml in current folder ($ScriptLocation)\n"
    exit
}

if (!Test-Path $ScriptLocation\SpecGatherScript.vbs) { 
    logger -TextToLog "$(Get-Date) ERROR: Cannot find SpecGatherScript.vbs in current folder ($ScriptLocation)\n"
    exit
}

$ConfigObject = Get-Content -Path $ScriptLocation\Images.json | ConvertFrom-Json 

if ($ConfigObject -eq $null) {
    logger -TextToLog "$(Get-Date) ERROR: Unable to import config from file\n"
    exit
}

$DefaultUnattend = Get-Content -Path $ScriptLocation\DefaultUnattend.xml

if ($DefaultUnattend -eq $null) {
    logger -TextToLog "$(Get-Date) ERROR: Unable to import DefaultUnattend from file\n"
    exit
}

if (Test-Path $ScriptLocation\ImageUpdater1.log) {
    logger -TextToLog "$(Get-Date) INFO: Removing ImageUpdater1.log\n"
    Remove-Item $ScriptLocation\ImageUpdater1.log
}
if (Test-Path $ScriptLocation\ImageUpdater.log) {
    logger -TextToLog "$(Get-Date) INFO: Moving ImageUpdater.log to ImageUpdater1.log\n"
    Move-Item $ScriptLocation\ImageUpdater.log $ScriptLocation\ImageUpdater1.log
}

# Make sure temp path exists
if( (Test-Path -Path $ConfigObject.ScratchFolder ) -eq $false ) {
    logger -TextToLog "$(Get-Date) INFO: Temp Folder $($ConfigObject.ScratchFolder) doesn't exist, creating it."
    $createPath = New-Item -Path $ConfigObject.ScratchFolder -ItemType directory

    if( $createPath -eq $false ) {
        logger -TextToLog "$(Get-Date) ERROR: Failed to create scratch path  $($ConfigObject.ScratchFolder). Exiting."
        exit
    }
}

 # Below came from  https://github.com/breich/UpdateWdsFromWsus
function Update-WdsFromWsus() {

    Param(
        [string] $ScratchFolder,
        [string] $WsusContent
    )

    


    logger -TextToLog "$(Get-Date) INFO: Getting list of install images from WDS"
    $Images = Get-WdsInstallImage

    # Update each image.
    foreach( $Image in $Images ) {
        if ($Image.ImageName.Contains(" | OLD VERSION")) {
            continue
        }
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
    
    $ExportDestination    = "$ScratchFolder\" + $image.FileName
    $ImageName      = $Image.ImageName
    $ImageNameParts = $ImageName.Split("|")
    $ImageName      = $ImageNameParts[0].Trim() + " | (Updated " + (Get-Date).ToShortDateString() + " via " + $MyInvocation.MyCommand.Name + ")"
    $FileName       = $Image.FileName
    $ImageGroup     = $Image.ImageGroup
    $OldImageName   = $Image.ImageName
    $Index          = $Image.Index 

    logger -TextToLog "$(Get-Date) INFO: Updating " $OldImageName " (" $Image.FileName ")"

    logger -TextToLog "$(Get-Date) INFO: .... Exporting $OldImageName to $ExportDestination"
    $Export = Export-WdsInstallImage  -Destination $ExportDestination -ImageName $OldImageName -FileName $FileName -ImageGroup $ImageGroup -NewImageName $ImageName -ErrorAction SilentlyContinue

    
    # Verify that mounting succeeded.
    if( $export -eq $null ) {

        logger -TextToLog "$(Get-Date) ERROR: .... Exporting $OldImageName to $exportDestination failed. Quitting."
        return $false;
    }

    # Create Mount path.
    $MountPath = "$ScratchFolder\$OldImageName"
    if( ( Test-Path -Path $MountPath ) -eq $false ) {
        logger -TextToLog "$(Get-Date) INFO: .... Mount Folder $MountPath doesn't exist, creating it."
        $crap = New-Item -Path $MountPath -ItemType directory
        
    }
    logger -TextToLog "$(Get-Date) INFO: .... Mounting $OldImageName to $MountPath. Please be patient."
    $mount = Mount-WindowsImage -ImagePath $exportDestination -Path $MountPath -Index $Index -CheckIntegrity  -ErrorAction SilentlyContinue

    # Verify Mount.
    if( $mount -eq $null ) {
        logger -TextToLog "$(Get-Date) ERROR: .... Failed to mount $OldImageName to $MountPath. Quitting."
        return $false
    }

    logger -TextToLog "$(Get-Date) INFO: Adding WSUS Packages from ""$WsusContent"" to Windows Image Mounted at ""$MountPath"" "
    
    $updatFolders = Get-ChildItem -Path $WsusContent
    
    foreach ($folder in $updatFolders) {
        Add-WindowsPackage -PackagePath $folder.FullName -Path $MountPath  -ErrorAction SilentlyContinue
    }
    
    # Dismount
    logger -TextToLog "$(Get-Date) INFO: .... Dismounting and saving $OldImageName."
    $dismount = Dismount-WindowsImage -Path $MountPath -Save  -ErrorAction SilentlyContinue

    if( $dismount -eq $null ) {

        logger -TextToLog "$(Get-Date) ERROR: Failed to dismount and save changes to $OldImageName. Quitting."
        return $false
    }

    # Delete Mount Path
    logger -TextToLog "$(Get-Date) INFO: .... Deleting mount path $MountPath"
    $deleteMountPath = Remove-Item -Path $MountPath

    logger -TextToLog "$(Get-Date) INFO: .... Importing image to WDS"
    
    # The Import needs to be called differently depending on whether or not there's an UnattendFile.
    # If Import-WdsInstallImage is called with an empty or null UnattendFile, import fails.
    if( $Image.UnattendFile -eq $null -or $Image.UnattendFile -eq "" ) {
        logger -TextToLog "$(Get-Date) INFO: Import-WdsInstallImage -ImageGroup $Image.ImageGroup -Path $ExportDestination -ImageName -DisplayOrder 0 -NewImageName $ImageName"
        $import = Import-WdsInstallImage -ImageGroup $Image.ImageGroup -Path $ExportDestination -DisplayOrder 0 -NewImageName $ImageName -Multicast -TransmissionName $ImageName+" MultiCast"
    } else {
        $import = Import-WdsInstallImage -ImageGroup $Image.ImageGroup -UnattendFile $Image.UnattendFile -Path $ExportDestination -ImageName $OldImageName -DisplayOrder 0 -NewImageName $ImageName -Multicast -TransmissionName $ImageName+" MultiCast"
    }

    if( $import -eq $null ) {
        logger -TextToLog "$(Get-Date) ERROR: Failed to import modified image to server. Quitting."
        return $false
    }

    # Delete  Export
    logger -TextToLog "$(Get-Date) INFO: .... Removing Exported file $exportDestination"
    Remove-Item -Path $ExportDestination -Recurse  -ErrorAction SilentlyContinue
}