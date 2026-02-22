
<#
🔐 Required PAT permissions (classic token)
When creating token in GitHub:

✔ repo
✔ read:org

That’s enough for private + public repos.

#>


# ===== CONFIG =====
$Org        = "skillmio"
$Token      = "ghp_xxxxxxxxxxxxxxxxxxxxx"   # <-- your classic PAT
$BackupRoot = "C:\MyDrive\Projects\Skillmio"    # where repos will be stored

# ===== PREP =====
$Headers = @{
    Authorization = "token $Token"
    "User-Agent"  = "PowerShell-Backup"
}

if (!(Test-Path $BackupRoot)) {
    New-Item -ItemType Directory -Path $BackupRoot | Out-Null
}

# ===== GET ALL REPOS (pagination) =====
$page = 1
$repos = @()

do {
    $url = "https://api.github.com/orgs/$Org/repos?per_page=100&page=$page"
    $result = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get

    $repos += $result
    $page++
} while ($result.Count -gt 0)

Write-Host "Found $($repos.Count) repositories"

# ===== CLONE / UPDATE =====
foreach ($repo in $repos) {

    $name = $repo.name
    $cloneUrl = $repo.clone_url
    $localPath = Join-Path $BackupRoot $name

    if (Test-Path $localPath) {
        Write-Host "Updating $name"
        git -C $localPath pull --all --prune
    }
    else {
        Write-Host "Cloning $name"
        git clone $cloneUrl $localPath
    }
}

Write-Host "Backup completed."
