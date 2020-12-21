'********** Part 1 Declaring and Defining Variables ******************

'VBS wants this, so it gets it
Option Explicit 
On Error Resume Next 
'Declaring vars beacause VBS says I must
Dim objWMIService, objItem, colItems, FSO, strComputer, File, oShell, user, comp, GB, report, mhz, TextOutput

TextOutput = ""
'Setting up env vars
Set oShell = CreateObject( "WScript.Shell" )
user=oShell.ExpandEnvironmentStrings("%UserProfile%")
comp=oShell.ExpandEnvironmentStrings("%ComputerName%")

'This is needed
strComputer = "localhost"

'Setting things up to work with the WMI system
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

'********** Part 4 Computer Information  ******************

'Writes general info about the computer to html file
TextOutput = TextOutput + "General Information" & vbCrLf

'Getting the right WMI object
Set colItems = objWMIService.ExecQuery("Select * from Win32_ComputerSystem") 

For Each objItem in colItems
	'Trying to get a nice neat figure in gigabytes
	GB = objItem.TotalPhysicalMemory
	GB = GB / 1000000000
	'This bit is doing the actual work
				    TextOutput = TextOutput +"Manufacturer: " & objItem.Manufacturer & vbCrLfLf
	TextOutput = TextOutput +"Model:      " & objItem.Model & vbCrLf
	TextOutput = TextOutput +"SystemType:   " & objItem.SystemType & vbCrLf
	TextOutput = TextOutput +"PCSystemType:   " & objItem.PCSystemType & vbCrLf
	TextOutput = TextOutput +"NumberOfProcessors: " & objItem.NumberOfProcessors & vbCrLf
	TextOutput = TextOutput +"Total Ram in Bytes: " & objItem.TotalPhysicalMemory & vbCrLf
	TextOutput = TextOutput +"Total Ram in GB:  " & round(GB) & vbCrLf
	TextOutput = TextOutput +"Note: If the second digit of the bytes number is 4 or 5, double check the memory size, as the GB figure may have been rounded incorrectly"
next

'********** Part 5 Disk Information  ******************

'Writes info about the disk to html file
TextOutput = TextOutput + vbCrLf & vbCrLf & "Disk Information" & vbCrLf
Set colItems = objWMIService.ExecQuery("Select * from Win32_diskdrive") 
For Each objItem in colItems
	'Getting nice neat figure in gigabytes
	GB = objItem.size
	GB = GB / 1000000000
	'Writing to the file
	TextOutput = TextOutput +"Manufacturer:  " & objItem.Manufacturer & vbCrLf
	TextOutput = TextOutput +"Model:    " & objItem.Model  & vbCrLf
	TextOutput = TextOutput +"InterfaceType: " & objItem.InterfaceType  & vbCrLf
	TextOutput = TextOutput +"Health Status: " & objItem.status & vbCrLf
	TextOutput = TextOutput +"Size in Bytes: " & objItem.size & vbCrLf
	TextOutput = TextOutput +"Size in GB:    " & GB & vbCrLf
	TextOutput = TextOutput +"Serial Numbers:    " & objItem.SerialNumber & vbCrLf
next

'********** Part 6 Video Information  ******************

'Writes info about the Video controller to html file
TextOutput = TextOutput + vbCrLf & "Video Chipset Information" & vbCrLf

Set colItems = objWMIService.ExecQuery("Select * from Cim_PCvideoController") 
For Each objItem in colItems
	TextOutput = TextOutput +"Video Card/Chipset: " & objItem.name & vbCrLf
next

'********** Part 7 CPU Information  ******************

'Writes info about the CPU to html file
TextOutput = TextOutput + vbCrLf & "CPU Information" & vbCrLf
Set colItems = objWMIService.ExecQuery("Select * from Win32_Processor") 
For Each objItem in colItems
	mhz = objItem.MaxClockSpeed
	mhz = mhz / 1000
	TextOutput = TextOutput +"CPU Name:    " & objItem.name & vbCrLf
	TextOutput = TextOutput +"Number of Cores:   " & objItem.NumberOfCores & vbCrLf
	TextOutput = TextOutput +"Number of Threads: 	" & objItem.NumberOfLogicalProcessors & vbCrLf
	TextOutput = TextOutput +"Clock Speed:   " & mhz & vbCrLf
next

'********** Part 8 Memory Configuration Info  ******************

TextOutput = TextOutput + vbCrLf & "Memory Configuration" & vbCrLf
Set colItems = objWMIService.ExecQuery("Select * from Win32_PhysicalMemory") 
For Each objItem in colItems
	GB = objItem.Capacity
	GB = GB / 1000000000
	TextOutput = TextOutput +"Bank Label: " & objItem.BankLabel & vbCrLf
	TextOutput = TextOutput +"Device Locator: " & objItem.DeviceLocator & vbCrLf
	TextOutput = TextOutput +"Speed in Mhz: " & objItem.Speed & vbCrLf
	TextOutput = TextOutput +"Size in Bytes: " & objItem.Capacity & vbCrLf
	TextOutput = TextOutput +"Size in GB:    " & GB & vbCrLf
next

'********** Part 9 Unique IDs Info  ******************

TextOutput = TextOutput + vbCrLf & "Unique Ids" & vbCrLf

Set colItems = objWMIService.ExecQuery("Select * from Win32_ComputerSystemproduct") 
For Each objItem in colItems
	TextOutput = TextOutput +"Service Tag:   " & objItem.IdentifyingNumber & vbCrLf
	TextOutput = TextOutput +"SKUNumber:  " & objItem.SKUNumber & vbCrLf
	TextOutput = TextOutput +"UUID:   " & objItem.UUID & vbCrLf
next

'********** Part 10 (Optitional)Battery Info  ******************

TextOutput = TextOutput + vbCrLf & "Battery Info" & vbCrLf

Set colItems = objWMIService.ExecQuery("Select * from Win32_battery") 

For Each objItem in colItems
	TextOutput = TextOutput +"Caption:  " & objItem.Caption & vbCrLf
	TextOutput = TextOutput +"BatteryStatusNum:   " & objItem.BatteryStatus & vbCrLf
	TextOutput = TextOutput +"Chemistry:   " & objItem.Chemistry & vbCrLf
	TextOutput = TextOutput +"Health Status:   " & objItem.status & vbCrLf
next
Wscript.Echo(TextOutput)
WSCript.Quit