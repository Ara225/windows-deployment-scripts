Script kicked off as scheduled task.
Script checks for JSON and other files
Loops through images. Updates them one by one then loops through their derivative images
Checks software in each derivative image and updates it.
 Deletes any with the Should be deleted flag and removes from WDS. 
 If a image needs to be created from scratch, use base image with updates

```JSON
{
    "ImageDetails": [
        {
            "Path": "...",
            "DisplayName": "...",
            "WindowsEdition": "...",
            "FileName": "",
            "ShouldBeDeleted": false,
            "DerivateImages": [
                {
                    "Path": "...",
                    "DisplayName": "...",
                    "FileName": "",
                    "WinGetDependencies": [
                        {
                            "URL": "URL to a yaml in WinGet repo",
                            "InstalledVersion": ""
                        }
                    ],
                    "CommandsToBeRunInUnattend": "",
                    "HasBeenGeneratedWithCurrentSoftware": true,
                    "ShouldBeDeleted": false
                }
            ]
        }
    ],
    "ReportingURL": "",
    "ScratchFolder": "",
    "WsusContentFolderPath": "",
    "DefaultImageGroup": ""
}
```