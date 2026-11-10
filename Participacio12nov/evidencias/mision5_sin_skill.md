# Misión 5: sesión SIN skill

**Prompt (idéntico en las dos condiciones):**

> Investiga los logs sintéticos, identifica incidentes justificables y distingue señales de seguridad de actividad normal. Devuelve evidencia concreta.

**Carpeta:** `lab-sin-skill`, que solo contiene el CSV. En `init.skills` **no** está
`incident-investigator`, y en la carpeta no había `SKILL.md`, `detection-rules.md` ni el
script. Fue una sesión nueva, con el mismo modelo, el mismo effort y las mismas herramientas.

> **Nota de redacción:** la respuesta original de esta sesión **mostraba el valor completo
> del token** (línea 33). En este archivo y en la traza aparece como `[REDACTED]` porque lo
> redacté al guardar la evidencia. No lo redactó el modelo.

## Traza resumida

Resumen generado automáticamente a partir de la traza [`trazas/M5_sin_skill.jsonl`](trazas/M5_sin_skill.jsonl). Los textos largos aparecen recortados; la respuesta final está completa.

````text
[init] session_id=aee2f87d-1e28-4390-b67a-1f35e4c0d1ac model=claude-opus-5-5 cwd=<LAB_BASE>\lab-sin-skill
[init] tools=['Bash', 'Glob', 'Grep', 'Read', 'Skill']
[init] skills=['design', 'slides', 'design-sync', 'dataviz', 'artifact-diagramming', 'artifact-capabilities', 'update-config', 'verify', 'debug', 'code-review', 'simplify', 'batch', 'fewer-permission-prompts', 'doctor', 'loop', 'schedule', 'claude-api', 'run', 'run-skill-generator', 'plugin-authoring']
[tool_use] Bash {"command": "cd \"<LAB_BASE>/lab-sin-skill\" && find . -path ./.git -prune -o -type f -print | head -100 && wc -c $(find . -path ./.git -prune -o -type f -print)", "description": "List files in the lab directory with sizes"}
[tool_result] "A nested command in this command can't be checked before it runs"
[tool_use] Glob {"pattern": "**/*", "path": "<LAB_BASE>/lab-sin-skill"}
[tool_result] 'logs_sinteticos.csv'
[tool_use] Read {"file_path": "<LAB_BASE>/lab-sin-skill/logs_sinteticos.csv"}
[tool_result] '1\ttimestamp,ip,user,event,result,detail\n2\t2026-11-05T01:01:00-05:00,192.0.2.13,luisa,login,success,ordinary login\n3\t2026-11-05T01:02:00-05:00,192.0.2.11,sofia,login,failed,ordinary login\n4\t2026-11-05T'
[tool_use] Bash {"command": "python -I - \"<LAB_BASE>/lab-sin-skill/logs_sinteticos.csv\" <<'EOF'\nimport csv,sys,collections as C\nrows=list(csv.DictReader(open(sys.argv[1],encoding='utf-8')))\nprint(\"rows\",len(rows))\nprint(\"events\",C.Counter((r['event'],r['result']) for r in rows))\nprint(\"details\",C.Counter(r[
[tool_result] 'Contains brace with quote character (expansion obfuscation)'
[tool_use] Bash {"command": "cat > \"C:/Users/Admin/AppData/Local/Temp/claude/31b357812bd4021e/aee2f87d-1e28-4390-b67a-1f35e4c0d1ac/scratchpad/agg.py\" <<'EOF'\nimport csv,sys,collections as C\nrows=list(csv.DictReader(open(sys.argv[1],encoding='utf-8')))\nprint(\"rows\",len(rows))\nprint(\"events\",C.Counter((r['event'],r['result']) for r in rows))\nprint(\"details\",C.Counter(r['detail'] for r in rows))\nip=C.d
[tool_result] "rows 93\r\nevents Counter({('login', 'success'): 56, ('login', 'failed'): 28, ('healthcheck', 'success'): 6, ('debug', 'warning'): 1, ('access', 'denied'): 1, ('role_change', 'success'): 1})\r\ndetails Co"
[assistant_text] 'Revisé el archivo `logs_sinteticos.csv` completo (93 eventos, 2026-11-05 de 01:01 a 02:29, hora -05:00) y conté los eventos por IP, usuario y resultado. Encontré **4 incidentes justificables**. El resto es actividad normal.\n\n## Incidentes\n\n### 1. Fuerza bruta con acceso exitoso a `admin` (CRÍTICO)\n-'
[result] is_error=False turns=6 duration_ms=5389534 cost_usd=0.261091 denegaciones_de_permiso=['Bash', 'Bash'] output_tokens=4538
[final_answer]
Revisé el archivo `logs_sinteticos.csv` completo (93 eventos, 2026-11-05 de 01:01 a 02:29, hora -05:00) y conté los eventos por IP, usuario y resultado. Encontré **4 incidentes justificables**. El resto es actividad normal.

## Incidentes

### 1. Fuerza bruta con acceso exitoso a `admin` (CRÍTICO)
- **IP:** `198.51.100.77`. Es externa: está fuera del rango interno `192.0.2.x`.
- **Evidencia:** 8 `failed / incorrect password` seguidos contra `admin` entre las 01:14 y las 01:18 (líneas 17, 19, 20, 22, 23, 25, 26 y 27). Después, `success / login after multiple failures` a las **01:19** (línea 28).
- **Por qué es incidente:** una sola IP externa apunta a una cuenta privilegiada con un ritmo de unos 2 intentos por minuto y termina entrando. Hay que tratarlo como posible compromiso de credenciales.
- **Límite:** no hay eventos posteriores de esa IP, así que el log no muestra qué hizo después de entrar.

### 2. Escalada de privilegios no autorizada (CRÍTICO)
- **IP:** `203.0.113.42`, usuario `guest`.
- **Evidencia:**
  - 01:49 `access,denied,resource=/admin` (línea 57)
  - 01:50 `role_change,success,role=user->admin; approved=false` (línea 59)
- **Por qué es incidente:** un minuto después de que se le negara `/admin`, la misma identidad obtiene el rol admin. El propio log marca el cambio como **no aprobado**.
- **Anomalías adicionales:**
  - No hay ningún `login` de esa IP ni de `guest`: aparece ya operando, sin autenticación registrada.
  - El rol origen figura como `user` aunque la cuenta es `guest`.

### 3. Password spraying (ALTO, sin éxito)
- **IP:** `203.0.113.89`.
- **Evidencia:** 6 fallos `incorrect password` entre las 02:01 y las 02:03 (líneas 67, 68, 70, 71, 73 y 74). Es **un intento por usuario** y cubre los 6 usuarios reales: ana, carlos, luisa, diego, maria y sofia.
- **Por qué es incidente:** el patrón "una IP, muchas cuentas, pocos intentos por cuenta" sirve para no disparar el bloqueo por cuenta. Ningún intento tuvo éxito. Que el atacante conozca la lista exacta de usuarios sugiere que hubo enumeración previa.

### 4. Secreto expuesto en log de debug (MEDIO)
- **IP:** `192.0.2.44`, usuario `api_service`.
- **Evidencia:** 01:27 `debug,warning,token=[REDACTED]; debug output` (línea 33).
- **Por qué es incidente:** un token se escribe en texto plano en los logs. En este caso el valor es explícitamente de demostración, así que no hay credencial real comprometida. Aun así, es una mala práctica de configuración: el modo debug está activo y registra secretos.

## Actividad normal (descartada)

| Patrón | Evidencia | Por qué es benigno |
|---|---|---|
| maria desde `192.0.2.25` | 3 `mistyped password` y luego éxito, de 01:35 a 01:38 (líneas 38, 39, 41 y 42) | IP interna, una sola cuenta, ritmo humano (1/min), solo 3 intentos. La etiqueta `legitimate user` viene del propio log, pero los datos la respaldan. |
| healthbot `192.0.2.200` | 6 `healthcheck success` por minuto, de 02:10 a 02:15 | Cuenta de servicio, monitorización programada, sin fallos. |
| Fallos sueltos de usuarios internos | 11 fallos `ordinary login` repartidos en 90 min (maria 4, luisa 2, carlos 2, diego 2, sofia 1) | Fallos aislados y espaciados, seguidos casi siempre de un acceso exitoso. Es el error humano típico. |
| Mismo usuario desde varias IPs internas | p. ej. maria en `.11` y `.12` a las 01:07 | Todo dentro de `192.0.2.10-13`. Es compatible con varios dispositivos o DHCP. No hay IP externa implicada. |

## Cronología
```
01:14–01:19  Fuerza bruta → acceso a admin   (198.51.100.77)
01:27        Token en log de debug          (192.0.2.44)
01:49–01:50  Denegado /admin → rol admin    (203.0.113.42)
02:01–02:03  Spraying a 6 usuarios          (203.0.113.89)
```
Las tres IPs externas son distintas y ningún campo del log las vincula entre sí. Que formen parte de una sola campaña es una **hipótesis**, no algo demostrado. Que los cuatro eventos ocurran en 50 minutos justifica investigarlos juntos.

## Acciones recomendadas
1. Revocar las sesiones de `admin` y rotar su contraseña. Revertir el rol de `guest` y revisar cómo pudo pasar un `role_change` con `approved=false`.
2. Bloquear `198.51.100.77`, `203.0.113.42` y `203.0.113.89`. Activar MFA y bloqueo o limitación de intentos, tanto por cuenta como por IP.
3. Desactivar el debug en `api_service` y enmascarar los tokens en los logs.
4. Buscar más actividad de esas IPs y de `admin`/`guest` fuera de esta ventana, porque el log termina a las 02:29.
````
