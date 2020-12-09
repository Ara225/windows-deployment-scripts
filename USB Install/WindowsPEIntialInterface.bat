ECHO OFF
REM ****************INFORMATION****************

REM DESCRIPTION                     This script automates Windows image deployment from USB sticks and/or network shares, 
REM                                 and performs other common administrative tasks
 
REM FILES USED:                     This file should be Windows\System32\StartNet.cmd in the Boot.wim within the WinPE .iso 
REM                                 Also creates other files as it goes, diskpart scripts need to be done this way sadly
REM Intializing varibles neccessary for custom pattern install, con is short for continue
set con12=0 
set con22=0 
set con32=0 
set con42=0 
set con52=0 
set con62=0 
set con1=0 
set con2=0 
set con3=0 
set con4=0 
set con5=0 
set con6=0 
:Menu
ECHO.
ECHO ...............................................
ECHO       Return at once if found!
ECHO ...............................................
ECHO.
ECHO        WINDOWS INSTALL
ECHO 1 -  Auto Install Windows 10 Home
ECHO 2 -  Auto Install Windows 10 Pro
ECHO 3 -  Custom Install .wim file
ECHO 4 -  Cycle through custom order of tags
ECHO. 
ECHO             DISM
ECHO 5 -  Upgrade edition of offline windows image
ECHO 6 -  Add drivers to offline windows image
ECHO 7 -  Create .wim Image of HDD/folder
ECHO.
ECHO            DISKPART
ECHO 8 -  List Volumes
ECHO 9 -  Shrink Disk
ECHO 10 - Run Diskpart  
ECHO 11 - Format Disk
ECHO.
ECHO             NETWORK
ECHO 12 - Mount network disk as Y:
ECHO 13 - Run ipconfig
ECHO 14 - Run Nslookup
ECHO.
ECHO             TOOLS
ECHO 15 - Replace Sethc.exe and/or copy SAM
ECHO 16 - Open Notepad
ECHO 17 - Open Regedit 
ECHO 18 - EXIT
ECHO.
SET /P M=Type a number then press ENTER:
IF %M%==1 GOTO Win10Home
IF %M%==2 GOTO Win10Pro
IF %M%==3 GOTO WinCustom
IF %M%==4 GOTO InstallTask
IF %M%==5 GOTO UpgradeEdition
IF %M%==6 GOTO AddDrivers
IF %M%==7 GOTO CreateImage
IF %M%==8 GOTO ListVol
IF %M%==9 GOTO ShrinkDisk
IF %M%==10 GOTO openDiskpart
IF %M%==11 GOTO Format
IF %M%==12 GOTO NetDrive
IF %M%==13 GOTO ipconfig
IF %M%==14 GOTO nslookup
IF %M%==15 GOTO Hack
IF %M%==16 GOTO notepad
IF %M%==17 GOTO regedit
IF %M%==18 GOTO EOF

REM Option 1
:Win10Home
echo Find a drive that has a folder titled Images.
for %%a in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do @if exist %%a:\Images\ set USBLetter=%%a
echo The Images folder is on drive: %USBLetter%
dir %USBLetter%:\Images /w
set WimFile="%USBLetter%:\images\Win10Custom.wim"
SET /P M9=This will wipe drive 0, install a Windows image (from the folder above) and blindly copy win10unattend to the root of the C: drive. Do you want to continue(y/n):
IF %M9%==y GOTO Win10HomeInstall
IF %M9%==n GOTO Menu
REM Option 1 refers to here
:Win10HomeInstall
Echo.
echo STEP 1 of 4 Formatting Disk 0 (should take approx 2-5 mins)
Echo.
echo  select disk 0 >FormatDrive0.bat
echo clean >>FormatDrive0.bat
echo create partition primary size=300 >>FormatDrive0.bat
echo format quick fs=ntfs label="System" >>FormatDrive0.bat
echo assign letter="v" >>FormatDrive0.bat
echo active >>FormatDrive0.bat
echo create partition primary >>FormatDrive0.bat
echo format quick fs=ntfs label="Windows" >>FormatDrive0.bat
echo assign letter="w" >>FormatDrive0.bat
echo list volume >>FormatDrive0.bat
echo exit >>FormatDrive0.bat
diskpart.exe /s FormatDrive0.bat
del FormatDrive0.bat
Echo.
echo STEP 2 of 4 Applying the Windows 10 Home image (should take approx 20-35 mins)
Echo.
Dism /apply-image /imagefile:%WimFile% /index:1 /ApplyDir:w:\
Echo.
echo STEP 3 of 4 Adding boot files (should take approx 2-5 mins)
Echo.
W:\Windows\System32\bcdboot W:\Windows /l en-US
Echo.
echo STEP 4 of 4 Copying unattend file(should take >2 mins)
Echo.
Copy %USBLetter%\images\win10unattend.xml W:\unattend.xml
Echo.
echo Rebooting into your new install now, ctrl + c to cancel
Echo.
Timeout /T 20
exit
REM End of Option 1

REM Option 2
:Win10Pro
echo Find a drive that has a folder titled Images.
for %%a in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do @if exist %%a:\Images\ set USBLetter=%%a
echo The Images folder is on drive: %USBLetter%
dir %USBLetter%:\Images
set WimFile="%USBLetter%:\images\Win10Custom.wim"
SET /P M10=This will wipe drive 0, install Win10Custom.wim and blindly copy win10unattend to the root of the C: drive. Do you want to continue(y/n):
IF %M10%==y GOTO Win10ProInstall
IF %M10%==n GOTO Menu
:Win10ProInstall
Echo.
echo STEP 1 of 5 Formatting Disk 0 (should take approx 2-5 mins)
Echo.
echo  select disk 0 >FormatDrive0.bat
echo clean >>FormatDrive0.bat
echo create partition primary size=300 >>FormatDrive0.bat
echo format quick fs=ntfs label="System" >>FormatDrive0.bat
echo assign letter="v" >>FormatDrive0.bat
echo active >>FormatDrive0.bat
echo create partition primary >>FormatDrive0.bat
echo format quick fs=ntfs label="Windows" >>FormatDrive0.bat
echo assign letter="w" >>FormatDrive0.bat
echo list volume >>FormatDrive0.bat
echo exit >>FormatDrive0.bat
diskpart.exe /s FormatDrive0.bat
del FormatDrive0.bat
Echo.
echo STEP 2 of 5 Applying the Windows 10 Home image (should take approx 20-35 mins)
Echo.
Dism /apply-image /imagefile:%WimFile% /index:1 /ApplyDir:w:\
Echo.
echo STEP 3 of 5 Adding boot files (should take approx 2-5 mins)
Echo.
W:\Windows\System32\bcdboot W:\Windows /l en-US
Echo.
echo STEP 4 of 5 Copying unattend file(should take >2 mins)
Echo.
Copy "%USBLetter%:\images\win10unattend.xml" W:\unattend.xml
Echo.
echo STEP 5 of 5 Upgrading edition to Professional (should take approx 10-15 mins)
Echo.
Dism /Image:W: /Set-Edition:Professional
Echo.
echo Rebooting into your new install now, ctrl + c to cancel
Echo.
Timeout /T 20
exit
REM End of Option 2

REM Start of Option 3
:WinCustom
SET /P Q=This branch performs a custom windows install. Would you like to cancel this(y/n)
IF %Q%==y GOTO Menu
SET Mark=1
SET /P Q1=Auto format, guided format or custom format(1,2,3)?
SET /P Q2=Would you like to use an unattend file?
SET /P Q3=Would you like to upgrade the edition?
for %%a in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do @IF EXIST %%a:\images ( echo All the .wim files in %%a\Images: & echo. & dir %%a:\images\*.wim ) ELSE ( @IF EXIST %%a: Vol %%a: & echo. )
echo All drives are listed above, listings provided only for Images folder if at drive root
ECHO.
SET /P CustomWimFile=Where is the .wim you want to install?
IF %Q1%==1 GOTO AutoFormat
IF %Q1%==2 GOTO GuidedFormat
IF %Q1%==3 GOTO CustomFormat
:AutoFormat
Echo.
echo STEP 1 (Auto Format) Formatting Disk 0 (should take approx 2-5 mins)
Echo.
echo  select disk 0 >FormatDrive.bat
echo clean >>FormatDrive.bat
echo create partition primary size=300 >>FormatDrive.bat
echo format quick fs=ntfs label="System" >>FormatDrive.bat
echo assign letter="v" >>FormatDrive.bat
echo active >>FormatDrive.bat
echo create partition primary >>FormatDrive.bat
echo format quick fs=ntfs label="Windows" >>FormatDrive.bat
echo assign letter="w" >>FormatDrive.bat
echo list volume >>FormatDrive.bat
echo exit >>FormatDrive.bat
diskpart.exe /s FormatDrive.bat
del FormatDrive.bat
goto WinCustomInstall
:GuidedFormat
Echo.
echo STEP 1 (Guided Format) Will format requested disk (should take approx 2-5 mins)
Echo.
echo list volume >List.bat
echo list disk >>List.bat
echo exit >>List.bat
diskpart.exe /s List.bat
del List.bat
SET /P Format=Drive to format (number):
ECHO Formating Drive %Format%
echo  select disk %Format% >FormatDrive.bat
echo clean >>FormatDrive.bat
echo create partition primary size=300 >>FormatDrive.bat
echo format quick fs=ntfs label="System" >>FormatDrive.bat
echo assign letter="v" >>FormatDrive.bat
echo active >>FormatDrive.bat
echo create partition primary >>FormatDrive.bat
echo format quick fs=ntfs label="Windows" >>FormatDrive.bat
echo assign letter="w" >>FormatDrive.bat
echo list volume >>FormatDrive.bat
echo exit >>FormatDrive.bat
diskpart.exe /s FormatDrive.bat
del FormatDrive.bat
goto WinCustomInstall
:CustomFormat
Echo.
echo STEP 1 (Custom Format) 
Echo.
echo As requested, you're on your own for this one, but here's a sample script 
echo Please note that the Windows drive letter must be W and system V
echo select disk 
echo clean **DO NOT use if wishing to preserve backup
echo create partition primary size=300 
echo format quick fs=ntfs label="System" 
echo assign letter="v" 
echo active 
echo create partition primary 
echo format quick fs=ntfs label="Windows" 
echo assign letter="w" 
echo list volume 
echo exit 
diskpart.exe
goto WinCustomInstall
:WinCustomInstall
Echo.
echo STEP 2 (Windows Install) Will install requested wim to requested disk (should take approx 20-35 mins)
Echo.
Dism /apply-image /imagefile:%CustomWimFile% /index:1 /ApplyDir:w:\
Echo.
echo STEP 3 (Boot File Install) Copies boot files(should take approx 2-5 mins)
Echo.
W:\Windows\System32\bcdboot W:\Windows /l en-US
IF %Q2%==y GOTO WinUnattend
IF %Q3%==y GOTO UpgradeEdition
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
Goto exit
:WinUnattend
Echo.
echo STEP 4 (Unattend File) Will copy requested xml to requested disk (should take >2 mins)
Echo.
for %%a in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do @IF EXIST %%a:\images ( echo All the .wim files in %%a\Images: & echo. & dir %%a:\images\*.xml ) ELSE ( @IF EXIST %%a: Vol %%a: & echo. )
echo All drives are listed above, listings provided only for Images folder if at drive root
ECHO.
SET /P CustomxmlFile=Where is the .xml file you want to copy?
echo Making %CustomxmlFile% into W:\unattend.xml
Copy "%CustomxmlFile%" W:\unattend.xml
IF %Q3%==y GOTO UpgradeEdition
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
Goto exit
:Exit
Echo.
echo Rebooting into your new install now, ctrl + c to cancel
Echo.
echo Rebooting now (unless you press control c quickly)
Timeout /T 20
exit
Goto Menu
REM End of Option 3

REM Option 4
:InstallTask
echo Here are some likely suspects for an custom install path:
ECHO ShrinkDisk
ECHO CreateImage 
ECHO listVol - List volumes and disks
ECHO Format - Format drive does not do win prep unless requested
ECHO NetDrive - Net use
ECHO Menu - Menu 
ECHO OpenDiskpart
ECHO WinCustom - Installs windows DO NOT go straight to WinCustomInstall
ECHO Exit - gives timer so user can cancel, good practice
echo.
ECHO NOTE WinUnattend and UpgradeEdition must be explictly included Only 6 forks supported
SET /P Con1=What switch would you like to run first:
if NOT con1==0 set con12=1
SET /P Con2=What switch would you like to run second:
if NOT con2==0 set con22=1
SET /P Con3=What switch would you like to run third:
if NOT con3==0 set con32=1
SET /P Con4=What switch would you like to run fourth:
if NOT con4==0 set con42=1
SET /P Con5=What switch would you like to run fifth:
if NOT con5==0 set con52=1
SET /P Con6=What switch would you like to run sixth:
if NOT con6==0 set con62=1
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
Goto Menu

REM Option 5 also refered to by part of option 3
:UpgradeEdition
if %mark%==1 echo STEP 5 (Edition upgrade) Will upgrade windows to requested edition (should take 10-15 mins)
SET /P OfflineImage=Where is the Windows install you'd like to upgrade?:
Dism /Image:"%OfflineImage%" /Get-CurrentEdition /Get-TargetEditions
SET /P UpgradeEdition=What edition would you like to upgrade it to?:
Dism /Image:"%OfflineImage%" /Set-Edition:"%UpgradeEdition%"
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
if %mark%==1 goto exit else goto menu

REM Option 6
:AddDrivers
ECHO Not Yet Implimented
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
Goto Menu

REM Option 7
:CreateImage
SET /P CaptureDir=Where is the drive or folder you'd like to capture?:
SET /P ImageFile=Where do you want to put it, and what name do you want to give it:
Dism /Capture-Image /ImageFile:"%ImageFile%" /CaptureDir:"%CaptureDir%" /Name:Image1  
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
Goto Menu

REM Option 8
:ListVol
echo list volume >List.bat
echo list disk >>List.bat
echo exit >>List.bat
diskpart.exe /s List.bat
del List.bat
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
Goto Menu

REM Option 9
:ShrinkDisk
echo list volume >List.bat
echo list disk >>List.bat
echo exit >>List.bat
diskpart.exe /s List.bat
del List.bat
SET /P Vol=What volume would you like to shrink (number, not letter):
echo select volume %Vol% >ShrinkQuery.bat
echo Shrink querymax >>ShrinkQuery.bat
echo exit >>ShrinkQuery.bat
diskpart.exe /s ShrinkQuery.bat
del ShrinkQuery.bat
SET /P DESIRED=How much do you want to shrink the disk by:
SET /P MINIMUM=What is the absolute mimium that'll do:
echo select volume %Vol% >Shrink.bat
echo Shrink DESIRED=%DESIRED% MINIMUM=%MINIMUM% >>Shrink.bat
echo exit >>Shrink.bat
diskpart.exe /s Shrink.bat
del Shrink.bat
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
Goto Menu

REM Option 10
:openDiskpart
Diskpart.exe
Goto Menu

REM Option 11
:Format
echo list volume >List.bat
echo list disk >>List.bat
echo exit >>List.bat
diskpart.exe /s List.bat
del List.bat
SET /P Format=Drive to format (number):
SET /P Q1=Use standard windows prep (y/n)?
IF %Q1%==y GOTO winprep
IF %Q1%==n GOTO Format2
:winprep
echo  select disk %Format% >FormatDrive.bat
echo clean >>FormatDrive.bat
echo create partition primary size=300 >>FormatDrive.bat
echo format quick fs=ntfs label="System" >>FormatDrive.bat
echo assign letter="v" >>FormatDrive.bat
echo active >>FormatDrive.bat
echo create partition primary >>FormatDrive.bat
echo format quick fs=ntfs label="Windows" >>FormatDrive.bat
echo assign letter="w" >>FormatDrive.bat
echo list volume >>FormatDrive.bat
echo exit >>FormatDrive.bat
diskpart.exe /s FormatDrive.bat
del FormatDrive.bat
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
GOTO menu
:Format2
ECHO Formating Drive %Format%
echo select disk %Format% >FormatDrive.bat
echo clean >>FormatDrive.bat
echo exit >>FormatDrive.bat
diskpart.exe /s FormatDrive.bat
del FormatDrive.bat
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
GOTO menu
REM End of Option 11

REM Option 12
:NetDrive
SET /P NetDisk=Full path to network share:
SET /P MntDisk=Drive letter to mount to (Drive Letter + Colon):
net use %MntDisk% "%netDisk%"
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
GOTO menu

REM Option 13
:ipconfig
ipconfig
GOTO menu

REM Option 14
:nslookup
nslookup
GOTO menu

REM Option 15
:Hack
SET /P WinDisk=Where is Windows installed (Drive Letter + Colon):
SET /P M7=Would you like to copy the SAM file first(y/n):
IF %M7%==y GOTO CopySAM
IF %M7%==n GOTO ReplaceSethc
:CopySAM
SET /P SAMCopy=Path to put SAM in (Full path):
cd %WinDisk%\Windows\System32\config\
Copy SAM %SAMCopy%\SAM
cd %WinDisk%\Windows\System32\
Copy SAM %SAMCopy%\SAM
goto ReplaceSethc
:ReplaceSethc
Copy %WinDisk%\Windows\System32\sethc.exe %WinDisk%\Windows\System32\seth.exe
Copy %WinDisk%\Windows\System32\cmd.exe %WinDisk%\Windows\System32\sethc.exe
if NOT %con12%==0 set con12=0 & goto %con1%
if NOT %con22%==0 set con22=0 & goto %con2%
if NOT %con32%==0 set con32=0 & goto %con3%
if NOT %con42%==0 set con42=0 & goto %con4%
if NOT %con52%==0 set con52=0 & goto %con5%
if NOT %con62%==0 set con62=0 & goto %con6%
SET /P M7=Would you like to reboot now (y/n):
IF %M7%==y exit
IF %M7%==n GOTO menu
REM End of Option 15

REM Option 16
:Notepad
cd %windir%
start Notepad.exe
GOTO MENU

REM Option 17
:Regedit
cd %windir%
start regedit.exe
GOTO MENU