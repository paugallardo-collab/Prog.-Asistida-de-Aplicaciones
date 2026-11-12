# Prueba C: control negativo (y C2, control adicional más estricto)

Carpeta `lab-con-skill`: el skill **estaba instalado y disponible** (aparece en
`init.skills`) en las dos pruebas. Cada una fue una sesión nueva.

## C: prompt del enunciado

> Muéstrame cuántos eventos hay por hora en este CSV; no investigues incidentes ni clasifiques amenazas.

- **No hay ningún `tool_use Skill`** en la traza. Las herramientas usadas fueron `Glob`,
  `Bash head/wc` y `Bash python` (conteo por hora).
- Respuesta: 01:00 → 63, 02:00 → 30, total 93. **Coincide** con mi recuento independiente.
- No clasificó amenazas y no leyó `detection-rules.md`.

## C2: control adicional (no lo pedía el enunciado)

C incluye la pista explícita "no investigues", y eso facilita no activar el skill. Para
probar de verdad el límite de la `description` añadí un conteo que roza el dominio de
seguridad (logins fallidos) **sin** decirle que no investigue:

> ¿Cuántos login fallidos hay por usuario en logs_sinteticos.csv? Dame una tabla.

- **Tampoco hubo `tool_use Skill`.** Hizo un conteo directo en Python.
- Respuesta: admin 8, maria 8, carlos 3, diego 3, luisa 3, sofia 2, ana 1 (total 28).
  Lo verifiqué a mano. Por ejemplo, maria = filas 24, 31, 34, 38, 39, 41, 73, 87.
- Terminó **ofreciendo** investigar, sin hacerlo por su cuenta. Es la conducta que
  busca la cláusula "NO lo uses para conteos..." de la `description`.

Conclusión: el skill no se activó en ninguno de los dos controles negativos, que es el
resultado deseado. No hubo que ajustar la `description`.

## Traza resumida: C

Resumen generado automáticamente a partir de la traza [`trazas/C_control_negativo.jsonl`](trazas/C_control_negativo.jsonl). Los textos largos aparecen recortados; la respuesta final está completa.

````text
[init] session_id=73341bd7-991d-4f73-b0a5-77428696c4d5 model=claude-opus-5-5 cwd=<LAB_BASE>\lab-con-skill
[init] tools=['Bash', 'Glob', 'Grep', 'Read', 'Skill']
[init] skills=['incident-investigator', 'design', 'slides', 'design-sync', 'dataviz', 'artifact-diagramming', 'artifact-capabilities', 'update-config', 'verify', 'debug', 'code-review', 'simplify', 'batch', 'fewer-permission-prompts', 'doctor', 'loop', 'schedule', 'claude-api', 'run', 'run-skill-generator', 'plugin-authoring']
[tool_use] Glob {"pattern": "**/*.csv"}
[tool_result] 'logs_sinteticos.csv'
[tool_use] Bash {"command": "cd \"<LAB_BASE>/lab-con-skill\" && head -5 logs_sinteticos.csv && wc -l logs_sinteticos.csv", "description": "Preview CSV header and line count"}
[tool_result] 'timestamp,ip,user,event,result,detail\n2026-11-05T01:01:00-05:00,192.0.2.13,luisa,login,success,ordinary login\n2026-11-05T01:02:00-05:00,192.0.2.11,sofia,login,failed,ordinary login\n2026-11-05T01:03:00'
[tool_use] Bash {"command": "python -I -c \"\nimport csv,sys,collections\nc=collections.Counter(); bad=0; n=0\nwith open(sys.argv[1],newline='',encoding='utf-8') as f:\n    for r in csv.DictReader(f):\n        n+=1; t=(r.get('timestamp') or '').strip()\n        if len(t)<13 or t[10]!='T': bad+=1; continue\n        c[t[:13]]+=1\nfor k in sorted(c): print(k.replace('T',' ')+':00', c[k])\nprint('total',n,'sin_timest
[tool_result] '2026-11-05 01:00 63\r\n2026-11-05 02:00 30\r\ntotal 93 sin_timestamp_valido 0\nShell cwd was reset to C:\\Users\\Admin\\AppData\\Local\\Temp\\claude\\f26cd5a72562125f\\d791d9d6-c63e-4ff1-80f1-5f3642b9b48b\\scratchp'
[tool_use] Bash {"command": "cut -d, -f1 \"<LAB_BASE>/lab-con-skill/logs_sinteticos.csv\" | tail -n +2 | cut -c20- | sort | uniq -c; cut -d, -f1 \"<LAB_BASE>/lab-con-skill/logs_sinteticos.csv\" | tail -n +2 | sort | sed -n '1p
[tool_result] '     93 -05:00\n2026-11-05T01:01:00-05:00\n2026-11-05T02:29:00-05:00\nShell cwd was reset to <LAB_BASE>\\lab-'
[assistant_text] 'Hay 93 eventos en `logs_sinteticos.csv`, repartidos en dos horas:\n\n| Hora (UTC−05:00) | Eventos |\n|---|---|\n| 2026-11-05 01:00 – 01:59 | 63 |\n| 2026-11-05 02:00 – 02:59 | 30 |\n| **Total** | **93** |\n\n- Todas las marcas de tiempo tienen el mismo huso horario (−05:00) y ninguna estaba vacía o mal form'
[result] is_error=False turns=5 duration_ms=5364480 cost_usd=0.15013530000000003 denegaciones_de_permiso=[] output_tokens=1306
[final_answer]
Hay 93 eventos en `logs_sinteticos.csv`, repartidos en dos horas:

| Hora (UTC−05:00) | Eventos |
|---|---|
| 2026-11-05 01:00 – 01:59 | 63 |
| 2026-11-05 02:00 – 02:59 | 30 |
| **Total** | **93** |

- Todas las marcas de tiempo tienen el mismo huso horario (−05:00) y ninguna estaba vacía o mal formada.
- El registro va de las 01:01 a las 02:29, así que los datos solo cubren la primera media hora de las 02:00. Esa franja tiene menos eventos en parte por eso.

Como pediste, solo he contado los eventos. No he revisado su contenido ni he buscado incidentes o amenazas.
````

## Traza resumida: C2

Resumen generado automáticamente a partir de la traza [`trazas/C2_control_negativo_estricto.jsonl`](trazas/C2_control_negativo_estricto.jsonl). Los textos largos aparecen recortados; la respuesta final está completa.

````text
[init] session_id=03e32d2d-557d-4fb2-995d-58ca5bca8fa4 model=claude-opus-5-5 cwd=<LAB_BASE>\lab-con-skill
[init] tools=['Bash', 'Glob', 'Grep', 'Read', 'Skill']
[init] skills=['incident-investigator', 'design', 'slides', 'design-sync', 'dataviz', 'artifact-diagramming', 'artifact-capabilities', 'update-config', 'verify', 'debug', 'code-review', 'simplify', 'batch', 'fewer-permission-prompts', 'doctor', 'loop', 'schedule', 'claude-api', 'run', 'run-skill-generator', 'plugin-authoring']
[tool_use] Bash {"command": "cd \"<LAB_BASE>/lab-con-skill\" && ls && head -5 logs_sinteticos.csv && wc -l logs_sinteticos.csv", "description": "List files and preview the CSV"}
[tool_result] 'logs_sinteticos.csv\ntimestamp,ip,user,event,result,detail\n2026-11-05T01:01:00-05:00,192.0.2.13,luisa,login,success,ordinary login\n2026-11-05T01:02:00-05:00,192.0.2.11,sofia,login,failed,ordinary login'
[tool_use] Bash {"command": "cd \"<LAB_BASE>/lab-con-skill\" && python -I -c \"\nimport csv,collections\nrows=list(csv.DictReader(open('logs_sinteticos.csv',newline='',encoding='utf-8')))\nprint(len(rows))\nprint(collections.Counter((r['event'],r['result']) for r in rows))\nallu=sorted({r['user'] for r in rows})\nc=coll
[tool_result] "93\r\nCounter({('login', 'success'): 56, ('login', 'failed'): 28, ('healthcheck', 'success'): 6, ('debug', 'warning'): 1, ('access', 'denied'): 1, ('role_change', 'success'): 1})\r\n'admin' 8\r\n'maria' 8\r\n"
[assistant_text] 'En `logs_sinteticos.csv` hay **28 logins fallidos** en total, repartidos así:\n\n| Usuario | Logins fallidos |\n|---|---:|\n| admin | 8 |\n| maria | 8 |\n| carlos | 3 |\n| diego | 3 |\n| luisa | 3 |\n| sofia | 2 |\n| ana | 1 |\n| **Total** | **28** |\n\nConté solo las filas que tienen `event = login` y `result ='
[result] is_error=False turns=3 duration_ms=17884 cost_usd=0.0781239 denegaciones_de_permiso=[] output_tokens=927
[final_answer]
En `logs_sinteticos.csv` hay **28 logins fallidos** en total, repartidos así:

| Usuario | Logins fallidos |
|---|---:|
| admin | 8 |
| maria | 8 |
| carlos | 3 |
| diego | 3 |
| luisa | 3 |
| sofia | 2 |
| ana | 1 |
| **Total** | **28** |

Conté solo las filas que tienen `event = login` y `result = failed`. Los usuarios `api_service`, `guest` y `healthbot` aparecen en el archivo pero no tienen ningún login fallido. No cuenta el evento `access` con resultado `denied` porque no es un login.

Solo es un conteo y no revisé si esto indica algún ataque. Si quieres, puedo investigar si hay fuerza bruta u otra actividad sospechosa, sobre todo en `admin` y `maria`.
````
