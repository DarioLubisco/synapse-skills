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

### Hooks instalados

| Hook | Disparador | Acción |
|------|-----------|--------|
| `post-commit` | `git commit` | Push a GitHub + sync a Cursor 2.5 |

### Integración con Synapse OS

Este repo se integra con el ecosistema `.synapse` existente:
- Los hooks de `.synapse` sincronizan con Notion (TASK-XXX)
- Los hooks de `synapse-skills` sincronizan skills con GitHub y Cursor
- Ambos coexisten en `~/source/` y se complementan
# Sync test
