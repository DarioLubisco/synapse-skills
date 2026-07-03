# install-hooks.ps1
# Instala git hooks + referencia para Cursor user hook (sessionStart auto-pull)
$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $PSScriptRoot
$GitHooksDir = Join-Path $RepoDir ".git\hooks"
$CursorHooksDir = Join-Path $env:USERPROFILE ".cursor\hooks"
$CursorHooksJson = Join-Path $env:USERPROFILE ".cursor\hooks.json"

New-Item -ItemType Directory -Path $GitHooksDir -Force | Out-Null
New-Item -ItemType Directory -Path $CursorHooksDir -Force | Out-Null

# --- Git post-merge: pull remoto ya ocurrio; solo sync local ---
$postMerge = @'
#!/bin/sh
# synapse-skills post-merge — sync a Cursor tras pull/merge
REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PULL_SYNC="$REPO_DIR/scripts/pull-and-sync.ps1"

if [ -f "$PULL_SYNC" ]; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PULL_SYNC" -ForceSync 2>/dev/null \
    || pwsh -NoProfile -ExecutionPolicy Bypass -File "$PULL_SYNC" -ForceSync 2>/dev/null \
    || true
fi
exit 0
'@

$postMergePath = Join-Path $GitHooksDir "post-merge"
Set-Content -Path $postMergePath -Value $postMerge -Encoding UTF8 -NoNewline

# --- Cursor sessionStart hook launcher ---
$cursorHookScript = @'
# synapse-skills-pull.ps1 — Cursor user hook (sessionStart)
$repo = Join-Path $env:USERPROFILE "synapse-skills"
$script = Join-Path $repo "scripts\pull-and-sync.ps1"

if (-not (Test-Path $script)) {
    exit 0
}

try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script
} catch {
    # fail open: no bloquear la sesion de Cursor
}
exit 0
'@

$cursorHookPath = Join-Path $CursorHooksDir "synapse-skills-pull.ps1"
Set-Content -Path $cursorHookPath -Value $cursorHookScript -Encoding UTF8

# --- Merge hooks.json ---
$hookEntry = @{
    command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$cursorHookPath`""
}

$hooksConfig = @{ version = 1; hooks = @{ sessionStart = @($hookEntry) } }

if (Test-Path $CursorHooksJson) {
    $existing = Get-Content $CursorHooksJson -Raw | ConvertFrom-Json
    if (-not $existing.hooks) {
        $existing | Add-Member -NotePropertyName hooks -NotePropertyValue (@{})
    }
    if (-not $existing.hooks.sessionStart) {
        $existing.hooks | Add-Member -NotePropertyName sessionStart -NotePropertyValue @()
    }

    $already = $false
    foreach ($h in $existing.hooks.sessionStart) {
        if ($h.command -like "*synapse-skills-pull*") { $already = $true; break }
    }
    if (-not $already) {
        $existing.hooks.sessionStart += $hookEntry
    }
    $existing | ConvertTo-Json -Depth 6 | Set-Content $CursorHooksJson -Encoding UTF8
} else {
    $hooksConfig | ConvertTo-Json -Depth 6 | Set-Content $CursorHooksJson -Encoding UTF8
}

Write-Host "Git hook instalado:  $postMergePath"
Write-Host "Cursor hook:         $cursorHookPath"
Write-Host "Cursor hooks.json:   $CursorHooksJson"
Write-Host ""
Write-Host "Listo. Al abrir Cursor (sessionStart) se hara fetch+pull si hay cambios en GitHub."
