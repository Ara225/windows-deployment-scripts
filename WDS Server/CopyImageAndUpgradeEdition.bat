rem Overly simplistic script with hard coded values
Dir C:
Dir D:
Dir E:
Dir F:
set /P CopyImage=Where is the  drive would would you like to copy it to (letter+colon), root?
set /P DesImage=What drive would would you like to copy it to (letter+colon), root?
copy "%copyImage%\images\Windows 10 Custom.wim" "%DesImage%\Windows 10 Custom.wim"
copy "%DesImage%\Windows 10 Custom.wim" "%DesImage%\Windows 10 Pro Custom.wim" 
mkdir %DesImage%\Mount
DISM /Mount-image /imagefile:"%DesImage%\Windows 10 Pro Custom.wim" /Index:1 /MountDir:%DesImage%\Mount
Dism /Image:%DesImage%\Mount /Set-Edition:Professional
rem copy unattend into image 
copy %copyImage%\win10unattend.xml %DesImage%\mount\unattend.xml
Dism /Unmount-Image /MountDir:%DesImage%\mount\ /Commit