#!/usr/bin/env bash
# auto-pull.sh
# Verifica si hay cambios remotos en TODOS los repos de ~/source/ y los trae automáticamente.
# Para synapse-skills, además regenera las reglas .mdc para Cursor 2.5.
#
# Instalado como systemd --user timer (cada 10 minutos).
set -euo pipefail

SOURCE_DIR="$HOME/source"
LOG_FILE="/tmp/synapse-autopull.log"
NOW="[$(date '+%Y-%m-%d %H:%M:%S')]"

# Repos a ignorar (no son de DarioLubisco o no tienen remote)
IGNORE_REPOS=(
    "plane"
)

sync_repo() {
    local repo_dir="$1"
    local repo_name="$2"
    
    cd "$repo_dir" || return 0
    
    # Solo si tiene remote 'origin' en GitHub
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    [[ "$remote_url" != *"github.com"* ]] && return 0
    
    # Fetch silencioso
    git fetch origin 2>/dev/null || return 0
    
    # Verificar si hay cambios
    local local_ref remote_ref
    local_ref=$(git rev-parse @ 2>/dev/null || echo "")
    remote_ref=$(git rev-parse @{u} 2>/dev/null || echo "")
    
    [[ -z "$remote_ref" ]] && return 0
    [[ "$local_ref" = "$remote_ref" ]] && return 0
    
    # Hay cambios — hacer pull
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    
    echo "$NOW 🔄 $repo_name: cambios detectados → pull en $branch"
    
    if git pull --ff-only origin "$branch" 2>&1; then
        echo "$NOW ✅ $repo_name: pull exitoso"
        
        # Para synapse-skills: sync a Cursor 2.5
        if [ "$repo_name" = "synapse-skills" ] && [ -x "$repo_dir/scripts/sync-to-cursor.sh" ]; then
            "$repo_dir/scripts/sync-to-cursor.sh" 2>&1
            echo "$NOW ✅ Cursor rules actualizadas"
        fi
    else
        echo "$NOW ❌ $repo_name: pull falló (conflictos?)"
    fi
}

# Escanear todos los repos en ~/source/
echo "$NOW === Auto-Pull: Synapse OS Repos ==="

for git_dir in $(find "$SOURCE_DIR" -name ".git" -maxdepth 4 -type d 2>/dev/null | sort); do
    repo_dir="$(dirname "$git_dir")"
    repo_name="$(basename "$repo_dir")"
    
    # Saltar ignorados
    for ignore in "${IGNORE_REPOS[@]}"; do
        [[ "$repo_name" == "$ignore" ]] && continue 2
    done
    
    sync_repo "$repo_dir" "$repo_name"
done

echo "$NOW === Auto-Pull completo ==="
