param(
    [string]$pathsFile,
    [int]$depth,
    [string]$messageFile,
    [int]$revisionNumber,
    [string]$errorFile,
    [string]$workingDir
)
$ErrorActionPreference ="Stop"
$DebugPreference = "Continue"
$command = "`"${PSScriptRoot}\commit-hook.ps1`" -phase post -pathsFile $pathsFile -depth $depth -messageFile $messageFile -revisionNumber $revisionNumber -errorFile $errorFile  -workingDir $workingDir";
Invoke-Expression "& $command "