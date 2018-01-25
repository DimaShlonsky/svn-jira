powershell.exe -ExecutionPolicy Unrestricted -File "%~dp0\commit-hook.ps1" -phase post -pathsFile "%1" -depth %2 -messageFile "%3" -workingDir "%4" -Debug >con 2>&1
pause < con > con