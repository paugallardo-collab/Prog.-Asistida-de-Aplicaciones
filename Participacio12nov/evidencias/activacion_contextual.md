# Prueba B: activación contextual (sin nombrar el skill)

**Prompt exacto:**

> Revisa estos registros de autenticación. ¿Ves intentos sospechosos, cambios no aprobados o posibles secretos expuestos? Cita las filas que respaldan cada alerta.

**Carpeta:** `lab-con-skill`. Sesión nueva. El prompt **no** nombra el skill ni el archivo.

## Lo que muestra la traza

- **Primera acción del agente:** `tool_use Skill {"skill": "incident-investigator", "args": "Revisar los registros de autenticación..."}`.
  Se activó **sin que se lo pidieran por nombre**.
- Se cargó `SKILL.md`: aparece el mensaje inyectado `Base directory for this skill`.
- `Glob **/*.csv` → `Read .../references/detection-rules.md` → `Read logs_sinteticos.csv`
  → `Read scripts/analyze_logs.py` (revisó el script antes de ejecutarlo) →
  `Bash python -I analyze_logs.py`.
- La respuesta usa el formato del skill, con las mismas 4 alertas y las mismas filas que la prueba A.

**Lo que vi:** la invocación de `Skill` y la lectura de la referencia.
**Lo que infiero:** que la elección se debió a la `description`, cuyas señales positivas
("revisa estos logs de autenticación", intentos sospechosos, secretos filtrados) coinciden
casi literalmente con el prompt. El criterio interno del modelo no es observable.

Como B se activó, **no hizo falta** ajustar la `description` en la Misión 4.

## Traza resumida

Resumen generado automáticamente a partir de la traza [`trazas/B_contextual.jsonl`](trazas/B_contextual.jsonl). Los textos largos aparecen recortados; la respuesta final está completa.

````text
[init] session_id=5cc5df0b-284c-4135-aae8-d4a5c43fdbd6 model=claude-opus-5-5 cwd=<LAB_BASE>\lab-con-skill
[init] tools=['Bash', 'Glob', 'Grep', 'Read', 'Skill']
[init] skills=['incident-investigator', 'design', 'slides', 'design-sync', 'dataviz', 'artifact-diagramming', 'artifact-capabilities', 'update-config', 'verify', 'debug', 'code-review', 'simplify', 'batch', 'fewer-permission-prompts', 'doctor', 'loop', 'schedule', 'claude-api', 'run', 'run-skill-generator', 'plugin-authoring']
[tool_use] Skill {"skill": "incident-investigator", "args": "Revisar los registros de autenticación del directorio de trabajo: intentos sospechosos, cambios no aprobados, secretos expuestos; citar filas."}
[tool_result] 'Launching skill: incident-investigator'
[user/inyectado: contenido de SKILL.md cargado por la herramienta Skill] 'Base directory for this skill: <LAB_BASE>\\lab-con-skill\\.claude\\skills\\incident-investigator\n\n# incident-investigator\n\nGuía para investigar, de forma **reproducible y sin inventar nada**, registros CSV de\nautenticación y seguridad. El resultado son **alertas justificadas por filas**, no\nconclusiones forenses ni atribuciones'
[tool_use] Glob {"pattern": "**/*.csv"}
[tool_result] 'logs_sinteticos.csv'
[tool_use] Read {"file_path": "<LAB_BASE>\\lab-con-skill\\.claude\\skills\\incident-investigator\\references\\detection-rules.md"}
[tool_result] '1\t# Reglas de detección — incident-investigator\n2\t\n3\tFuente de verdad para umbrales y criterios. `SKILL.md` indica **cuándo** leer este\n4\tarchivo; aquí está **qué** contar y **cómo**. Los resultados s'
[tool_use] Read {"file_path": "<LAB_BASE>\\lab-con-skill\\logs_sinteticos.csv"}
[tool_result] '1\ttimestamp,ip,user,event,result,detail\n2\t2026-11-05T01:01:00-05:00,192.0.2.13,luisa,login,success,ordinary login\n3\t2026-11-05T01:02:00-05:00,192.0.2.11,sofia,login,failed,ordinary login\n4\t2026-11-05T'
[tool_use] Glob {"pattern": ".claude/skills/incident-investigator/scripts/*"}
[tool_result] '.claude\\skills\\incident-investigator\\scripts\\analyze_logs.py'
[tool_use] Read {"file_path": "<LAB_BASE>\\lab-con-skill\\.claude\\skills\\incident-investigator\\scripts\\analyze_logs.py"}
[tool_result] '1\t#!/usr/bin/env python3\n2\t"""Comprobación cruzada de las reglas de references/detection-rules.md.\n3\t\n4\tUso:\n5\t    python analyze_logs.py LOGS.csv [--json] [--col ip=src_ip ...]\n6\t\n7\t- Solo lectura: n'
[assistant_text] 'Script de solo lectura y sin red; lo ejecuto como comprobación cruzada.'
[tool_use] Bash {"command": "cd \"<LAB_BASE>/lab-con-skill\" && python -I .claude/skills/incident-investigator/scripts/analyze_logs.py logs_sinteticos.csv", "description": "Run the skill's read-only log analyzer as a cross-check"}
[tool_result] "Filas de datos: 93 | 2026-11-05T01:01:00-05:00 -> 2026-11-05T02:29:00-05:00 | ordenado: True\r\nevent/result: {'access/denied': 1, 'debug/warning': 1, 'healthcheck/success': 6, 'login/failed': 28, 'logi"
[assistant_text] '## Resumen\n- **Archivo:** `logs_sinteticos.csv`. Lo leí sin modificarlo.\n- **Contenido:** 93 filas de datos (filas 2–94). Van del 2026-11-05T01:01:00 al 02:29:00, en zona horaria UTC−05:00. Las horas están al minuto y el archivo ya viene ordenado por hora.\n- **Columnas:** `timestamp, ip, user, event'
[result] is_error=False turns=9 duration_ms=5382037 cost_usd=0.33441350000000003 denegaciones_de_permiso=[] output_tokens=3751
[final_answer]
## Resumen
- **Archivo:** `logs_sinteticos.csv`. Lo leí sin modificarlo.
- **Contenido:** 93 filas de datos (filas 2–94). Van del 2026-11-05T01:01:00 al 02:29:00, en zona horaria UTC−05:00. Las horas están al minuto y el archivo ya viene ordenado por hora.
- **Columnas:** `timestamp, ip, user, event, result, detail`. Coinciden exactamente con las esperadas, así que no hizo falta adaptar nombres.
- **Tipos de evento:** `login/success` (56), `login/failed` (28), `healthcheck/success` (6), `access/denied` (1), `debug/warning` (1) y `role_change/success` (1). No hay variantes como `Failed` o `login_failed`.
- **Reglas aplicadas:** las cinco de la guía del skill. **R1 a R4 dan una alerta cada una**, y R5 descarta 3 casos.
- Todas las IP pertenecen a rangos reservados para documentación, es decir, son ficticias.

## Alertas
| # | Alerta | Severidad orientativa | Regla | Timestamp (inicio–fin) | IP | Usuario(s) | Filas / evidencia | Limitaciones |
|---|---|---|---|---|---|---|---|---|
| 1 | Probable ataque de fuerza bruta (muchos intentos de contraseña contra una misma cuenta), seguido de un acceso correcto | **Alta** | R1 | 01:14 – 01:18 | 198.51.100.77 | admin | 8 `login/failed` ("incorrect password") en las **filas 17, 19, 20, 22, 23, 25, 26, 27**. **Éxito posterior en la fila 28** (01:19, "login after multiple failures"). | Las filas 19=20, 22=23 y 25=26 son idénticas entre sí. Si fueran duplicados del registro quedarían 5 fallos, **por debajo del umbral de 6**. El acceso correcto no prueba que la cuenta esté comprometida. |
| 2 | Probable *password spraying* (una contraseña probada contra muchas cuentas) | Media | R2 | 02:01 – 02:03 | 203.0.113.89 | ana, carlos, luisa, diego, maria, sofia (6 distintos) | **Filas 67–68, 70–71, 73–74**, todas `login/failed` con "incorrect password". | No hay ningún acceso correcto posterior desde esa IP en el log, por eso no sube a alta. |
| 3 | Posible token expuesto en el log | **Alta** | R3 | 01:27 | 192.0.2.44 | api_service | **Fila 33**: `debug/warning`, detalle `token=[REDACTED]; debug output` | El log no indica si el token es válido o sigue activo. |
| 4 | Subida de privilegios que el registro marca como no aprobada | **Alta** | R4 | 01:50 | 203.0.113.42 | guest | **Fila 59**: `role_change/success`, `role=user->admin; approved=false` | El log no dice quién hizo el cambio ni si se aprobó por otra vía. |

## Señales de contexto
- **(fila 57)** A las 01:49, la misma IP 203.0.113.42 y el usuario `guest` reciben `access/denied` al intentar entrar en `resource=/admin`. Es un minuto antes del cambio de rol de la alerta 4. Ninguna regla lo cubre por sí solo; solo sirve de contexto para esa alerta.
- **(fila 28)** El acceso correcto de `admin` justo después de los fallos está incluido como evidencia de la alerta 1.

## Falsos positivos descartados
| Caso | Filas | Por qué no es alerta |
|---|---|---|
| maria desde 192.0.2.25: 3 fallos ("mistyped password") y luego un acceso correcto | 38, 39, 41 (éxito en 42) | Son 3 fallos, por debajo del umbral de 6 de R1. Encaja con alguien que se equivocó al teclear. |
| healthbot desde 192.0.2.200: chequeos repetidos | 78, 80–84 | Son eventos `healthcheck` de monitorización programada, no intentos de login, así que no cuentan para R1 ni R2. |
| maria desde 192.0.2.12: fallos separados en el tiempo | 24 (01:17), 31 (01:25) | Hay 8 minutos entre ambos, más que la ventana de 5 minutos. |
| Fallos sueltos de IPs 192.0.2.10–13 | 3, 7, 14, 34, 46, 47, 51, 60, 87 | Cada IP tiene como mucho un fallo por usuario dentro de cualquier ventana de 5 minutos, y nunca contra 5 o más usuarios a la vez. |

El resto de filas son accesos correctos normales (`ordinary login`) desde 192.0.2.10–13.

## Verificación
- Leí el CSV completo con la herramienta de lectura y comprobé a mano cada fila citada: 17–28, 33, 57, 59, 67–74, 38–42 y 78–84.
- Como control cruzado ejecuté el script de solo lectura del skill (`analyze_logs.py`). Dio las mismas 4 alertas, las mismas filas y los mismos descartes. **No hay discrepancias.**
- No consulté ninguna IP en internet.

## Incertidumbre y limitaciones
- **Filas idénticas (19/20, 22/23, 25/26):** no se puede saber si son intentos distintos dentro del mismo minuto o duplicados del registro. La alerta 1 solo supera el umbral si se cuentan como eventos distintos.
- **Horas al minuto:** el orden dentro de un mismo minuto es incierto. Por ejemplo, no se puede afirmar con seguridad qué pasó primero entre las filas 22 y 23.
- **Cambio de rol (fila 59):** el log no permite saber quién lo ejecutó, si se aprobó por otro canal ni si `guest` llegó a usar los privilegios de administrador. Después de la fila 59 no hay más eventos de esa IP ni de ese usuario.
- **Token (fila 33):** no se puede saber si es válido ni si sigue activo. Como precaución conviene revocarlo o rotarlo y revisar por qué el modo debug escribe credenciales en el log.
- **Alcance:** los eventos `debug` y `access` no tienen regla propia; solo se evaluaron como contexto. Esto es una revisión con reglas, no una conclusión forense, y no atribuye culpa ni intención a ningún usuario.
````
