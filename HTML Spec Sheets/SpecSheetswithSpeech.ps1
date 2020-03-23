
<#
************** Overview **************

This one's just a bit of fun. Same as it's counterparts but speaks what it's doing.This script 
creates a HTML specsheet for the computer it is run on, and saves it on the current user's 
desktop. As part of this script PowerCfg will save a Battery Report on the desktop also.

************** Formatting Information ******************

HTML File Naming format: "Spec Report from User-PC (21st of May).htm" Vars used for that are $env:computername $date
Battery Report naming format: "Battery Report from User-PC.html" Uses $env:computername only
Text size: H2 for main header, H3 for sub-headings, H4 for normal test and H5 for the note
Other Formatting: Font: Segoe UI Light, Spacing: 0.02em, Margin: 5.5em, line-height: 1.7em
The battery report HTML file also introduces it's own formatting, though this is mostly fine now
Colors: rgb(35, 73, 116) for background, white for normal text, and #11EEF4 for headings
#>

#*************** Intial Speech ******************

add-type -assemblyname system.speech 
$Speak = New-Object System.Speech.Synthesis.SpeechSynthesizer 
$speak.Speak("Windows Install completed on $env:computername. Now generating specsheet") 

#*************** Setting up Filename ******************

$Date = get-date
$date = $date.ToLongDateString()
$FileName = "Spec Report from $env:computername `($date`)" 

#*************** Getting WMI Objects ******************

$1 = Get-WmiObject Win32_ComputerSystem | Select-Object -property Manufacturer,Model,NumberOfProcessors,PCSystemType,SystemType,@{Label="RAMSizeInBytes"; Expression={ForEach-Object {$_.TotalPhysicalMemory}}},@{Label="RAMSizeinGB"; Expression={ForEach-Object {$_ = $_.TotalPhysicalMemory / 1gb; if (($_ -like "*.4*") -or ($_ -like "*.5*") -or ($_ -like "*.6*")) {$_} else {$_ = [math]::round($_); $_}}}} 
$2 = get-disk | Select-Object Manufacturer,Model,BusType,HealthStatus,@{Label="HDDSizeInBytes"; Expression={ForEach-Object {$_.size}}},@{Label="Size in Gigabytes"; Expression={ForEach-Object {$_ = $_.size / 1000000000; [math]::round($_)}}}    
$3 = get-wmiobject Cim_PCvideoController | Select-Object -Property name -Unique
$4 = Get-WmiObject Win32_Processor | Select-Object Name,NumberOfCores,@{Label="Threads"; Expression={$_.NumberOfLogicalProcessors}},@{Label="Clock Speed in ghz"; Expression={ForEach-Object {$_.MaxClockSpeed / 1000}}}
$5 = Get-WmiObject Win32_PhysicalMemory | Select-Object BankLabel,DeviceLocator,@{Label="Speed in Mhz"; Expression={$_.Speed}},@{Label="Capacity in Bytes"; Expression={ForEach-Object {$_.Capacity}}},@{Label="Capacity in GB"; Expression={ForEach-Object {$_ = $_.Capacity / 1000000000; [math]::Truncate($_)}}}
$6 = Get-WmiObject Win32_ComputerSystemproduct | Select-Object -property IdentifyingNumber,SKUNumber,UUID
$7 = Get-WmiObject cim_battery

#*************** Adding Style Sheet and Header to HTML file ******************

"<!DOCTYPE html>
`<html xmlns`=`"http://www.w3.org/1999/xhtml`" xmlns`:ms`=`"urn:schemas-microsoft-com:xslt`" xmlns`:bat`=`"http://schemas.microsoft.com/battery/2012`" xmlns:js=`"http://microsoft.com/kernel`"`>`<head`>`<meta http-equiv`=`"X-UA-Compatible`" content`=`"IE=edge`"`/`>`<meta name`=`"ReportUtcOffset`" content=`"+1:00`"`/`>
`<title`>$FileName`<`/title`>`<style type`=`"text/css`"`>

      body `{

          font`-family`: Segoe UI Light`;

          letter`-spacing`: 0.02em`;

          background`-color`: rgb`(35, 73, 116`)`;

          color`: white`;

          margin`-left`: 5.5em`;

          line-height`: 1.7em`;

      `}
`<`/style`> `<body`>" > "$env:userprofile\desktop\$FileName.htm"

#*************** Writing general overveiw info to HTML file ******************
$1 | convertto-html -as list -fragment  -precontent "`<h1 style`=`"text-align:center`"`>Specifications`
of $env:computername`</h1`>`<h3 style`=`"font-style:bold;Color:`#11EEF4`"`>General Overview`</h3`>`</p`>`
`<h4>" -postcontent '</h4>' >>"$env:userprofile\desktop\$FileName.htm"
"<h5>Note: If the second digit of the bytes number is 4 or 5,<br>double check the memory size, 
as the GB figure may<br>have been rounded incorrectly</h5>" >>"$env:userprofile\desktop\$FileName.htm"

#*************** Writing disk info to HTML file ******************
$2 | convertto-html -as list -fragment -precontent '<p><h3 style="font-style:bold;Color:#11EEF4">Disk `
Information</h3></p><h4>' -postcontent '</h4>' >>"$env:userprofile\desktop\$FileName.htm"

#*************** Writing Video controller info to HTML file ******************
$3 | convertto-html -as list -fragment -precontent '<p><h3 style="font-style:bold;Color:#11EEF4">Video 
Chipset Information</h3></p><h4>' -postcontent '</h4>' >>"$env:userprofile\desktop\$FileName.htm"

#*************** Writing CPU info to HTML file ******************
$4 | convertto-html -as list -fragment -precontent '<p><h3 style="font-style:bold;Color:#11EEF4">CPU 
Information</h3></p><h4>' -postcontent '</h4>' >>"$env:userprofile\desktop\$FileName.htm"

#*************** Writing Memory Configuration info to HTML file ******************
$5 | convertto-html -as list -fragment -precontent '<p><h3 style="font-style:bold;Color:#11EEF4">Memory 
Configuration</h3></p><h4>' -postcontent '</h4>' >>"$env:userprofile\desktop\$FileName.htm"

#*************** Writing Unique IDs info to HTML file ******************
$6 | convertto-html -as list -fragment -precontent '<p><h3 style="font-style:bold;Color:#11EEF4">Unique 
Ids</h3></p><h4>' -postcontent '</h4>' >>"$env:userprofile\desktop\$FileName.htm" 

#*************** Testing whether the computer has a battery installed ******************
if ( $7 -ne $null ) {
    #**** Reducing the properties to the ones we want ******
    $7 = $7 | Select-Object -property BatteryStatus,Caption,Chemistry,status

    #**** Invoking PowerCfg to get battery report ******
    Powercfg /batteryreport /output "$env:userprofile\desktop\Battery Report from $env:computername.html"

    #**** Getting the content of the HTML file that created ******
    $Battery = get-content "$env:userprofile\desktop\Battery Report from $env:computername.html"

    #**** Replaces some lines from the file for styling ***** 
    $Battery[10] = 'background-color:rgb(35, 73, 116);'
    #$Battery[12] = 'color:rgb(25, 131, 158);'
    $Battery[25] = 'text-align:center;'
    $Battery[112] = 'background-color:rgb(35, 73, 116);'
    $Battery[114] = 'color:white;'

    #*****Writing Battery info to HTML file ******
    $7 | convertto-html -as list -Fragment -precontent '<p><h3 style="font-style:bold;Color:#11EEF4">Battery Info</h3></p><h4>' -postcontent '</h4>' >>"$env:userprofile\desktop\$FileName.htm" 

} else {$battery = '<p> <h4>No battery Present </h4></p>' }

#*************** Finishing the html file ******************
$Battery >> "$env:userprofile\desktop\$FileName.htm"
'</body> </html>' >> "$env:userprofile\desktop\$FileName.htm"

#*************** Setting the vars up for speech ******************
$Manufacturer = $1.Manufacturer 
$Model = $1.Model
$CPU = $4 | Select-Object -ExpandProperty name
$RAM = $1.RAMSizeinGB
if ($CPU -like "*i3*") {$CPU = "an i3"}
if ($CPU -like "*i5*") {$CPU = "an i5"; $value = "I'm worth quite a lot of money aren't I?"}
if ($CPU -like "*i7*") {$CPU = "an i7"; $value = "I'm worth lots and lots of money!" }
if ($CPU -like "*Pentium*") {$CPU = "a Pentium"}
if ($CPU -like "*Celeron*") {$CPU = "a Celeron"}
if ($CPU -like "*xeon*") {$CPU = "a Xeon"; $value = "I'm a Workstation but I'd like to be a server."}
if ($CPU -like "*Intel*") {$CPU = "an Intel"}
if ($CPU -like "*AMD*") {$CPU = "an AMD"}

#****************** Second Speech ****************
$speak.Speak("I, a $Manufacturer $Model have successfully generated a spec sheet. By the way, I have $CPU CPU and $RAM gigabytes of RAM. $value") 

# Could use to copy to server never worked
#****************** Tries to copy to server ****************
#copy-item "$env:userprofile\desktop\$FileName.htm" "\\WDS-Server\specs\$FileName.htm" 
