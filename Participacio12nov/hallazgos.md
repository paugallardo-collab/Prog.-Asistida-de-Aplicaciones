# Hallazgos: investigación de `logs_sinteticos.csv`

- **Origen del informe:** Prueba A, invocación explícita del skill `incident-investigator`
  en una sesión nueva de Claude Code. La traza está en
  [`evidencias/activacion_explicita.md`](evidencias/activacion_explicita.md).
- **Revisión:** contrasté el informe del agente con las filas originales del CSV (ver
  [§ Verificación manual](#verificación-manual)). Lo que sigue es el informe ya revisado.
- **Advertencia:** son **alertas justificadas, no conclusiones forenses**. No se atribuye
  culpa ni intención a ningún usuario.

## Resumen

| Dato | Valor |
|---|---|
| Archivo | `logs_sinteticos.csv` (solo lectura, SHA-256 `67ee039f…92904756`, sin cambios) |
| Filas de datos | 93 (filas 2–94; la fila 1 es el encabezado) |
| Rango temporal | 2026-11-05 01:01 → 02:29, UTC−05:00, resolución de minuto, ya ordenado |
| Columnas | `timestamp, ip, user, event, result, detail` (no hizo falta mapearlas) |
| `event/result` | `login/success` 56 · `login/failed` 28 · `healthcheck/success` 6 · `access/denied` 1 · `debug/warning` 1 · `role_change/success` 1 |
| Reglas evaluadas | R1–R5 de `references/detection-rules.md`: **4 alertas** (R1, R2, R3, R4) y 2 tipos de falso positivo descartados (R5) |

## Alertas

| # | Alerta | Severidad orientativa | Regla | Timestamp (inicio–fin) | IP | Usuario(s) | Filas / evidencia | Limitaciones |
|---|---|---|---|---|---|---|---|---|
| 1 | Fuerza bruta probable, con éxito posterior | Alta | R1 | 01:14–01:18 (éxito 01:19) | 198.51.100.77 | admin | 8 `login/failed` ("incorrect password"): filas **17, 19, 20, 22, 23, 25, 26, 27**. Éxito posterior: fila **28** (`login/success`, "login after multiple failures"), 1 min después del último fallo. | Las parejas 19/20, 22/23 y 25/26 son idénticas en todos los campos. Si fueran duplicados de registro quedarían **5 fallos, por debajo del umbral de 6**. El éxito es compatible con un compromiso de la cuenta, pero no lo prueba. |
| 2 | Password spraying probable | Media | R2 | 02:01–02:03 | 203.0.113.89 | ana, carlos, luisa, diego, maria, sofia (6 distintos) | 6 `login/failed` ("incorrect password"), uno por usuario: filas **67, 68, 70, 71, 73, 74**. | Esta IP no tiene ningún `login/success`, así que la severidad no sube. Los éxitos de esos usuarios en las filas 69 y 72 vienen de otra IP (192.0.2.10) y no se relacionan con esta. |
| 3 | Token potencialmente expuesto | Alta | R3 | 01:27 | 192.0.2.44 | api_service | Fila **33**: `debug/warning`, `detail` = `token=[REDACTED]; debug output`. | El log no indica si el token es válido o si sigue vigente. |
| 4 | Escalada no autorizada según el registro | Alta | R4 | 01:50 | 203.0.113.42 | guest | Fila **59**: `role_change/success`, `role=user->admin; approved=false`. | El log no dice quién ejecutó el cambio ni si se aprobó por otro canal. No se infiere intención. |

## Señales de contexto

- **Fila 57** (01:49, 203.0.113.42, guest): `access/denied` sobre `resource=/admin`, un minuto
  antes del cambio de rol de la alerta 4, con la misma IP y el mismo usuario. Ninguna regla
  lo cubre, así que es contexto y no una alerta aparte.
- **Fila 28:** el propio `detail` dice "login after multiple failures", lo que es
  coherente con la alerta 1.
- No aparecen otras claves sensibles (`password=`, `secret=`, `api_key=`, `authorization:`).
  "incorrect password" y "mistyped password" son texto descriptivo, sin ningún valor.

## Falsos positivos descartados

| Caso | Filas | Por qué no es alerta |
|---|---|---|
| 3 fallos de `maria` desde 192.0.2.25, seguidos de un éxito | 38, 39, 41 (éxito en la 42) | Son 3 `login/failed` y R1 exige **6 o más**. Ver la explicación más abajo. |
| `healthbot` desde 192.0.2.200, repetitivo | 78, 80, 81, 82, 83, 84 | Son eventos `healthcheck/success`, no `login/failed`. No cuentan para R1 ni R2, aunque se repitan desde la misma IP. |
| Fallos dispersos de `maria` desde 192.0.2.12 | 24 (01:17), 31 (01:25) | Hay 8 minutos entre ellos, así que no caben en una misma ventana de 5 minutos. Además solo son 2. |
| Fallos sueltos desde 192.0.2.10–13 | 3, 7, 14, 34, 46, 47, 51, 60, 87 | Ninguna pareja IP/usuario tiene más de 1 fallo en una ventana, y ninguna IP falla contra 5 o más usuarios en 5 minutos. |

Control de totales: 8 (alerta 1) + 6 (alerta 2) + 3 + 2 + 9 = **28 `login/failed`**, que
coincide con el total del archivo. No queda ningún fallo sin clasificar.

**Actividad normal:** el resto son `login/success` "ordinary login" desde 192.0.2.10–13.

### Por qué los 3 fallos aislados no son fuerza bruta

R1 define la fuerza bruta probable como **6 o más** `login/failed` de la misma IP al mismo
usuario dentro de 5 minutos. Las filas 38, 39 y 41 (192.0.2.25 → maria, 01:35–01:37) sí
están en la misma ventana, pero son **3**, la mitad del umbral. Además:

- el propio log las describe como `mistyped password`;
- les sigue enseguida un `login/success` (fila 42, "legitimate user"), lo que encaja con
  alguien que escribió mal la contraseña;
- no hay más intentos de esa IP.

Marcarlas como alerta sería un falso positivo. Un umbral solo es reproducible si se
aplica igual en todos los casos, sin bajarlo porque un patrón "se parezca" a un ataque.

## Verificación manual

Leí las filas citadas directamente en el CSV original con `awk` (número de línea real del
archivo, encabezado = 1). No usé el texto del modelo ni el script. Lo que sigue es lo que
devuelve el archivo para la **alerta 1**:

```text
17: 2026-11-05T01:14:00-05:00,198.51.100.77,admin,login,failed,incorrect password
19: 2026-11-05T01:15:00-05:00,198.51.100.77,admin,login,failed,incorrect password
20: 2026-11-05T01:15:00-05:00,198.51.100.77,admin,login,failed,incorrect password
22: 2026-11-05T01:16:00-05:00,198.51.100.77,admin,login,failed,incorrect password
23: 2026-11-05T01:16:00-05:00,198.51.100.77,admin,login,failed,incorrect password
25: 2026-11-05T01:17:00-05:00,198.51.100.77,admin,login,failed,incorrect password
26: 2026-11-05T01:17:00-05:00,198.51.100.77,admin,login,failed,incorrect password
27: 2026-11-05T01:18:00-05:00,198.51.100.77,admin,login,failed,incorrect password
28: 2026-11-05T01:19:00-05:00,198.51.100.77,admin,login,success,login after multiple failures
```

Las filas 18, 21 y 24, que quedan intercaladas, son de otras IP y usuarios
(carlos/success, maria/success, maria/failed desde 192.0.2.12). Por eso no cuentan.

Comprobaciones:

- 8 filas `login/failed` con la misma IP y el mismo usuario, entre 01:14 y 01:18
  (4 minutos, ≤ 5): **cumple R1**.
- La fila 28 es `login/success` de la misma IP y usuario, 1 minuto después del último
  fallo: **éxito posterior**.
- Las filas 19=20, 22=23 y 25=26 son idénticas. Se cuentan tal cual, como fija la
  convención, y se declara la limitación.

Con el mismo método comprobé también las alertas 2 (filas 67–74: los 6 fallos son de
203.0.113.89 y las filas 69 y 72 son de otra IP), 3 (fila 33) y 4 (filas 57 y 59), y los
descartes (filas 38–42 y 78–84). Todo coincide. Como tercera fuente independiente,
`scripts/analyze_logs.py` y un recuento propio en Python, escrito aparte, dan las mismas
filas.

## Incertidumbre y limitaciones

- **Filas idénticas (la más relevante):** no se puede saber si 19/20, 22/23 y 25/26 son
  intentos distintos dentro del mismo minuto o duplicados de registro. De eso depende
  que la alerta 1 supere el umbral (8 frente a 5). Conviene confirmarlo en la fuente
  antes de escalar. No inventé una regla de deduplicación.
- **Resolución de minuto:** el orden real dentro de un mismo minuto es incierto. Esto no
  afecta al "después" de las alertas 1 y 4, porque el éxito y el cambio de rol caen en un
  minuto posterior.
- **Lo que el log no dice:** si el token de la fila 33 es válido; quién ejecutó el cambio
  de rol de la fila 59 y si se aprobó por otra vía; si el éxito de la fila 28 fue del
  titular de `admin`.
- **El relato de las 02:17:** según el enunciado, "son las 02:17" cuando se ve la
  secuencia de fallos y éxito. En el CSV, la fila de las 02:17 (fila 85) es un
  `login/success` ordinario de ana. La secuencia de fallos seguida de un éxito está en
  01:14–01:19. No ajusté los datos al relato.
- **IP:** todas son de rangos de documentación (RFC 5737). No se consultaron ni se tratan
  como infraestructura real.
- **Sin regla propia:** `access/denied` (fila 57) y `debug/warning` (fila 33, salvo por
  R3) solo se usaron como contexto.
