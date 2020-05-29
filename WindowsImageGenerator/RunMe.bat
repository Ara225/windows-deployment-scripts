@echo off
set drive=%~dp0
%drive:~0,2%
cd "%~dp0"
psexec -i -s powershell -ExecutionPolicy Bypass -Command "cd %~dp0; .\WindowsImageGenerator_GUI.ps1; get-job; Receive-Job 1; pause"
if %errorLevel% NEQ 0 (
    color 04
    echo.
    echo.
    echo "Failure: This script needs to be run as Administrator (right click it and select Run as Administrator)"
    pause
    exit
)
pause
