# WindowsDeploymentScripts
Recently rediscovered my personal collection of Windows deployment scripts, unattend files and other related stuff. Quite frankly not 
that good, but the documentation on these topics isn't great, so I figure some people might find it useful Please be warned that 
development on these stopped quickly a while ago, as I moved into a Linux environment, so no promises on function or form. They're more 
useful as a starting point than anything else.

These were developed with an unusual use case in mind - re-imaging refurbished PCs via WDS, but could be repurposed for more general 
systems administration functions. Most were used on Windows Server 2016.

# Contents
## HTML Spec Sheets
Scripts for generating HTML spec sheets. These and the unattend files are by far the best here In four flavours, VBS, batch, PowerShell
and PowerShell with speech. These are all more or less functional. I find that the VBS script was the best choice for running as part 
of an unattend file (I include it and the unattend within the .wim image at the root of the drive). The PowerShell ones would never run
properly in that scenario and the batch isn't very pretty. The VBS is built to require some attention on launch, but that code can 
easily be cut out. 

## Unattend Files
Contains some unattend files. First stage install is specifically for use with WDS for the boot image stage. Second stage install ones 
can be used for both WDS second stage and a USB install out of the box (just rename to ).

## USB Install
Contains a massive batch file used as part of a Windows PE image to offer a menu on start up. Not all of the functions are implemented.

## WDS Server 
Contains a couple of scripts loosely related to deployment of WDS servers, including one that does most of the work for a non-domain joined one