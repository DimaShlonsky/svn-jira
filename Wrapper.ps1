$args | Out-File -FilePath $PSScriptRoot\log.txt -Append
Set-PSDebug -Trace 2
&"${PSScriptRoot}post-commit-hook.ps1 -messageFile $args[2] -revisionNumber $args[3] -workingDir $args[5] | Out-File -FilePath $PSScriptRoot\log.txt -Append"