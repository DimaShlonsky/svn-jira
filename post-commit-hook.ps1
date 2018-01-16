param(
    [string]$pathsFile,
    [int]$depth,
    [string]$messageFile,
    [int]$revisionNumber,
    [string]$errorFile,
    [string]$workingDir
)

#$issueIdRegex = "(?<id>[A-Z]{2,5}-\d+)"
$svnInfoXml = svn info $workingDir --xml
$svnRootDir = [string]::Join("", $svnInfoXml) | Select-Xml -XPath "//wcroot-abspath/text()" | ForEach-Object {$_.Node.Value}
$bugUrl = svn propget bugtraq:url $svnRootDir
if (-not $bugUrl){
    $bugUrl = "https://seatgeekenterprise.atlassian.net/browse/%BUGID%"
}
$svnLogRegexes = svn propget bugtraq:logregex $svnRootDir
$regexPattern = $svnLogRegexes[0]
if (-not $regexPattern){
    $regexPattern = "((\s*((R|r)esolve(d|s)|(F|f)ixe(d|s))\s+)?([A-Z]{2,5}-\d{2,}))|\(([A-Z]{2,5}-\d{2,})\)"
}
$regexBugIdPattern = $svnLogRegexes[1]
if (-not $regexBugIdPattern){
    $regexPattern = "([A-Z]{2,5}-\d{2,})"
}
$cmdRegex = "^/(?<cmd>\w+\b)\s*(?<id>[A-Z]{2,5}-\d+)?\s*$"
$msg = Get-Content $messageFile;
$cmdMatches = $msg | Select-String -Pattern $cmdRegex  -AllMatches | ForEach-Object {$_.Matches}

$match = $msg | Select-String -Pattern $regexPattern | ForEach-Object {$_.Matches.Value}
$bugId = $match | Select-String -Pattern $regexBugIdPattern | ForEach-Object {$_.Matches.Value}

$msg = $msg -replace $cmdRegex,""
$msg | Out-File $messageFile

if ($bugId){
    $commentText = "This issue is mentioned in commit ${revisionNumber}:`n{quote}${msg}{quote}"
    .\jira-cli.ps1 -action addComment -issue $bugId -comment $commentText
}


foreach($match in $cmdMatches){
    $cmd = $match.Groups["cmd"].Value
    $cmd = $cmd.ToLower();
    $issue = $match.Groups["id"].Value
    if ($bugId -and (-not $issue)){$issue = $bugId}
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

function TransitionPath($transitionIds, $issue) { #TransitionIds must be arranged in sequential order and form a path from intial state to the target state
    $transitionIds = [System.Collections.ArrayList]$transitionIds
    do{
        $transitions = (.\jira-cli.ps1 -action getTransitionList -issue $issue).transitions
        $tmpLen = $transitionIds.Count
        foreach($tid in $transitionIds){
            $t = $transitions | Where-Object {$_.id -eq $tid}
            if ($t){
                .\jira-cli.ps1 -action transitionIssue -issue $issue -transition $tid
                $transitionIds.RemoveRange(0, $transitionIds.IndexOf($tid)+1)
                break
            }
        }
        if($transitionIds.Length -eq $tmpLen){
            break;
        }
    }while($transitionIds.Length -gt 0)
}