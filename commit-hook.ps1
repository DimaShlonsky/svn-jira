param(
    [ValidateSet('pre','post')]
    [string]$phase,
    [string]$pathsFile,
    [int]$depth,
    [string]$messageFile,
    [int]$revisionNumber,
    [string]$errorFile,
    [string]$workingDir
)
function TransitionPath($transitionIds, $issue) { #TransitionIds must be arranged in sequential order and form a path from intial state to the target state
    $transitionIds = [System.Collections.ArrayList]$transitionIds
    Write-Debug "Applying transitions"
    do{
        $transitions = (.\jira-cli.ps1 -action getTransitionList -issue $issue).transitions
        Write-Debug "Available transitions are: $transitions"
        $tmpLen = $transitionIds.Count
        foreach($tid in $transitionIds){
            $t = $transitions | Where-Object {$_.id -eq $tid}
            if ($t){
                Write-Debug "applying transition $tid for issue $issue"
                .\jira-cli.ps1 -action transitionIssue -issue $issue -transition $tid
                $transitionIds.RemoveRange(0, $transitionIds.IndexOf($tid)+1)
                break
            }
        }
        if($transitionIds.Count -eq $tmpLen){
            break;
        }
    }while($transitionIds.Count -gt 0)
}

$cmdRegex = "^/(?<cmd>\w+\b)\s*(?<id>[A-Z]{2,5}-\d+)?\s*$"

if ($phase -eq "pre"){
    Write-Debug "Executing 'pre' process"
    Copy-Item -Path $messageFile -Destination "${env:TEMP}\jr-svn.tmp" -Force
    $msg = Get-Content $messageFile;
    $msg = $msg -replace $cmdRegex,""
    $msg = [String]::Join("`n", $msg).Trim()
    $msg | Out-File $messageFile -Encoding utf8
    return
}
if ($phase -ne "post"){
    throw "Unrecognized phase parameter";
}
Write-Debug "Executing 'post' process"
$origWd = $pwd
try{
    $errText = Get-Content $errorFile
    if ($errText){
        Write-Debug "Exiting because there is something in the error file: $errText"
        return
    }
    Set-Location $PSScriptRoot
    #$issueIdRegex = "(?<id>[A-Z]{2,5}-\d+)"
    $svnInfoXml = svn info $workingDir --xml
    if ($LASTEXITCODE -ne 0){
        Write-Error "Error getting svn info for '$workingDir'"
        exit 1;
    }
    $svnRootDir = [string]::Join("", $svnInfoXml) | Select-Xml -XPath "//wcroot-abspath/text()" | ForEach-Object {$_.Node.Value}
    if (svn proplist -q $svnRootDir | Select-String "bugtraq:url"){
        $bugUrl = svn propget bugtraq:url $svnRootDir
    }else{
        Write-Debug "Setting BugUrl from default"
        $bugUrl = "https://seatgeekenterprise.atlassian.net/browse/%BUGID%"
    }
    Write-Debug "BugUrl is $bugUrl"

    if (svn proplist -q $svnRootDir | Select-String "bugtraq:logregex"){
        $svnLogRegexes = svn propget bugtraq:logregex $svnRootDir
        if ($svnLogRegexes.Length -ge 1){
            $regexPattern = $svnLogRegexes[0]
            $regexBugIdPattern = $svnLogRegexes[1]
        }
    }
    if ($LASTEXITCODE -ne 0){
        Write-Error "Error getting svn props for '$svnRootDir'"
        exit 1;
    }
    if (-not $regexPattern){
        Write-Debug "Setting regexPattern from default"
        $regexPattern = "((\s*((R|r)esolve(d|s)|(F|f)ixe(d|s))\s+)?([A-Z]{2,5}-\d{2,}))|\(([A-Z]{2,5}-\d{2,})\)"
    }
    Write-Debug "regexPattern in $regexPattern"
    if (-not $regexBugIdPattern){
        $regexBugIdPattern = "([A-Z]{2,5}-\d{2,})"
        Write-Debug "Setting regexBugIdPattern pattern from default"
    }
    Write-Debug "regexBugIdPattern in $regexBugIdPattern"

    $msg = Get-Content "${env:TEMP}\jr-svn.tmp";
    Write-Debug "msg is $msg"
    $cmdMatches = $msg | Select-String -Pattern $cmdRegex  -AllMatches | ForEach-Object {$_.Matches}

    $msg = $msg -replace $cmdRegex,""
    $msg = [String]::Join("`n", $msg).Trim()
    Write-Debug "final msg is $msg"

    $match = $msg | Select-String -Pattern $regexPattern -AllMatches | ForEach-Object {$_.Matches.Value}
    [System.Collections.ArrayList]$mentionedIssues = @($match | Select-String -Pattern $regexBugIdPattern -AllMatches | ForEach-Object {$_.Matches.Value})
    $mentionedIssues = @($mentionedIssues | Sort-Object | Get-Unique)

    foreach($match in $cmdMatches){
        $cmd = $match.Groups["cmd"].Value
        $cmd = $cmd.ToLower();
        $issue = $match.Groups["id"].Value
        if (-not $issue){
            if ($mentionedIssues.Count -eq 1){
                $issue = $mentionedIssues[0]
            }
        }else{
            $mentionedIssues.Add($issue)
            $mentionedIssues = @($mentionedIssues | Sort-Object | Get-Unique)
        }
        Write-Debug "processing command '$cmd' for issue $issue"
        switch -Regex ($cmd) {
            "view"{
                if (-not $issue){
                    throw "missing issue number"
                }
                $url = ${bugUrl} -replace "%BUGID%", $issue
                Start-Process -FilePath $url
                break
            }
            "fixe(s|d)"{
                if (-not $issue){
                    throw "missing issue number"
                }
                TransitionPath -transitionIds @(11,101,21) -issue $issue
            }
            default
            {
                throw "Unrecognized /command"
            }
        }
    }

    $mentionedIssues = @($mentionedIssues | Sort-Object | Get-Unique)
    foreach($mentionedIssue in $mentionedIssues){
        $commentText = "This issue is mentioned in commit ${revisionNumber}:`n{quote}${msg}{quote}"
        Write-Debug "processing comment '$commentText' for bug $mentionedIssue"
        .\jira-cli.ps1 -action addComment -issue $mentionedIssue -comment $commentText
    }
}finally{
    Set-Location $origWd
    Remove-Item "${env:TEMP}\jr-svn.tmp" -Force
}
