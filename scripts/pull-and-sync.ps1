# pull-and-sync.ps1
# Fetch + pull (ff-only) si hay cambios en origin/main, luego sync a ~/.cursor/
param(
    [switch]$ForceSync
)

$ErrorActionPreference = "Stop"
$RepoDir = Split-Path -Parent $PSScriptRoot

$CursorRulesDir = Join-Path $env:USERPROFILE ".cursor\rules"
$CursorSkillsDir = Join-Path $env:USERPROFILE ".cursor\skills"
$RepoCursorDir = Join-Path $RepoDir "cursor-rules"
$HandoffSrc = Join-Path $RepoDir "handoff"
$LogFile = Join-Path $env:TEMP "synapse-skills-pull.log"

function Write-Log($Message) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

function Sync-CursorRules {
    if (-not (Test-Path $RepoCursorDir)) {
        Write-Log "WARN: cursor-rules no encontrado en $RepoCursorDir"
        return 0
    }

    New-Item -ItemType Directory -Path $CursorRulesDir -Force | Out-Null
    New-Item -ItemType Directory -Path $CursorSkillsDir -Force | Out-Null

    $mdcFiles = Get-ChildItem $RepoCursorDir -Filter "*.mdc" -ErrorAction SilentlyContinue
    foreach ($f in $mdcFiles) {
        Copy-Item $f.FullName -Destination (Join-Path $CursorRulesDir $f.Name) -Force
    }

    if (Test-Path "$HandoffSrc\SKILL.md") {
        $handoffDst = Join-Path $CursorSkillsDir "handoff"
        New-Item -ItemType Directory -Path $handoffDst -Force | Out-Null
        Copy-Item "$HandoffSrc\*" -Destination $handoffDst -Recurse -Force
    }

    return @($mdcFiles).Count
}

Push-Location $RepoDir
try {
    Write-Log "Inicio pull-and-sync en $RepoDir"

    git fetch origin 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WARN: git fetch fallo (sin red?)"
        if ($ForceSync) {
            $count = Sync-CursorRules
            Write-Log "Sync forzado: $count reglas"
        }
        exit 0
    }

    $local = (git rev-parse HEAD 2>$null).Trim()
    $remote = (git rev-parse origin/main 2>$null).Trim()

    if (-not $remote) {
        Write-Log "WARN: origin/main no configurado"
        exit 0
    }

    if ($local -eq $remote) {
        Write-Log "Al dia ($local)"
        if ($ForceSync) {
            $count = Sync-CursorRules
            Write-Log "Sync forzado: $count reglas"
        }
        exit 0
    }

    Write-Log "Cambios remotos detectados: $local -> $remote"
    git pull --ff-only origin main 2>&1 | ForEach-Object { Write-Log $_ }

    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERROR: git pull fallo"
        exit 1
    }

    $count = Sync-CursorRules
    Write-Log "Pull OK + $count reglas sincronizadas a $CursorRulesDir"
    Write-Host "synapse-skills: pull OK, $count reglas Cursor actualizadas"
}
finally {
    Pop-Location
}
