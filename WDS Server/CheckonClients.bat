@echo OFF
:start
set /P Answer=Check on multicast clients (y/n)?
if Answer==y goto PS
if Answer==n goto EOF
:PS
PowerShell -Command "& {Get-WdsMulticastClient}"
goto Start