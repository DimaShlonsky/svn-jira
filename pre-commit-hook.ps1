param(
    [string]$pathsFile,
    [int]$depth,
    [string]$messageFile,
    [string]$workingDir
)
$command = "`"${PSScriptRoot}\commit-hook.ps1`" -phase pre -pathsFile $pathsFile -depth $depth -messageFile $messageFile -workingDir $workingDir";
Invoke-Expression "& $command "