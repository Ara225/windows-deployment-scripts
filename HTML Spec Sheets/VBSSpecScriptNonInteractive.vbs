
'*************** Information ********************

'This script creates a HTML specsheet for the computer its run on,and saves it on the current user's desktop 
'along with a file called CreateBatteryReport.bat, which creates a battery report when invoked by the user (see part 11 for notes)

'Text size: H1 for main header, H2 for sub-headings, H3 for normal text and H4 for the note
'Other Formatting: Font: Segoe UI Light, Spacing: 0.02em, Margin: 5.5em, line-height: 1.7em
'Colors: rgb(35, 73, 116) for background, white for normal text, and #11EEF4 for headings

'********** Part 1 Declaring and Defining Variables ******************

'VBS wants this, so it gets it
Option Explicit 
On Error Resume Next 
'Declaring vars beacause VBS says I must
Dim objWMIService, objItem, colItems, FSO, strComputer, File, oShell, user, comp, GB, report, mhz

'Setting up env vars
Set oShell = CreateObject( "WScript.Shell" )
user=oShell.ExpandEnvironmentStrings("%UserProfile%")
comp=oShell.ExpandEnvironmentStrings("%ComputerName%")

'This is needed
strComputer = "localhost"

'Setting things up to work with the WMI system
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

'creating a var to work with the filesystem and creating HTML file
Set FSO = CreateObject("Scripting.FileSystemObject")
Set File = FSO.CreateTextFile( user & "\desktop\Spec Report from " & comp & " VBS Version.htm",True)

'********** Part 2 Messages to the User  ******************

'Displays first message box
'Wscript.Echo "This script will generate a specsheet for this computer and save it on your desktop. Another notification will be displayed when it is generated. Click OK to begin"

'Displays a question box
'report = msgbox("Does this computer have a battery?", 4, "Important Question")

'********** Part 3 Styling & Setting Up (For the HTML file)  ******************

'Writes Styling info to html file
File.Write "<html><head><style 'type=text/css'>" & vbCr &_
"body {" & vbCr &_
"font-family: Segoe UI Light;" & vbCr &_
"letter-spacing: 0.02em;" & vbCr &_
"background-color: rgb(35, 73, 116);" & vbCr &_
"color: white;" & vbCr &_
"margin-left: 5.5em;" & vbCr &_
"line-height: 1.7em;" & vbCr &_
"font-size: 12pt;"  & vbCr &_
"}" & vbCr &_
"h3 {" & vbCr &_
"font-size: 20pt;" & vbCr &_	
"}" & vbCr &_
"h4 {" & vbCr &_
"font-size: 13pt;" & vbCr &_	
"}" & vbCr &_
"h1 {" & vbCr &_
"font-size: 32pt;" & vbCr &_	
"}" & vbCr &_
"</style><title>Spec Sheet from" & comp & "</title> <body>" & vbCr

'Writes heading to html file
File.Write "<h1 style=""text-align:center;Color:#11EEF4""><BR>Specifications of " & comp & "</h1>" & vbCr

'********** Part 4 Computer Information  ******************

'Writes general info about the computer to html file
File.Write "<h3 style=""font-style:bold;Color:#11EEF4"">General Information</h3><h4> "

'Getting the right WMI object
Set colItems = objWMIService.ExecQuery("Select * from Win32_ComputerSystem") 

For Each objItem in colItems
	'Trying to get a nice neat figure in gigabytes
	GB = objItem.TotalPhysicalMemory
	GB = GB / 1000000000
	'This bit is doing the actual work
	File.Write "Manufacturer: " & objItem.Manufacturer & "<br>" & vbCr
	File.Write "Model:      " & objItem.Model  & "<br>" & vbCr
	File.Write "SystemType:   " & objItem.SystemType & "<br>" & vbCr
	File.Write "PCSystemType:   " & objItem.PCSystemType & "<br>" & vbCr
	File.Write "NumberOfProcessors: " & objItem.NumberOfProcessors & "<br>" & vbCr
	File.Write "Total Ram in Bytes: " & objItem.TotalPhysicalMemory & "<br>" & vbCr
	File.Write "Total Ram in GB:  " & round(GB) & "<br> " & vbCr
	File.Write "<h5 style=""line-height: 1.5em;font-size:12pt"">Note: If the second digit of the bytes number is 4 or 5,<br>double check the memory size, as the GB figure may<br>have been rounded incorrectly</h5>"
next

'********** Part 5 Disk Information  ******************

'Writes info about the disk to html file
File.Write "<h3 style=""font-style:bold;Color:#11EEF4"">Disk Information</h3><h4> " & vbCr
Set colItems = objWMIService.ExecQuery("Select * from Win32_diskdrive") 
For Each objItem in colItems
	'Getting nice neat figure in gigabytes
	GB = objItem.size
	GB = GB / 1000000000
	'Writing to the file
	File.Write "Manufacturer:  " & objItem.Manufacturer & "<br>" & vbCr
	File.Write "Model:    " & objItem.Model  & "<br>" & vbCr
	File.Write "InterfaceType: " & objItem.InterfaceType  & "<br>" & vbCr
	File.Write "Health Status: " & objItem.status & "<br>" & vbCr
	File.Write "Size in Bytes: " & objItem.size & "<br>" & vbCr
	File.Write "Size in GB:    " & GB & "<br><br>" & vbCr
next

'********** Part 6 Video Information  ******************

'Writes info about the Video controller to html file
File.Write "<h3 style=""font-style:bold;Color:#11EEF4"">Video Chipset Information</h3><h4> " & vbCr
Set colItems = objWMIService.ExecQuery("Select * from Cim_PCvideoController") 
For Each objItem in colItems
	File.Write "Video Card/Chipset: " & objItem.name & "<br>" & vbCr
next

'********** Part 7 CPU Information  ******************

'Writes info about the CPU to html file
File.Write "<h3 style=""font-style:bold;Color:#11EEF4   "">CPU Information</h3><h4> " & vbCr
Set colItems = objWMIService.ExecQuery("Select * from Win32_Processor") 
For Each objItem in colItems
	mhz = objItem.MaxClockSpeed
	mhz = mhz / 1000
	File.Write "CPU Name:    " & objItem.name & "<br>" & vbCr
	File.Write "Number of Cores:   " & objItem.NumberOfCores & "<br>" & vbCr
	File.Write "Number of Threads: 	" & objItem.NumberOfLogicalProcessors & "<br>" & vbCr
	File.Write "Clock Speed:   " & mhz & "<br><br>" & vbCr
next

'********** Part 8 Memory Configuration Info  ******************

File.Write "<h3 style=""font-style:bold;Color:#11EEF4"">Memory Configuration</h3><h4> " & vbCr
Set colItems = objWMIService.ExecQuery("Select * from Win32_PhysicalMemory") 
For Each objItem in colItems
	GB = objItem.Capacity
	GB = GB / 1000000000
	File.Write "Bank Label: " & objItem.BankLabel & "<br>" & vbCr
	File.Write "Device Locator: " & objItem.DeviceLocator & "<br>" & vbCr
	File.Write "Speed in Mhz: " & objItem.Speed & "<br>" & vbCr
	File.Write "Size in Bytes: " & objItem.Capacity & "<br>" & vbCr
	File.Write "Size in GB:    " & GB & "<br><br>" & vbCr
next

'********** Part 9 Unique IDs Info  ******************

File.Write "<h3 style=""font-style:bold;Color:#11EEF4   "">Unique Ids</h3><h4> " & vbCr
Set colItems = objWMIService.ExecQuery("Select * from Win32_ComputerSystemproduct") 
For Each objItem in colItems
	File.Write "Service Tag:   " & objItem.IdentifyingNumber & "<br>" & vbCr
	File.Write "SKUNumber:  " & objItem.SKUNumber & "<br>" & vbCr
	File.Write "UUID:   " & objItem.UUID & "<br>" & vbCr
next

'********** Part 10 (Optitional)Battery Info  ******************

File.Write "<h3 style=""font-style:bold;Color:#11EEF4"">Battery Info</h3><h4> " & vbCr
Set colItems = objWMIService.ExecQuery("Select * from Win32_battery") 

For Each objItem in colItems
	File.Write "Caption:  " & objItem.Caption & "<br>" & vbCr
	File.Write "BatteryStatusNum:   " & objItem.BatteryStatus & "<br>" & vbCr
	File.Write "Chemistry:   " & objItem.Chemistry & "<br>" & vbCr
	File.Write "Health Status:   " & objItem.status & "<br>" & vbCr
next
File.Write "</h4></html></body>" & vbCr
File.Close

'********** Part 11 Creating CreateBatteryReport.bat  ******************

'Set FSO = CreateObject("Scripting.FileSystemObject")
'Set File = FSO.CreateTextFile( user & "\desktop\CreateBatteryReport.bat",True)
'File.Write "C:\windows\system32\powercfg.exe /batteryreport & pause"
'Note: It is neccessary to do this this way as powercfg can't be invoked directly from the script.
'PowerCfg refuses to load energy.dll which is neccessary for this operation if invoked from this vbs script
'Disabled as WDS deploy doesn't need

'********** Part 12 Finishing up  ******************

'Wscript.Echo "Spec sheet saved successfully!" & vbCr & vbCr & "It is saved on the desktop as Spec Report from " & comp & " VBS Version.htm " & vbCr & vbCr &_ 
'"If required, a Battery Report can easily be created by clicking on the CreateBatteryReport.bat file, also on the desktop, which will output to Battery-Report.htm on the desktop"
WSCript.Quit