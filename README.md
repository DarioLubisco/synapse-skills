# Synapse Skills

Repositorio central de skills de agente para Synapse OS.

## Contenido

- **`handoff/`** — Skill de traspaso estructurado (handoff) del ecosistema Matt Pocock
- **`cursor-rules/`** — Reglas `.mdc` para Cursor 2.5 convertidas desde todos los skills de `~/.agents/skills/`
- **`scripts/`** — Utilidades de sincronización entre agentes (ZCode, Cursor, Antigravity)
- **`hooks/`** — Git hooks para auto-sync

## Flujo de sincronización

```
~/.agents/skills/  ←→  synapse-skills repo  ←→  GitHub (DarioLubisco/synapse-skills)
       ↓
~/.cursor/rules/  (reglas .mdc para Cursor 2.5)
```

### Cómo sincronizar

**Traer cambios desde `~/.agents/skills/` al repo:**
```bash
./scripts/sync-from-agent.sh
git add -A && git commit -m "sync: actualizar skills desde agente"
```

**Push automático:** El hook `post-commit` pushea a GitHub y regenera las reglas Cursor.

**Regenerar reglas Cursor manualmente:**
```bash
./scripts/sync-to-cursor.sh
```

### Hooks y auto-sync

| Hook | Disparador | Acción |
|------|-----------|--------|
| `post-commit` | `git commit` | Push a GitHub + sync a Cursor 2.5 |
| `post-merge` | `git pull` / `git merge` | Sync a Cursor 2.5 si hay cambios |

**Auto-pull desde GitHub (cada 10 min):**
Un `systemd --user timer` corre `scripts/auto-pull.sh` cada 10 minutos. Si detecta cambios remotos en GitHub, los trae con `git pull --ff-only` y regenera las reglas Cursor.

```bash
# Ver estado del timer
systemctl --user status synapse-skills-pull.timer
```

### Ciclo completo de sincronización

```
Local: ~/.agents/skills/
  │
  ├── sync-from-agent.sh  ──>  synapse-skills/ (handoff)
  │                                │
  │                          git commit
  │                                │
  │                ┌── post-commit hook ──> Push a GitHub
  │                │                         + sync a Cursor
  │                │
  │                └── post-merge hook  ──> Sync a Cursor tras merge
  │
  └── sync-to-cursor.sh  ──> ~/.cursor/rules/ (169 .mdc)
        (manual o automático)

GitHub (DarioLubisco/synapse-skills)
  │
  └── auto-pull (cada 10min) ──> git pull ──> sync a Cursor
```

### Integración con Synapse OS

Este repo se integra con el ecosistema `.synapse` existente:
- Los hooks de `.synapse` sincronizan con Notion (TASK-XXX)
- Los hooks de `synapse-skills` sincronizan skills con GitHub y Cursor
- Ambos coexisten en `~/source/` y se complementan
# Sync test - hooks unificados
