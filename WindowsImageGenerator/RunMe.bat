set drive=%~dp0
%drive:~0,2%
cd "%~dp0"
psexec -i -s powershell -ExecutionPolicy Bypass -Command "cd %~dp0; .\WindowsImageGenerator_GUI.ps1; pause"
pause