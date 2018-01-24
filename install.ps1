param(
    [string]$workingDir=$PWD,
    [switch]$keepCred
)
$ErrorActionPreference = "Stop"
#check if we running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    throw "Please run this with as administrator"
}

function Set-HookData($hookLines, $hookData) {
    for($i=0; $i -lt $hookLines.Count; $i+=6){
        if (($hookLines[$i] -eq $hookData.type) -and ($hookLines[$i+1] -eq $hookData.path)){
            break;
        }
    }
    if ($i -ge $hookLines.Count){
        $hookLines.AddRange(@($hookData.type, $hookData.path, $hookData.cmd, $hookData.wait, $hookData.display, $hookData.run))
    }else{
        $hookLines[$i] = $hookData.type
        $hookLines[$i+1] = $hookData.path
        $hookLines[$i+2] = $hookData.cmd
        $hookLines[$i+3] = $hookData.wait
        $hookLines[$i+4] = $hookData.display
        $hookLines[$i+5] = $hookData.run
    }
}

$tmpDir=$PWD
Set-Location $PSScriptRoot
try{
    #unblock all the scripts
    Unblock-File *.ps1
    #normalize wc dir
    $workingDir = Join-Path -Path $workingDir  ""
    #get the working copy dir
    $svnInfoXml = svn info $workingDir --xml
    if ($LASTEXITCODE -eq 0){
        $svnRootDir = [string]::Join("", $svnInfoXml) | Select-Xml -XPath "//wcroot-abspath/text()" | ForEach-Object {$_.Node.Value}
    }
    if (-not $svnRootDir){
        $err = "$workingDir is not an SVN working directory. Please specify the working directory using -workingDir"
        throw $err
    }
    #get the credentials
    $credIsValid = $false;
    $credExists = Test-Path -path "jira.cred"
    if ((-not $credExists) -or (-not $keepCred)){
        do{
            $cred = Get-Credential -Message "Please enter your JIRA credentials"
            if (-not $cred){
                exit 1;
            }
            $cred | Export-Clixml -Path "jira.cred";
            try{
                .\jira-cli.ps1 -action "getMyProfile" | Out-Null
                $credIsValid = $true
            }catch [System.Net.WebException]{
                $credIsValid = $false
                Remove-Item "jira.cred"
                if (-not ($_.Exception.Message -match "\b401\b")){
                    throw $_
                }
            }
        }while(-not $credIsValid )
    }
    #get the hooks for the dir
    $hooksText =  (Get-Item -Path Registry::HKEY_CURRENT_USER\Software\TortoiseSVN).GetValue("hooks")
    #replace the hooks
    $hookLines = [System.Collections.ArrayList]($hooksText.Trim().Split("`n"));
    if ((-not ($hooksText -eq "")) -and (($hookLines.Count % 6) -ne 0)){
        throw "Unexpected error configuring Tortoise SVN hooks. Please configure them manually"
    }
    Set-HookData $hookLines `
        @{
            type="pre_commit_hook";
            path=$workingDir;
            cmd="$PSHOME\powershell.exe -ExecutionPolicy Unrestricted -NonInteractive -File `"$PWD\pre-commit-hook.ps1`"";
            wait="true";
            display="hide";
            run="enforce"
        }

    Set-HookData $hookLines `
        @{
            type="post_commit_hook";
            path=$workingDir;
            cmd="$PSHOME\powershell.exe -ExecutionPolicy Unrestricted -NonInteractive -File `"$PWD\post-commit-hook.ps1`"";
            wait="true";
            display="hide";
            run="enforce"
        }
    
    $hooksText = [System.String]::Join("`n", $hookLines.ToArray()) + "`n"
    #store the hooks
    Set-ItemProperty -Path Registry::HKEY_CURRENT_USER\Software\TortoiseSVN -Name "hooks" -Value $hooksText
    Write-Output "Done!"
}finally{
    Set-Location $tmpDir
}