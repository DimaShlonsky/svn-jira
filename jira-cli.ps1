param(
    [string]$action,
    [string]$issue,
    [string]$comment
)
$cred=$null;
try{
    $cred = Import-Clixml -Path "jira.cred"
}catch{}
if (-not $cred){
    $cred = Get-Credential -Message "Please enter your JIRA credentials"
    $cred | Export-Clixml -Path "jira.cred";
}
$user=$cred.UserName
$pass = $cred.GetNetworkCredential().Password
$pair = "${user}:${pass}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = @{ Authorization = $basicAuthValue; Accept = "application/json"; "Content-Type" = "application/json" }

$baseUrl = "https://seatgeekenterprise.atlassian.net/rest/api/2/"

if ($action -eq "getIssue"){
    Invoke-RestMethod -Uri "${baseUrl}/issue/${issue}/" -Credential $cred -Headers $headers 
}elseif($action -eq "addComment"){
    $req = @{body=$comment} | ConvertTo-Json
    Invoke-RestMethod -Uri "${baseUrl}/issue/${issue}/comment" -Method Post -Credential $cred -Headers $headers -Body $req -Proxy "http://localhost:8888"
}