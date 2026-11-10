# Respuestas — Misión 6: Plugin Detective

Plataforma usada: **Claude Code 2.1.322** (Windows). Los nombres de archivos de plugin que
cito son los de Claude Code; en otras plataformas el formato cambia.

## 1. Skill frente a plugin

**Por qué `incident-investigator` es un skill.** Lo que aporta son **instrucciones y
recursos que se cargan según el contexto**: un `description` que le dice al agente
*cuándo* usarlo, un procedimiento (`SKILL.md`), una referencia que se abre solo cuando
hace falta (`references/detection-rules.md`) y un script opcional. No reacciona a
eventos del entorno (eso sería un hook), no da acceso a un sistema externo (eso sería
MCP) y no necesita ningún componente más para funcionar. El agente lo activa cuando la
petición encaja (lo comprobamos en las pruebas A y B) y no lo activa cuando no encaja
(prueba C).

**Qué más podría empaquetarse para distribuirlo como plugin** (Claude Code):

| Componente | Archivo en el plugin | Para qué serviría aquí |
|---|---|---|
| Manifiesto | `.claude-plugin/plugin.json` | Nombre, versión, autor y descripción del plugin "cyber-detective". Para distribuirlo, una entrada en un `marketplace.json`. |
| Skill | `skills/incident-investigator/` | Este mismo skill, sin cambios. |
| Comando | `commands/investigar-logs.md` | `/investigar-logs <archivo.csv>`: invocación explícita y repetible con el formato de salida fijo, útil cuando no se quiere depender de la autoactivación. |
| Hook | `hooks/hooks.json` | `PreToolUse` que bloquee `WebFetch`/`WebSearch` y comandos de red (`curl`, `Invoke-WebRequest`) durante la investigación, y que impida escribir sobre el CSV original. `PostToolUse`/`Stop` que busque `token=` seguido de un valor sin `[REDACTED]` en el informe y lo rechace. Así la regla "sin red y sin secretos" deja de depender solo de que el modelo obedezca. |
| Subagente | `agents/verificador-evidencias.md` | Revisor de solo lectura que recalcula cada alerta contra las filas citadas, sin heredar el razonamiento del agente principal. |
| MCP | `.mcp.json` | **No hace falta** para este caso (no hay sistemas externos y el skill prohíbe la red). Solo tendría sentido un servidor MCP **local** de solo lectura que expusiera consultas sobre CSV o un SIEM de laboratorio. No lo añadiría sin una necesidad concreta. |

Resumen: el **skill** es el conocimiento del procedimiento. El **plugin** sería el
paquete instalable que lo distribuye junto con controles automáticos (hooks), un
atajo (comando) y un verificador (subagente).

## 2. Ralph Loop: repetir el análisis con comprobaciones verificables

Idea: repetir **investigar → verificar → corregir**, pero dejando que decida un
verificador determinista, no el propio modelo.

**Comprobaciones verificables** (un script de solo lectura sobre `hallazgos.json` y el CSV):

1. Cada fila citada existe en el CSV original (2 ≤ fila ≤ última línea).
2. Cada fila citada coincide con la regla: por ejemplo, en R1 todas son `login/failed`
   con la misma `ip` y el mismo `user`, y caben en ≤ 5 min.
3. Los conteos alcanzan el umbral al recalcularlos desde el CSV (R1 ≥ 6, R2 ≥ 5 usuarios).
4. No hay alertas que el verificador no pueda reproducir, ni alertas reproducibles que
   falten.
5. Ningún valor de secreto en la salida: regex `token=(?!\[REDACTED\])`.
6. El hash SHA-256 del CSV es el mismo que al empezar.
7. Las cinco reglas (R1–R5) aparecen evaluadas y cada alerta tiene su limitación.

**Bucle (máximo 3 iteraciones):**

```text
i = 1
mientras i <= 3:
    el agente genera o corrige hallazgos.json siguiendo el skill
    el verificador ejecuta las comprobaciones 1–7
    si todas pasan          -> PARAR (éxito)
    si los fallos son iguales a los de la iteración anterior -> PARAR (sin progreso)
    al agente se le pasan SOLO los mensajes de las comprobaciones que fallaron
    i = i + 1
si se llega a i = 4 sin éxito -> PARAR y marcar "requiere revisión humana",
    listando las comprobaciones que siguen fallando como limitaciones
```

**Criterio de parada explícito:** todas las comprobaciones pasan, **o** dos iteraciones
seguidas tienen los mismos fallos, **o** se agotan las 3 iteraciones.

**Cómo evitar fabricar evidencia nueva:**

- La única fuente es el CSV, que no cambia (su hash se comprueba en cada vuelta).
- El verificador rechaza cualquier fila que no exista o que no cumpla la regla, así que
  "inventar" una fila nunca sirve para pasar.
- En cada iteración solo se puede **eliminar o corregir** una alerta o añadir una que el
  verificador pueda reproducir desde el CSV. No se puede bajar un umbral ni crear una
  regla para que salga algo.
- El feedback que recibe el agente son los mensajes del verificador, no "hazlo mejor".
  Así el bucle corrige errores comprobables y no reescribe por estética.
