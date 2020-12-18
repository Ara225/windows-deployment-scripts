$ExcutionComplete = $false
$WDSRoot = ""

Write-Host "This script can delete WDS images "
$Images = Get-WdsInstallImage

while ($ExcutionComplete -ne $true) {
    for ($i = 0; $i -lt $Images.Count; $i++) {
        Write-Host $i  $Images[$i]
    }
    
    $Choice = Read-Host -Prompt "Please enter the number of the image you want to delete (ctrl+c to exit): "
    try {
        $Choice = $Choice.ToUInt16($Choice)
        $Image = $Images[$Choice]
    }
    catch {
        Write-Error "Please enter a valid number"
        continue
    }

    $Confirmation = Read-Host -Prompt "Are you sure you want to delete $($Image.ImageName) (Y/N)? "
    
    if ($Confirmation -ne "Y") {
        Write-Host "Deletion cancelled at user request"
        continue
    }
    Remove-WdsInstallImage -ImageGroup $Image.ImageGroup -ImageName $Image.ImageName
    Delete-Item "$WDSRoot\$($Image.FileName)"
}