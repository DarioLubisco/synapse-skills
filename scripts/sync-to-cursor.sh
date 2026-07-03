#!/usr/bin/env bash
# sync-to-cursor.sh
# Convierte todos los SKILL.md de ~/.agents/skills/ a reglas .mdc para Cursor 2.5
# y las copia a ~/.cursor/rules/ (global) y cursor-rules/ en el repo.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGENT_SKILLS_DIR="$HOME/.agents/skills"
CURSOR_RULES_DIR="$HOME/.cursor/rules"
REPO_CURSOR_DIR="$REPO_DIR/cursor-rules"

# Skills que deben tener alwaysApply: true (conducta global / guardrails)
ALWAYS_APPLY_LIST=(
    "web-search-mcp-routing"
    "sql-safety-protocol"
    "assistente-rigoroso"
    "bash-pro"
    "code-tester"
    "git-guardrails"
)

echo "=== Synapse Skills: sync-to-cursor ==="

# Asegurar directorios
mkdir -p "$CURSOR_RULES_DIR" "$REPO_CURSOR_DIR"

cleanup_name() {
    # Convierte nombre de carpeta a nombre legible para .mdc
    local name="$1"
    echo "$name" | sed 's/_procesado_antigravity//g; s/_procesado_openrouter//g'
}

generate_mdc() {
    local skill_path="$1"
    local skill_name="$2"
    local clean_name
    clean_name="$(cleanup_name "$skill_name")"
    
    # Extraer frontmatter del SKILL.md
    local description
    description=$(sed -n '/^---$/,/^---$/p' "$skill_path" 2>/dev/null | grep -m1 'description:' | sed 's/description: *//' || echo "Skill $clean_name")
    
    # Determinar alwaysApply
    local always_apply="false"
    for a in "${ALWAYS_APPLY_LIST[@]}"; do
        if [[ "$skill_name" == "$a" ]] || [[ "$clean_name" == "$a" ]]; then
            always_apply="true"
            break
        fi
    done
    
    # Para skills de open-design, extraer subnombre si es anidado
    local mdc_name="$clean_name"
    local subfolder
    subfolder="$(basename "$(dirname "$skill_path")")"
    if [ "$subfolder" != "skills" ] && [ "$subfolder" != "." ]; then
        # Para skills dentro de colecciones (mattpocock, open-design)
        local parent_name
        parent_name="$(basename "$(dirname "$(dirname "$skill_path")")")"
        if [ "$parent_name" != "skills" ] && [ "$parent_name" != "$skill_name" ]; then
            mdc_name="${parent_name}-${clean_name}"
        fi
    fi
    
    local mdc_file="$CURSOR_RULES_DIR/${mdc_name}.mdc"
    
    # Extraer el body del SKILL.md (lo que está después del frontmatter)
    local body
    body=$(sed '1,/^---$/d' "$skill_path" 2>/dev/null || cat "$skill_path")
    
    # Generar .mdc
    cat > "$mdc_file" << EOFRULE
---
description: "${description}"
alwaysApply: ${always_apply}
---

# ${clean_name}

$(echo "$body" | head -c 8000)
EOFRULE
    
    echo "   ✓ ${mdc_name}.mdc (alwaysApply: ${always_apply})"
    
    # Copiar al repo también
    cp "$mdc_file" "$REPO_CURSOR_DIR/${mdc_name}.mdc"
}

count=0
# Buscar todos los SKILL.md recursivamente
while IFS= read -r skill_file; do
    # Obtener nombre base (la carpeta que contiene el skill)
    local_dir="$(dirname "$skill_file")"
    skill_name="$(basename "$local_dir")"
    
    # Saltar si es el mismo nombre que el padre (ej: nesting duplicado)
    parent_dir="$(basename "$(dirname "$local_dir")")"
    if [ "$parent_dir" = "$skill_name" ]; then
        # Es el caso de skills copiados con doble nesting, tomar el abuelo
        grandparent="$(basename "$(dirname "$(dirname "$local_dir")")")"
        if [ "$grandparent" != "skills" ]; then
            skill_name="${grandparent}-${skill_name}"
        fi
    fi
    
    # Limpiar duplicación de nombre en cursor-sync/antigravity-skills (omitir si está dentro de cursor-sync)
    if [[ "$skill_file" == *"cursor-sync"* ]]; then
        continue
    fi
    
    echo "📄 Procesando: $skill_name"
    generate_mdc "$skill_file" "$skill_name"
    count=$((count + 1))
done < <(find "$AGENT_SKILLS_DIR" -name "SKILL.md" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort)

echo ""
echo "✅ $count skills convertidos a .mdc"
echo "   → Global: $CURSOR_RULES_DIR/"
echo "   → Repo:   $REPO_CURSOR_DIR/"
