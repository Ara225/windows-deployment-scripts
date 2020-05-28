Write-Host "Script has started. FYI, many steps will take a very long time."
# Assumes that the script is run from the same location as it is actually in. This will always happen when run by the batch script
$ScriptLocation = Get-Location
$ScriptLocation = $ScriptLocation.Path
# Path to the Windows ISO
$ISOPath =  $ScriptLocation + "\Windows.iso"
# Folder to put the wim files
$DestinationFolder = $ScriptLocation
Set-Location $DestinationFolder
# The list of volumes before mounting ISO
$volumesBefore = Get-Volume
# Mount ISO Assumes default file associations are present
Invoke-Item $ISOPath
# Volumes present after mounting ISO
$volumeAfter = Get-Volume
# Compare the volumes
$DriveLetter = Compare-Object -ReferenceObject $volumesBefore -DifferenceObject $volumeAfter -Property DriveLetter
$count = 0
# If we don't register the ISO mount straight away
while (($null -eq $DriveLetter) -and ($count -lt 5)) {
    Start-Sleep 2
    $count++
    $volumeAfter = Get-Volume
    $DriveLetter = Compare-Object -ReferenceObject $volumesBefore -DifferenceObject $volumeAfter -Property DriveLetter
}

if ($null -eq $DriveLetter) {
    Write-Error "ERROR: The ISO has not mounted properly OR was already inserted. Please eject the ISO (right click on the newly added CD drive and click eject) and try again"
    exit
}
elseif ($DriveLetter.DriveLetter.length -gt 1) {
    Write-Error "ERROR: Detected more than one drive was added. Please eject the ISO (right click on the newly added CD drive and click eject)"
    exit
}
# Converts to String instead of Char PS is fidly about that for some reason
$drive = "" + $DriveLetter.DriveLetter[0]
Write-Host "Extracting the (install.esd) base image file from the ISO"
if (Test-Path  .\install.esd) {
    Remove-Item .\install.esd
}
# Take install file from iso
Copy-Item -Path $drive`:\sources\install.esd -Destination .
Write-Host "Looking inside the install.esd file, to find the Windows 10 Home and Windows 10 Pro images"
$WIMContents = dism /Get-WimInfo /WimFile:.\install.esd

# Find Windows 10 Pro and Home images (install.esd has all the editions of Win10)
for ($i = 0; $i -lt $WIMContents.Count; $i++) {
    if ($WIMContents[$i] -eq "Name : Windows 10 Pro") {
        $ProIndex = $WIMContents[$i-1].replace("Index : ", "") - 1
    }
    if ($WIMContents[$i] -eq "Name : Windows 10 Home") {
        $HomeIndex = $WIMContents[$i-1].replace("Index : ", "") - 1
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
Write-Host "Starting to process the Windows 10 Home image"
Set-Location Home
try {
    Write-Host "Trying to use 7zip to extract the Home image (PLEASE ensure 7zip is installed if not already)"
    & 'C:\Program Files (x86)\7-Zip\7z.exe' x ..\install.esd $HomeIndex
    if (Get-ChildItem $ScriptLocation\AdministrativeFiles) {
        Get-ChildItem $ScriptLocation\AdministrativeFiles | ForEach-Object {
            Copy-Item $ScriptLocation\AdministrativeFiles\$_ .
        }
    }
    else {
        Write-Host "Can not find AdministrativeFiles folder (This folder should be in the same place as the script). This means that the install will not be automated!!"
    }
    if (Get-ChildItem $ScriptLocation\FilesToInstall) {
        Get-ChildItem $ScriptLocation\FilesToInstall | ForEach-Object {
            Copy-Item $ScriptLocation\FilesToInstall\$_ .
        }
    }
    Write-Host "Using DISM to convert the Home folder (which contains the extracted files) back into a image. "
    Dism /Capture-Image /ImageFile:../Win10HomeNew.wim /CaptureDir:$HomeIndex /Name:Win10Home
}
catch {
    Write-Host "Error handling Windows Home image"
}
Write-Host "Starting to process Windows 10 Pro"
Set-Location ..\Pro
try {
    Write-Host "Trying to use 7zip to extract the Pro image (PLEASE ensure 7zip is installed if not already)"
    & 'C:\Program Files (x86)\7-Zip\7z.exe' x ..\install.esd $ProIndex
    if (Get-ChildItem $ScriptLocation\AdministrativeFiles) {
        Get-ChildItem $ScriptLocation\AdministrativeFiles | ForEach-Object {
            Copy-Item $ScriptLocation\AdministrativeFiles\$_ .
        }
    }
    else {
        Write-Host "Can not find AdministrativeFiles folder (This folder should be in the same place as the script). This means that the install will not be automated!!"
    }
    if (Get-ChildItem $ScriptLocation\FilesToInstall) {
        Get-ChildItem $ScriptLocation\FilesToInstall | ForEach-Object {
            Copy-Item $ScriptLocation\FilesToInstall\$_ .
        }
    }
    Write-Host "Using DISM to convert the Pro folder (which contains the extracted files) back into a image. "
    Dism /Capture-Image /ImageFile:../Win10ProNew.wim /CaptureDir:$ProIndex /Name:Win10Pro
}
catch {
    Write-Host "Error handling Windows Pro image."
}
Set-Location $DestinationFolder
Set-Location $ScriptLocation
Write-Host "Script excution completed"