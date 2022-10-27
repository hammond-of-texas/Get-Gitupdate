<# 
.SYNOPSIS
    A script to deploy new commits on a self hosted server.

.DESCRIPTION 
    This script checks if new commits were made in a private git hub repositry. If this is the case,
    the new version is downloaded and replaces the old one on the server.

    In order to work properly, an API key has to be requested and the parameters adjusted.

.NOTES 
    2022, Fabian Kupferschmid
#>


$token = "YOUR_GITHUB_TOKEN"
$CommitPath = "c:\commits"
$DestinationDir = "C:\inetpub\wwwroot\"
$User = "hammond-of-texas"
$Appname = "webapp"

# If following switch is true, everything works normal, but nothing is removed or copied.
$Safe = $false


New-Item -ItemType Directory -path $CommitPath -Force | Out-Null
New-Item -ItemType Directory -path "$CommitPath\packages" -Force | Out-Null

try {
    $commitfile = (Get-Content -Path "$CommitPath\commits.txt" -ErrorAction SilentlyContinue)
} catch {
    New-Item -ItemType File -Path "$CommitPath\commits.txt"
    Write-host "Empty commit file created."
}

Write-Host "Getting commit history..."
$x = (Invoke-Webrequest -Uri "https://api.github.com/repos/$User/$Appname/commits" -Headers @{'Authorization'='token '+$token; 'Accept'='application/vnd.github+json'}) | ConvertFrom-Json
$latestcommit = $x[0].commit.url

Write-host "Checking if commit is allready known..."
$IsNew = $true
if ($null -ne $commitfile) { 
    foreach ($line in $commitfile) {

        if ($line -eq $latestcommit) {$isNew = $false; break}
    }
} 

if ($isNew) {
    Write-Output "Commit is new"
    Add-Content -Path "$CommitPath\commits.txt" -Value $latestcommit
    Remove-Item "$CommitPath\packages\main.zip" -Force -ErrorAction SilentlyContinue
    Write-Output "Downloading latest version."
    Invoke-Webrequest -Uri "https://api.github.com/repos/$User/$Appname/zipball/" -Headers @{'Authorization'='token '+$token; 'Accept'='application/vnd.github+json'} -OutFile "$CommitPath\packages\main.zip"
    Write-Output "Download complete."
    Expand-Archive -Path "$CommitPath\packages\main.zip" -DestinationPath "$CommitPath\packages\"
    $idArray = $latestcommit.Split("/")
    $id=$idArray[-1]
    Write-Output "ID; $id"
    Write-Output "Removeing old directory..."
    if ($Safe -eq $false) {
        Remove-Item -Path "$DestinationDir" -Recurse -Force
    } else {
        Write-Host "Safe mode is on, so here the directory would be removed."
    }
    Write-Output "Copying new deployment..."
    if ($safe -eq $false) {
        Write-host "Copying files..."
        Copy-Item -Path "$CommitPath\packages\$User-$Appname-$id" -Destination "$DestinationDir" -Recurse -Force
    } else {
        write-host "Safe mode is on, here the new files would be copied."
    }
    Write-Output "Deployment finished."

} else {
    Write-Output "Commit is known."
}
