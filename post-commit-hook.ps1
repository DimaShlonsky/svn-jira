param(
    [string]$pathsFile,
    [int]$depth,
    [string]$messageFile,
    [int]$revisionNumber,
    [string]$errorFile,
    [string]$workingDir
)

#$issueIdRegex = "(?<id>[A-Z]{2,5}-\d+)"
$bugUrl = "https://seatgeekenterprise.atlassian.net/browse/"
$msg = Get-Content $pathsFile;
$matches = $msg | Select-String -Pattern "^/(?<cmd>\w+\b)\s*(?<id>[A-Z]{2,5}-\d+)?\s*$" -AllMatches | ForEach-Object {$_.Matches}
foreach($match in $matches){
    $cmd = $match.Groups["cmd"].Value
    $cmd = $cmd.ToLower();
    $bugId = $match.Groups["id"].Value
    if ($cmd.StartsWith("view")){
        if (-not $bugId){
            throw "/view without id is illegal"
        }
        Start-Process -FilePath "${bugUrl}${bugId}"
    }elseif($cmd.StartsWith("fixes")){
        
    }
}