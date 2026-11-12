# Evidencias: cómo se instaló, cómo se probó y qué se observó

Las evidencias son **trazas textuales reales** de Claude Code en modo no interactivo
(`--output-format stream-json`), no capturas de pantalla. Cada prueba fue una **sesión
nueva e independiente**: un proceso `claude -p` por prueba, sin `--continue` ni
`--resume` y con `--no-session-persistence`. Ninguna sesión heredó el contexto de otra.

## Entorno

| Elemento | Valor |
|---|---|
| Agente | Claude Code **2.1.322** (binario de la extensión de VS Code). El CLI global de npm (2.1.204) no admitía el modelo y lo rechazó con un error 400. |
| Modelo | `claude-opus-5-5`, `--effort high`, el mismo en todas las corridas |
| SO | Windows 11, Git Bash |
| Fecha | 2026-11-10 |

## Instalación del skill

Claude Code carga los skills de proyecto desde `<proyecto>/.claude/skills/<nombre>/SKILL.md`.
La copia canónica del skill es [`../incident-investigator/`](../incident-investigator/), y
para instalarlo la copié tal cual:

```bash
mkdir -p <LAB>/.claude/skills
cp -r incident-investigator <LAB>/.claude/skills/
diff -r incident-investigator <LAB>/.claude/skills/incident-investigator   # sin diferencias
```

## Laboratorio aislado (por qué no se probó en la carpeta del repo)

En la carpeta del repo, el agente podría encontrar `incident-investigator/SKILL.md` con
un `Glob` y leerlo como un archivo más. Eso se confundiría con una activación del skill.
También cargaría el `CLAUDE.md` del proyecto. Para evitarlo usé dos carpetas temporales
idénticas salvo por el skill:

| Carpeta | Contenido |
|---|---|
| `lab-con-skill/` | `logs_sinteticos.csv` + `.claude/skills/incident-investigator/` |
| `lab-sin-skill/` | `logs_sinteticos.csv` y nada más |

Las dos copias del CSV tienen el mismo SHA-256 que el original
(`67ee039fcb45396bb9285fdcbc1430e45af52c5a1920c4dbd5f3eb9b92904756`). En los resúmenes,
la ruta temporal de las carpetas aparece abreviada como `<LAB_BASE>`.

## Comando usado en todas las pruebas

```bash
claude -p "<prompt exacto>" \
  --output-format stream-json --verbose --no-session-persistence \
  --model claude-opus-5-5 --effort high \
  --setting-sources project --strict-mcp-config \
  --tools "Read,Glob,Grep,Bash,Skill" \
  --allowedTools Read Glob Grep Skill "Bash(python *)" "Bash(head *)" "Bash(sed *)" ...
```

- `--tools` deja **solo** herramientas locales: sin `WebFetch` ni `WebSearch`, y
  `--strict-mcp-config` sin servidores MCP. Esto **no es un aislamiento de red
  demostrado**: `Bash` seguía disponible, limitado a los prefijos de la lista, entre ellos
  `python`. Lo que sí está comprobado es que **ninguna de las 6 trazas contiene un comando
  de red**: busqué `curl`, `wget`, `http`, `socket`, `urllib`, `requests`, `nslookup`,
  `ping` y `whois` en todas las llamadas `Bash` y hubo 0 coincidencias.
- Fue **la misma configuración** en las condiciones con y sin skill. Lo único que cambia
  es la carpeta.
- Algunas llamadas `Bash` con `cd ... && ...` quedaron **denegadas** por el sistema de
  permisos: en modo `-p` no hay nadie que las apruebe. Las denegaciones aparecen en cada
  traza. El agente reintentó con comandos más simples, y eso no tiene que ver con el skill.

## Qué prueba la activación (lo que **vi** en la traza)

En la traza, una activación real se reconoce por esta secuencia:

1. El evento `init` incluye `incident-investigator` en `skills`. Esto indica que el skill
   está instalado y disponible. En `lab-sin-skill` **no aparece**.
2. Hay un `tool_use` de la herramienta **`Skill`** con `{"skill": "incident-investigator"}`,
   y su resultado es `Launching skill: incident-investigator`.
3. Aparece un mensaje inyectado con `Base directory for this skill: ...` seguido del
   **contenido de `SKILL.md`**.
4. Hay un `tool_use` **`Read`** de `.../references/detection-rules.md`.

Que el modelo nombre el skill en su respuesta **no** cuenta como prueba. La prueba son los
eventos 2–4.

**Lo que infiero y no puedo ver:** en la prueba B, que el modelo eligió el skill
basándose en su `description`. La traza muestra que lo invocó como primera acción sin que
el prompt lo nombrara, pero el razonamiento interno de esa elección no es observable.

## Redacción aplicada a las trazas

Los `.jsonl` de [`trazas/`](trazas/) son las trazas completas con **una sola
modificación**: el valor que sigue a `token=` se sustituyó por `[REDACTED]`, para que
ningún token completo llegue al PR. Por lo demás están tal como se emitieron. En la
condición *sin skill*, la respuesta original del modelo **mostraba el token completo**.
Ese valor también está redactado aquí (ver `comparacion.md`).

## Índice

| Archivo | Prueba | Resultado observado |
|---|---|---|
| [activacion_explicita.md](activacion_explicita.md) | A: explícita | Se invocó `Skill`, se cargó `SKILL.md` y se leyó `detection-rules.md` |
| [activacion_contextual.md](activacion_contextual.md) | B: contextual, sin nombrar el skill | Igual que A: se activó solo |
| [control_negativo.md](control_negativo.md) | C y C2: controles negativos | **No** se invocó el skill (resultado deseado) |
| [mision5_sin_skill.md](mision5_sin_skill.md) | Misión 5, sin skill | Sin skill disponible; mostró el token completo |
| [mision5_con_skill.md](mision5_con_skill.md) | Misión 5, con skill | Se activó solo; redactó el token incluso antes de leer el CSV |
