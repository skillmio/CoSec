
<#
🔐 Required PAT permissions (classic token)
When creating token in GitHub:

✔ repo
✔ read:org

That’s enough for private + public repos.

#>

# ===== CONFIG =====
$User     = "skillmio"
$Token    = "ghp_xxxxxxxxxxxxxxxxx"
$RootPath = "C:\MyDrive\Projects\Skillmio\GitHubBackup"

# ===== TIMESTAMP =====
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$BackupDir = Join-Path $RootPath $timestamp
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# ===== HEADERS =====
$Headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "Skillmio-Backup"
}

# ===== GET ALL USER REPOS (incl private) =====
$page = 1
$repos = @()

while ($true) {

    $url = "https://api.github.com/user/repos?per_page=100&page=$page"

    $result = Invoke-RestMethod -Uri $url -Headers $Headers

    if (!$result -or $result.Count -eq 0) { break }

    # keep only repos owned by skillmio (not collaborators)
    $repos += $result | Where-Object { $_.owner.login -eq $User }

    $page++
}

Write-Host "Found $($repos.Count) repos"

# ===== DOWNLOAD =====
foreach ($repo in $repos) {

    $name = $repo.name
    $zipUrl = "https://api.github.com/repos/$User/$name/zipball"
    $outFile = Join-Path $BackupDir "$name.zip"

    Write-Host "Downloading $name"
    Invoke-WebRequest -Uri $zipUrl -Headers $Headers -OutFile $outFile
}

Write-Host "Backup completed to $BackupDir"
