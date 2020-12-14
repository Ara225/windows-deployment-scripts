function logger{
    param (
        $TextToLog
    )
    Tee-Object -InputObject $TextToLog -FilePath $ScriptLocation\ImageUpdater.log -Append
}

$WIM_FILES_FOLDER = "C:\Users\User\Documents\WimsToBeUpdated"
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

logger -TextToLog "$(Get-Date) INFO: Installing OSDBuilder\n" 
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module -Name OSDBuilder -Scope CurrentUser -Confirm:$false
logger -TextToLog "$(Get-Date) INFO: Getting contents of the WIM_FILES_FOLDER\n" 
$files = Get-ChildItem $WIM_FILES_FOLDER -File

for ($file = 0; $file -lt $files.Count; $file++) {
    try {
        if ($files[$file].Extension.ToLower() -match "wim" -or $files[$file].Extension.ToLower() -match "esd") {
            $FileName = $files[$file].FullName
            logger -TextToLog "$(Get-Date) INFO: Getting image info from $FileName \n" 
            $filemageContents = Get-WindowsImage -ImagePath $FileName
            for ($ImageIndex = 0; $ImageIndex -lt $filemageContents.Count; $ImageIndex++) {
                logger -TextToLog "$(Get-Date) INFO: Importing $FileName image index $ImageIndex \n"
                Import-OSMedia -Path $FileName -ImageIndex $filemageContents[$ImageIndex].ImageIndex
            }
        }
    }
    catch {
        for ($i = 0; $i -lt $Error.Count; $i++) {
            logger -TextToLog $Error[$i].Exception
        }
        continue
    }
}