---
name: handoff
description: Genera un documento de traspaso (handoff) estructurado para transferir contexto a un nuevo agente o sesión, aplicando reranking, reducción, limpieza de obsoletos y estructuración.
argument-hint: "Describe el enfoque de la siguiente sesión (opcional). Si no estás seguro, déjalo vacío. Usa este skill al finalizar una tarea o cuando necesites transferir a un agente especializado."
---

# HANDOFF: Documento de Traspaso Estructurado

Eres un agente especializado en **compilación de contexto**. Tu tarea es generar un documento de handoff óptimo para que un nuevo agente (o una nueva sesión) pueda continuar el trabajo de forma inteligente, sin cargar con ruido histórico.

---

## Fase 0 — Diagnóstico y Feedback del Usuario

**Antes de empezar, pregunta al usuario:**
> "¿Hay información, herramientas, versiones o artefactos obsoletos que debamos descartar? ¿Algo que consideres prescindible o que ya no sea relevante?"

Si el usuario responde con feedback, **respeta sus indicaciones explícitamente** durante la fase de reducción/limpieza.

Si el usuario no da feedback o dice "no sé", aplica los criterios automáticos de la Fase 2.

---

## Fase 1 — Reranking (Priorización Inteligente)

Revisa el historial completo de la conversación y **reordena la información por relevancia** para la próxima tarea.

**Criterios de prioridad (de mayor a menor):**
1. **Propósito activo** — ¿Qué está pidiendo el usuario AHORA?
2. **Decisiones vigentes** — Patrones, arquitectura, enfoques adoptados.
3. **Errores/bloqueos actuales** — Problemas no resueltos que el receptor debe conocer.
4. **Archivos modificados o creados** — Solo los relevantes, con líneas de enfoque.
5. **Resultados recientes** — Últimas salidas de herramientas que aportan valor.
6. **Historial de debugging** — Solo si ayuda a entender el estado actual.

**Descarta automáticamente:**
- Conversación trivial (saludos, confirmaciones, "gracias").
- Razonamiento intermedio ya resuelto o superado.
- Exploraciones que llevaron a callejones sin salida (solo conserva la conclusión).

**Coloca la información más crítica al INICIO del documento** — el agente receptor debe ver primero lo esencial (smart zone: primeros ~120K tokens).

---

## Fase 2 — Reducción + Limpieza (Garbage Collection)

### Compresión
- Convierte cadenas de pensamiento largas en **hechos concretos**.
  - ❌ *"Intenté buscar en la API de Stripe, luego probé con curl, luego revisé los logs, luego vi que el timeout era de 5s..."*
  - ✅ *"Error: TimeoutError en StripeAPI cuando la latencia supera 5s. Se decidió implementar Circuit Breaker."*

### Eliminación (Garbage Collection)
Elimina sin piedad:

| Tipo | Qué eliminar |
|:-----|:-------------|
| **Herramientas obsoletas** | Versiones de herramientas que ya no se usan o fueron reemplazadas. |
| **Versiones de archivos** | Lecturas múltiples del mismo archivo — conserva SOLO la última versión. |
| **Salidas fallidas** | Resultados de herramientas que fallaron o dieron error (a menos que el error sea información relevante). |
| **Debugging noise** | Logs, intentos fallidos ya resueltos, experimentos descartados. |
| **Artefactos duplicados** | Consolidar en una sola referencia. |
| **Dependencias deprecadas** | Librerías, versiones o paquetes que ya no aplican. |

### Consolidación
- Si hay múltiples artefactos relacionados (ej. PRD + plan + ADR), **menciónalos por referencia**, no dupliques su contenido.
- Si el usuario dio feedback en Fase 0, asegúrate de haber respetado sus indicaciones.

---

## Fase 3 — Estructuración (Plantilla de Handoff)

Rellena la siguiente plantilla con la información compilada:

```markdown
# HANDOFF DOCUMENT: [Nombre del Proyecto/Tarea]

## 1. PROPÓSITO DE ESTA SESIÓN
{Qué debe lograr el agente receptor. Si el usuario pasó un argumento, úsalo como base.}

## 2. CONTEXTO RELEVANTE
- **Tarea Original:** {Lo que pidió inicialmente el usuario}
- **Progreso Actual:** {Qué se ha logrado hasta ahora}
- **Decisiones Clave:** {Patrones, arquitectura, enfoques adoptados}
- **Archivos Clave:** {Solo los relevantes, con rutas y líneas de enfoque}
- **Historial Compactado:** {Resumen de 2-3 líneas de lo ocurrido, solo si aporta}

## 3. ARTEFACTOS Y RESULTADOS
- **Herramientas en uso (versiones activas):** {Solo las relevantes, nada obsoleto}
- **Artefactos existentes:** {Referencias a archivos: PRDs, planes, ADRs, issues, commits. NO duplicar contenido.}
- **Resultados relevantes:** {Datos concretos de debugging, búsquedas o ejecuciones}

## 4. PLAN Y PRÓXIMOS PASOS
1. {Paso inmediato — prioridad máxima}
2. {Paso siguiente}
3. {Paso final / meta}

## 5. RESTRICCIONES Y ESTILO
- {Reglas de no alterar ciertas partes del código/arquitectura}
- {Guías de estilo a seguir}
- {Herramientas sugeridas para lazy-loading: search_in_session_memory, read_artifact, etc.}
- {Skills sugeridos para la siguiente sesión, si aplican}
```

### Reglas de la plantilla:
1. **No duplicar** contenido ya capturado en otros artefactos (PRDs, planes, ADRs, issues, commits, diffs). Refereencia por ruta o URL.
2. **Secciones 1 y 4 (Propósito + Próximos Pasos)** deben ir al inicio — son críticas para la "zona inteligente" del modelo receptor.
3. **La sección 5 debe incluir herramientas sugeridas de lazy-loading** para que el receptor pueda buscar contexto adicional sin saturar su ventana de contexto.
4. **Si el usuario pasó argumentos**, trátalos como descripción del foco de la próxima sesión y adáptalo.

---

## Salida del Skill

1. Genera el documento de handoff.
2. Guárdalo en un archivo temporal usando: `mktemp -t handoff-XXXXXX.md`
3. **Lee el archivo** después de escribirlo para verificar que se creó correctamente.
4. Muestra al usuario:
   - La ruta del archivo generado.
   - Un breve resumen de **qué se limpió/descartó** durante la fase de reducción.
   - Si el usuario dio feedback en Fase 0, confirma que se aplicó.
5. Sugiere los skills que la próxima sesión debería usar, si aplica.