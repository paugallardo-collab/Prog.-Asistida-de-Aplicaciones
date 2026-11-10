# Reglas de detección — incident-investigator

Fuente de verdad para umbrales y criterios. `SKILL.md` indica **cuándo** leer este
archivo; aquí está **qué** contar y **cómo**. Los resultados son **alertas
justificadas**, no conclusiones forenses.

## 0. Convenciones comunes (aplican a todas las reglas)

| Convención | Definición |
|---|---|
| **Numeración de filas** | Número de línea del CSV original. El encabezado es la fila 1; el primer registro, la fila 2. Cita siempre estas filas, nunca índices de un DataFrame ordenado. |
| **Orden** | Ordena por `timestamp` (orden estable: ante empate, conserva el orden de fila original) **antes** de revisar ventanas. No reescribas el archivo. |
| **Ventana** | Duración **≤ 5 minutos incluyendo ambos extremos**: un evento en `t` y otro en `t + 5:00` caen en la misma ventana; uno en `t + 5:01`, no. Las ventanas son deslizantes: se prueban ancladas en cada evento candidato y se reporta la que contiene más eventos (primer y último timestamp). |
| **Coincidencia exacta** | Solo cuentan eventos cuyos campos `event` y `result` coinciden **exactamente** con el valor de la regla (`login` + `failed`). Variantes (`Failed`, `login_failed`, `failure`) **no** se cuentan en silencio: se mencionan en limitaciones. |
| **Misma IP / mismo usuario** | Igualdad exacta del texto de `ip` y de `user`. |
| **Filas idénticas** | Si varias filas tienen todos los campos iguales, **no** se eliminan ni se fusionan: no hay forma inequívoca de saber si son eventos distintos dentro del mismo minuto o duplicados de registro. Se cuentan tal como aparecen y se informa, como limitación, cuántos eventos quedarían si fueran duplicados y si la alerta seguiría superando el umbral. No inventes una regla de deduplicación. |
| **Resolución temporal** | Si los timestamps tienen resolución de minuto, el orden dentro del mismo minuto es incierto; dilo cuando afecte a "antes/después". |
| **Secretos** | Nunca se imprime el valor; se escribe `[REDACTED]`. |
| **Lenguaje** | "probable", "según el registro", "compatible con". Nunca culpabilidad. |

## R1 — Fuerza bruta probable

- **Condición:** **6 o más** eventos `login`/`failed` desde la **misma `ip`** hacia el
  **mismo `user`** dentro de una ventana de 5 minutos.
- **Cómo evaluar:** agrupa `login/failed` por `(ip, user)`; para cada grupo, ancla una
  ventana en cada evento y cuenta los eventos con `t_ancla ≤ t ≤ t_ancla + 5 min`.
  Alerta si el máximo es ≥ 6.
- **Anotación aparte (no cambia la condición):** comprueba si existe un `login`/`success`
  de la **misma `ip`** al **mismo `user`** en los **5 minutos siguientes al último fallo**
  de la ventana (`t_último ≤ t ≤ t_último + 5 min` y fila posterior). Si existe, cítalo
  como "éxito posterior" en una fila separada de la tabla o en la columna de evidencia.
  Un éxito posterior **no prueba** que la cuenta esté comprometida; es compatible con ello
  y también con que el titular recordara la contraseña.
- **Severidad orientativa:** media; **alta** si hay éxito posterior.
- **Evidencia a citar:** todas las filas de fallo de la ventana, la fila del éxito
  posterior (si existe), primer y último timestamp, nº de fallos.

## R2 — Password spraying probable

- **Condición:** eventos `login`/`failed` desde la **misma `ip`** contra **al menos 5
  usuarios distintos** dentro de una ventana de 5 minutos.
- **Cómo evaluar:** agrupa `login/failed` por `ip`; para cada ventana anclada cuenta
  usuarios **distintos** (no eventos). Alerta si el máximo es ≥ 5.
- **Comprobaciones adicionales:** lista los usuarios afectados; indica si hay algún
  `login/success` desde esa misma IP **posterior al último fallo** de la ventana (señal
  de contexto que eleva la severidad). "Posterior" se decide con el orden estable
  `(timestamp, fila)`: un éxito en una fila anterior no cuenta, aunque comparta minuto. Si
  comparte timestamp con el último fallo, indícalo como orden incierto (lo mismo en R1).
- **Severidad orientativa:** media; **alta** si la misma IP obtiene un éxito posterior.
- **Evidencia a citar:** filas de cada intento, lista de usuarios, ventana.

## R3 — Token potencialmente expuesto

- **Condición:** el campo `detail` contiene la subcadena `token=` (sin distinguir
  mayúsculas).
- **Redacción obligatoria:** sustituye el valor (desde `=` hasta `;`, espacio, coma o fin
  de campo) por `[REDACTED]`. Ejemplo: `token=[REDACTED]; debug output`. No reveles
  longitud, prefijo ni si "parece" de prueba.
- **Otras claves** (`password=`, `secret=`, `api_key=`, `apikey=`, `authorization:`): no
  forman parte de R3, pero se redactan igual y se reportan como **señal de contexto**
  ("posible secreto fuera de regla").
- **Severidad orientativa:** alta (exposición de credencial en logs), con la limitación
  de que el log no indica si el token es válido.
- **Evidencia a citar:** fila, timestamp, `ip`, `user`, `event/result`, `detail` redactado.

## R4 — Escalada no autorizada según el registro

- **Condición:** `event = role_change`, `result = success` y `detail` contiene la
  subcadena literal `approved=false`. Las variantes (`approved= false`, `APPROVED=FALSE`) no
  cumplen la regla: se reportan como señal de contexto, para revisión humana.
- **Cómo reportar:** cita el cambio de rol tal como aparece (p. ej. `role=user->admin`).
  Revisa eventos del mismo `user` o la misma `ip` en los minutos previos (p. ej. `access`
  `denied` a recursos administrativos) y repórtalos como **señales de contexto**, no como
  alertas independientes.
- **No inferir:** ni culpabilidad, ni que el usuario lo hiciera intencionadamente, ni
  quién ejecutó el cambio si el log no lo dice. Redacta: "según el registro, el cambio
  figura como no aprobado".
- **Severidad orientativa:** alta.
- **Evidencia a citar:** fila del cambio, filas de contexto.

## R5 — Falsos positivos (comprobación obligatoria)

Estos casos se **reportan como descartados**, con su explicación:

- **Fallos aislados bajo el umbral:** 3 (o cualquier número < 6) `login/failed` de la
  misma IP al mismo usuario **no** son fuerza bruta según R1, aunque estén seguidos de un
  éxito. Cita sus filas y el conteo.
- **Healthcheck:** un evento `healthcheck` (de cualquier resultado) **no** es un
  `login/failed` y no cuenta para R1 ni R2, aunque sea repetitivo y de la misma IP.
- **Spraying bajo el umbral:** fallos de una IP contra < 5 usuarios distintos en la
  ventana.
- **Fallos dispersos:** fallos de la misma IP/usuario separados más de 5 minutos no se
  suman en una misma ventana.

## Eventos no cubiertos por las reglas

Si aparecen eventos que ninguna regla contempla (p. ej. `debug` sin secretos, `access
denied`, `logout`), **no crees una regla nueva**: menciónalos como señal de contexto si son
relevantes o como "no evaluado por las reglas" en limitaciones.

## Tabla resumen de severidad orientativa

| Regla | Base | Se eleva a |
|---|---|---|
| R1 Fuerza bruta | media | alta con éxito posterior |
| R2 Spraying | media | alta con éxito posterior desde la IP |
| R3 Token expuesto | alta | — |
| R4 Cambio de rol no aprobado | alta | — |
| R5 Falso positivo | informativa (no es alerta) | — |

La severidad es **orientativa** para priorizar la revisión humana; no es un veredicto.
