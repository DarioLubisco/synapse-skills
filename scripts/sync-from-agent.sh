#!/usr/bin/env bash
# sync-from-agent.sh
# Copia el skill handoff desde ~/.agents/skills/ al repo synapse-skills
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGENT_SKILLS_DIR="$HOME/.agents/skills"
HANDOFF_SRC="$AGENT_SKILLS_DIR/mattpocock-skills/skills/productivity/handoff/SKILL.md"
HANDOFF_DST="$REPO_DIR/handoff/SKILL.md"

echo "=== Synapse Skills: sync-from-agent ==="

# Verificar que existe el fuente
if [ ! -f "$HANDOFF_SRC" ]; then
    echo "❌ No se encuentra: $HANDOFF_SRC"
    exit 1
fi

# Copiar handoff
cp "$HANDOFF_SRC" "$HANDOFF_DST"
echo "✅ handoff/SKILL.md copiado desde agente"

# Detectar cambios
if git -C "$REPO_DIR" diff --quiet 2>/dev/null; then
    echo "ℹ️  Sin cambios nuevos"
else
    echo "📝 Cambios detectados. Haz commit:"
    echo "   cd $REPO_DIR && git add -A && git commit -m \"sync: actualizar handoff desde agente\""
fi
