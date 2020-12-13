$WIM_FILES_FOLDER = "C:\Users\User\Documents\WimsToBeUpdated"
$ScriptLocation = Get-Location
$ScriptLocation = $ScriptLocation.Path
if (Test-Path $ScriptLocation\ImageUpdater1.log) {
    Remove-Item $ScriptLocation\ImageUpdater1.log
}
if (Test-Path $ScriptLocation\ImageUpdater.log) {
    Move-Item $ScriptLocation\ImageUpdater.log $ScriptLocation\ImageUpdater1.log
}
Install-Module -Name OSDBuilder 
try {
    $files = Get-ChildItem $WIM_FILES_FOLDER -File
}
catch {
    Write-Output "Error happened while trying to get contents of the WIM_FILES_FOLDER" >>$ScriptLocation\ImageUpdater.log
    throw
}
for ($i = 0; $i -lt $files.Count; $i++) {
    if ($files[$i].Extension.ToLower() -match "wim" -or $files[$i].Extension.ToLower() -match "esd") {
        Write-Host $files[$i]
    }
}