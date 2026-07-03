#!/usr/bin/env bash
# auto-pull.sh
# Verifica si hay cambios remotos en GitHub y los trae automáticamente.
# Ideal para ejecutar via cron (cada 5-10 minutos).
# 
# Uso en crontab (cada 10 minutos):
#   */10 * * * * /home/synapse/source/synapse-skills/scripts/auto-pull.sh >> /tmp/synapse-skills-autopull.log 2>&1
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="/tmp/synapse-skills-autopull.log"

# No loguear si no hay cambios (silencioso)
cd "$REPO_DIR"

# Fetch sin merge para ver si hay cambios
git fetch origin 2>/dev/null || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  git fetch falló (sin conexión?)"
    exit 0
}

# Comparar con remote
LOCAL=$(git rev-parse @ 2>/dev/null || echo "")
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

if [ -z "$REMOTE" ]; then
    # No hay upstream configurado
    exit 0
fi

if [ "$LOCAL" = "$REMOTE" ]; then
    # Está al día, silencioso
    exit 0
fi

# Hay cambios remotos — hacer pull
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Cambios detectados en GitHub. Pullando..."

if git pull --ff-only origin main 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Pull exitoso"
    
    # Sync a Cursor 2.5
    if [ -x "$REPO_DIR/scripts/sync-to-cursor.sh" ]; then
        "$REPO_DIR/scripts/sync-to-cursor.sh" 2>&1
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Cursor rules actualizadas"
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Pull falló (conflictos?)"
fi
