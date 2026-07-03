#!/usr/bin/env bash
# install-hooks.sh
# Configura el repo synapse-skills para usar sus propios git hooks
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$REPO_DIR/hooks"

echo "=== Instalando hooks para synapse-skills ==="

# Verificar que los hooks existan
if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ No se encuentra el directorio hooks/"
    exit 1
fi

# Hacer ejecutables los hooks
chmod +x "$HOOKS_DIR"/* 2>/dev/null || true

# Configurar git para usar estos hooks
git -C "$REPO_DIR" config core.hooksPath hooks/

echo "✅ Hooks instalados: core.hooksPath = hooks/"
echo ""
echo "Los siguientes hooks están activos:"
for hook in "$HOOKS_DIR"/*; do
    if [ -x "$hook" ]; then
        echo "   - $(basename "$hook")"
    fi
done
echo ""
echo "Listo. Los hooks se ejecutarán automáticamente en git."
