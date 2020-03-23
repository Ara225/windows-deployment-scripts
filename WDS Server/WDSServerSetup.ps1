#This script written by Anna Aitchison.
#Final Draft complete 06/05/2019
write-Warning "THINGS TO DO BEFORE RUNNING
Mount 32/64 bit Win 10 ISO
Ensure that the server has an internet connection, or WDS int will fail
Find the unattend for WDS
Decide where to put the WDS folder
Copy all the images you want to add to the same folder
You will not be prompted to confirm which images you want to add, all WIM files in the folder (and all sub folders) will be added"
pause

get-volume
$Server = Read-Host -Prompt 'What drive would you like to put the WDS folder in? (letter+colon)'
$unattend = Read-Host -Prompt 'Where is the unattend for WDS full path e.g. C:\wds\unattend.xml (inc quotes if required)'
$BootImage = Read-Host -Prompt 'Where is the mounted iso with the Boot.wim file? (letter+colon)'  
Write-Warning "Input the location of the *.wim files you want to add to WDS. This will recurse!
Write the path as without the quotation marks ""C:\BlaBla\"" or as UNC-path ""\\ServerNavn\Share\folder"""
$Path = Read-Host -Prompt "Write the path here"
Write-host "Are you sure your input is correct and you've done everything you should?"
pause
Write-host "Just checking! Thanks for your input, that's all I need. I'll get on with it now!"

Write-host "WDS Install"
Install-WindowsFeature wds-deployment -includemanagementtools

Write-host "WDS initialization"
wdsutil /initialize-server/Verbose /Progress /standalone /remInst:"$Server\WDSInstall"

Write-host "Adding 64bit (will not add 32bit automatically) WDS boot Image"
Import-WdsBootImage -Path "$BootImage\x64\sources\boot.wim"

Write-host "Copying unattend"
Copy-Item -Path $unattend -Destination $server\WDSInstall\WdsClientUnattend\unattend.xml
Write-host "WDS Config"
WDSUTIL /Set-Server /AnswerClients:All /DefaultX86X64ImageType:x64 
WDSUTIL /Set-Server /UseDhcpPorts:No /DhcpOption60:Yes /DhcpV6Option:Yes
WDSUTIL /Set-Server /PxePromptPolicy /Known:OptOut /New:OptOut
WDSUTIL /Set-Server /BootImage:boot.wim /Architecture:x64
WDSUTIL /Set-Server /PendingDevicePolicy /Policy:Disabled
WDSUTIL /Set-Server /NewMachineDomainJoin:No  
WDSUTIL /Set-Server /WdsUnattend /Policy:Enabled /File:unattend.xml /Architecture:x64 /CommandlinePrecedence:Yes
WDSUTIL /Set-Server /transport /MulticastSessionPolicy /policy:Multistream /StreamCount:2 /Fallback:Yes

Write-host "IP config"
set-netipaddress -InterfaceAlias "Ethernet" -DHCP Disabled
New-NetIPAddress -IPAddress 10.0.0.2 -InterfaceAlias "Ethernet" -DefaultGateway 10.0.0.1 -AddressFamily IPv4 -PrefixLength 24

Write-host "DHCP install"
Install-WindowsFeature DHCP -IncludeManagementTools
netsh dhcp add securitygroups
Restart-service dhcpserver
Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2

Write-host "DHCP Config"
Add-DhcpServerv4Scope -name "WDSServerRange" -StartRange 10.0.0.1 -EndRange 10.0.0.254 -SubnetMask 255.255.255.0 -State Active
Add-DhcpServerv4ExclusionRange -ScopeID 10.0.0.0 -StartRange 10.0.0.1 -EndRange 10.0.0.15
Set-DhcpServerv4OptionValue -OptionID 3 -Value 10.0.0.1 -ScopeID 10.0.0.0 -ComputerName WDS-Server

Write-host "DNS install"
Install-WindowsFeature Dns -IncludeManagementTools
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.0.0.2
Set-DhcpServerv4OptionValue -DnsServer 10.0.0.2

Write-host "WDS install Image Group adding"
New-WdsInstallImageGroup -Name "Desktops"
New-WdsInstallImageGroup -Name "Servers"
write-Warning "THINGS TO DO NOW
Dismount ISO
Add install images as required
Reveiw command ouput for errors
Check that the server int completed
Check WDS config
Add image unattend files
Check DHCP config
Check IP config
Disconnect server from the internet
Edit WDS unattend if required
Test deployment"
pause
pause