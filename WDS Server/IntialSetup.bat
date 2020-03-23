@echo OFF
set /P Answer=This will set the PS excution policy, rename the computer and restart. Do you want to continue?
if Answer==y goto startps
if Answer==n goto EOF
:startps
PowerShell -Command "& {Set-ExecutionPolicy RemoteSigned}"
PowerShell -Command "& {get-ExecutionPolicy}"
pause
PowerShell -Command "& {Rename-Computer WDS-Server}"
pause
PowerShell -Command "& {Restart-Computer}"
