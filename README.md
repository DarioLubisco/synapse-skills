# Synapse OS — Auto-Sync Unificado

Repositorio central de skills + sistema de sincronización automática para todos los repos de Synapse OS.

## Contenido

| Ruta | Descripción |
|------|-------------|
| `handoff/` | Skill de traspaso estructurado (Matt Pocock) |
| `cursor-rules/` | 169 reglas `.mdc` para Cursor 2.5 |
| `scripts/` | Utilidades de sync: `sync-to-cursor.sh`, `sync-from-agent.sh`, `auto-pull.sh` |

## Arquitectura de hooks (unificada)

**Todos los repos** de `~/source/` usan un solo directorio de hooks: **`~/.synapse/hooks/`**

```
~/source/.synapse/hooks/
  ├── post-checkout   → Notion: TASK-XXX → "In Progress"
  ├── post-merge      → Notion (TASK IDs) + Cursor (synapse-skills)
  └── post-commit     → Push a GitHub     + Cursor (synapse-skills)
```

### Repos sincronizados automáticamente

| Repo | GitHub | post-commit push | auto-pull |
|------|--------|:---:|:---:|
| `synapse-skills` | DarioLubisco/synapse-skills | ✅ + Cursor sync | ✅ |
| `HERMES` | DarioLubisco/HERMES | ✅ | ✅ |
| `Utilidades` | DarioLubisco/Utilidades | ✅ | ✅ |
| `kanban Tasks` | DarioLubisco/kanban-Tasks | ✅ | ✅ |
| `N8N` | DarioLubisco/N8N | ✅ | ✅ |
| `.synapse` | DarioLubisco/.synapse | ✅ | ✅ |
| `APPSHEET` | DarioLubisco/APPSHEET | ✅ | ✅ |
| `Clasificacion Medicamentos` | DarioLubisco/Clasificacion-Medicamentos | ✅ | ✅ |

## Ciclo de sincronización

```
Commit local
    │
    ▼
post-commit hook  ───> Push a GitHub (todos los repos)
    │                  └── Cursor .mdc (solo synapse-skills)
    ▼
auto-pull (cada 10min) ───> git pull (todos los repos)
    │                        └── Cursor .mdc (solo synapse-skills)
    ▼
post-merge hook ───> Notion TASK sync (todos los repos)
                    └── Cursor .mdc (solo synapse-skills)
```

## Cómo usar

```bash
# Traer cambios de skills desde agente
cd ~/source/synapse-skills
bash scripts/sync-from-agent.sh
git add -A && git commit -m "sync: actualizar handoff"

# Regenerar reglas Cursor manualmente
bash scripts/sync-to-cursor.sh

# Ver estado del auto-pull
systemctl --user status synapse-skills-pull.timer
```
