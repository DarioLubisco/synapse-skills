#!/usr/bin/env bash
# install-unified-hooks.sh
# Configura un repo para usar los hooks unificados de .synapse/hooks/
# Uso: bash install-unified-hooks.sh /ruta/al/repo
set -euo pipefail

TARGET_REPO="${1:-}"
HOOKS_SOURCE="/home/synapse/source/.synapse/hooks"

if [ -z "$TARGET_REPO" ]; then
    echo "Uso: bash install-unified-hooks.sh /ruta/al/repo"
    exit 1
fi

if [ ! -d "$TARGET_REPO/.git" ]; then
    echo "❌ No es un repo git: $TARGET_REPO"
    exit 1
fi

REPO_NAME="$(basename "$(cd "$TARGET_REPO" && git rev-parse --show-toplevel)")"

git -C "$TARGET_REPO" config core.hookspath "$HOOKS_SOURCE"
echo "✅ $REPO_NAME → hooks unificados ($HOOKS_SOURCE)"
