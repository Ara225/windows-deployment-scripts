cd "%~dp0"
psexec -i -s powershell -ExecutionPolicy Bypass -Command "cd %~dp0; .\WindowsImageGenerator.ps1; pause"
pause