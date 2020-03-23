echo off
rem Batch HTML specsheet script Not at all nice, but does work VBS and PS scripts much better though
echo Spec sheet script started. Writing to %userprofile%\desktop\SpecSheetFrom%computerName%.html
echo Writing out CSS style info 
echo ^<htmL^> ^<title^>Spec Report From %ComputerName%^</title^>^<style type="text/css"^> >%userprofile%\desktop\SpecSheetFrom%computerName%.html
      echo body {>>%userprofile%\desktop\SpecSheetFrom%computerName%.html
          echo font-family: Segoe UI Light;>>%userprofile%\desktop\SpecSheetFrom%computerName%.html
          echo letter-spacing: 0.02em;>>%userprofile%\desktop\SpecSheetFrom%computerName%.html
          echo background-color: rgb(35, 73, 116);>>%userprofile%\desktop\SpecSheetFrom%computerName%.html
          echo color: white;>>%userprofile%\desktop\SpecSheetFrom%computerName%.html
          echo margin-left: 5.5em;>>%userprofile%\desktop\SpecSheetFrom%computerName%.html
          echo line-height: 1.7em;>>%userprofile%\desktop\SpecSheetFrom%computerName%.html
      echo }>>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^</style^> ^<body^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^>^<h1 style="text-align:center;Color:#11EEF4"^>Specifications of %ComputerName% ^</h1^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html

echo Getting genral PC information
WmiC ComputerSystem get Manufacturer >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC ComputerSystem get Model >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC ComputerSystem get NumberOfProcessors >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC ComputerSystem get PCSystemType >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC ComputerSystem get SystemType >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC ComputerSystem get TotalPhysicalMemory >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html

echo Getting HDD information
WmiC diskdrive get Manufacturer >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC diskdrive get Model >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC diskdrive get InterfaceType >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC diskdrive get status >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC diskdrive get size >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html

echo Getting CPU info
WmiC CPU get Name >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC CPU get NumberOfCores >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC CPU get NumberOfLogicalProcessors >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
WmiC CPU get MaxClockSpeed >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html

echo Getting memory info
wmic memorychip get BankLabel >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
wmic memorychip get DeviceLocator >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
wmic memorychip get Speed >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
wmic memorychip get Capacity >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html

echo Getting video controller info
wmic path cim_VideoController get name >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html

echo Getting Unique ID info
wmic CSproduct get IdentifyingNumber >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
wmic CSproduct get SKUNumber >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
wmic CSproduct get UUID >>%userprofile%\desktop\SpecSheetFrom%computerName%.html
echo ^<br^> ^<br^> >>%userprofile%\desktop\SpecSheetFrom%computerName%.html

echo Getting battery report
powercfg.exe /batteryReport /output "%UserProfile%\desktop\Battery Report.html"

pause