$ExcutionComplete = $false
$WDSRoot = "C:/"

Write-Host "This script can delete WDS images "
$Images = Get-WdsInstallImage

while ($ExcutionComplete -ne $true) {
    if ($Images.Count -ne $null) {
        for ($i = 0; $i -lt $Images.Count; $i++) {
            Write-Host $i  $Images[$i].ImageName
        }
        try {
            $Choice = Read-Host -Prompt "Please enter the number of the image you want to delete (ctrl+c to exit)"
            $Choice = [int]$Choice
            $Image = $Images[$Choice]
        }
        catch {
            Write-Error "Please enter a valid number"
            continue
        }
    }
    else {
        $Image = $Images
    }
    

    $Confirmation = Read-Host -Prompt "Are you sure you want to delete $($Image.ImageName) (Y/N)? "
    
    if ($Confirmation -ne "Y") {
        Write-Host "Deletion cancelled at user request"
        continue
    }
    Write-Host "Deleting $($Image.ImageName)"
    Remove-WdsInstallImage -ImageGroup $Image.ImageGroup -ImageName $Image.ImageName
    Remove-Item "$WDSRoot\$($Image.FileName)"
    Write-Host "Deleted $($Image.ImageName)"
    Read-Host -Prompt "Press enter to continue"
    $ExcutionComplete = $true
}