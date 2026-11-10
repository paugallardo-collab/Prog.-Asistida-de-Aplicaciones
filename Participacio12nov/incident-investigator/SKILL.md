---
name: incident-investigator
description: >-
  Investiga incidentes de seguridad en logs CSV sintéticos o de práctica de autenticación y
  acceso (columnas tipo timestamp, ip, user, event, result, detail) aplicando reglas
  documentadas: fuerza bruta, password spraying, tokens o secretos expuestos en el detalle,
  cambios de rol no aprobados y descarte de falsos positivos. Devuelve alertas justificadas
  con números de fila del CSV original, severidad orientativa y limitaciones. Úsalo cuando
  se pida investigar, auditar o revisar registros buscando intentos de acceso sospechosos,
  ataques, accesos o escaladas no autorizadas, secretos filtrados o actividad anómala
  (p. ej. "¿alguien entró al sistema?", "revisa estos logs de autenticación"). NO lo uses
  para conteos, estadísticas, agregaciones por hora o usuario, gráficos, limpieza o
  conversión del CSV sin investigación de incidentes, ni cuando el usuario pida no
  investigar ni clasificar amenazas.
---

# incident-investigator

Guía para investigar, de forma **reproducible y sin inventar nada**, registros CSV de
autenticación y seguridad. El resultado son **alertas justificadas por filas**, no
conclusiones forenses ni atribuciones de culpa.

## 1. Cuándo usar este skill y cuándo no

**Úsalo** si la petición pide investigar o juzgar seguridad sobre un log tabular:
intentos sospechosos, fuerza bruta, spraying, accesos o cambios de privilegios no
aprobados, secretos o tokens expuestos, "¿hubo un incidente?", "¿qué pasó a las 02:17?".

**No lo uses** (responde la petición de forma normal, sin clasificar amenazas) si solo se
pide:

- contar o agregar eventos (por hora, por usuario, por IP, por tipo de evento);
- visualizar, graficar, resumir columnas, convertir de formato o limpiar el archivo;
- explicar qué significa una columna;
- o el usuario dice expresamente que **no** investigue incidentes ni clasifique amenazas.

Si la petición mezcla ambas cosas, aplica el skill solo a la parte de investigación.

**Fuera de alcance — detente y avisa:** logs reales de producción con datos personales,
peticiones de atribuir autoría o culpa a una persona, o de consultar IPs/dominios en
servicios externos.

## 2. Reglas de seguridad (siempre)

1. **Solo lectura.** No modifiques, reordenes ni sobrescribas el CSV original. Si
   necesitas ordenar, hazlo en memoria o en una salida aparte.
2. **Sin red.** No consultes IPs, dominios ni servicios de reputación/geolocalización.
   Las IP de los rangos de documentación (`192.0.2.0/24`, `198.51.100.0/24`,
   `203.0.113.0/24`, RFC 5737) son ficticias: nunca las trates como infraestructura real.
3. **Nunca muestres secretos.** Cualquier valor tras `token=` (y también `password=`,
   `secret=`, `api_key=`, `apikey=`, `authorization:`) se escribe como `[REDACTED]`, sin
   prefijo, sufijo ni longitud. Esto aplica al informe, a tablas, a citas de filas y a la
   salida de comandos que reproduzcas (no pegues la línea cruda: redáctala antes).
4. **No inventes eventos, filas ni contexto.** Cada afirmación debe poder rastrearse a
   filas concretas. Si algo no está en el archivo, dilo ("no hay evidencia en el log").
5. **No infieras culpabilidad ni intención.** Escribe "según el registro", "compatible
   con", "probable". El log describe eventos, no personas culpables.

## 3. Procedimiento

Sigue los pasos en orden. No saltes al informe sin completar los pasos 1–4.

### Paso 1 — Inspeccionar columnas y formato

- Identifica el archivo (si hay varios CSV candidatos, di cuál analizas o pregunta).
- Lee el encabezado y confirma las columnas `timestamp, ip, user, event, result, detail`.
  Si los nombres difieren (p. ej. `src_ip`, `username`, `action`, `status`), declara el
  mapeo explícitamente antes de seguir. Si falta una columna imprescindible para una
  regla, esa regla queda **no evaluable** (dilo en limitaciones).
- Cuenta las filas de datos, revisa el formato de `timestamp` y su zona horaria, y lista
  los valores distintos de `event` y `result` (para detectar variantes como `Failed` o
  `login_failed` que **no** coinciden exactamente).
- Comprueba si el archivo ya está ordenado por `timestamp` y si hay filas idénticas.
- Numeración: **fila = número de línea del CSV original; el encabezado es la fila 1**
  (la primera fila de datos es la 2). Si algún campo entrecomillado contiene saltos de
  línea, usa la línea donde empieza el registro y anótalo como limitación.

### Paso 2 — Leer las reglas de detección

**Antes de evaluar cualquier alerta, abre y lee
[`references/detection-rules.md`](references/detection-rules.md).** Es la fuente de verdad
para umbrales, ventanas, criterios de coincidencia, severidades y falsos positivos. No
apliques umbrales de memoria ni los ajustes "a ojo" para que salga una alerta.

Vuelve a consultarla cuando: dudes si un caso alcanza un umbral, encuentres un tipo de
evento no previsto, aparezcan filas idénticas o timestamps empatados, o vayas a asignar
severidad.

### Paso 3 — Analizar la evidencia

- Ordena los eventos por `timestamp` (orden estable: ante empate, conserva el orden de
  fila original) antes de revisar ventanas.
- Aplica **cada** regla de la referencia (R1–R5) y registra también las que **no**
  producen alerta: un resultado negativo es información.
- Herramienta opcional: `python scripts/analyze_logs.py <archivo.csv>` (solo biblioteca
  estándar, solo lectura, redacta secretos) aplica las mismas reglas y lista filas. Úsala
  como **comprobación cruzada**, no como sustituto del razonamiento: si su resultado y tu
  análisis discrepan, investiga la discrepancia y repórtala. Si Python no está
  disponible, haz el análisis con las herramientas de lectura/búsqueda del agente.
- **Verifica cada alerta contra las filas originales** (lee esas líneas concretas del
  archivo) antes de reportarla.

### Paso 4 — Distinguir alerta de hecho confirmado

Clasifica cada hallazgo en una de estas categorías y no las mezcles:

| Categoría | Significado |
|---|---|
| **Alerta** | Cumple literalmente una regla de la referencia. Sigue siendo una alerta, no un hecho forense. |
| **Señal de contexto** | No cumple una regla, pero es relevante para interpretar una alerta (p. ej. un acceso denegado previo del mismo usuario). |
| **Falso positivo descartado** | Parece sospechoso pero no alcanza el umbral o no es el tipo de evento correcto. Explica por qué. |
| **Actividad normal** | Resto de eventos; resúmela en una línea, sin enumerarla. |

Lo **confirmado** es solo lo que el registro dice literalmente (p. ej. "hay 8 filas
`login/failed` de la IP X al usuario Y entre T1 y T2"). La **interpretación** ("fuerza
bruta probable", "posible compromiso de cuenta") debe marcarse como tal.

### Paso 5 — Reportar con el formato estándar

Usa exactamente esta estructura (en el idioma del usuario):

```markdown
## Resumen
Archivo, nº de filas de datos, rango temporal, zona horaria, columnas y mapeo usado.
Reglas evaluadas y cuántas produjeron alerta.

## Alertas
| # | Alerta | Severidad orientativa | Regla | Timestamp (inicio–fin) | IP | Usuario(s) | Filas / evidencia | Limitaciones |
|---|---|---|---|---|---|---|---|---|

## Señales de contexto
- (fila N) descripción breve y con qué alerta se relaciona.

## Falsos positivos descartados
| Caso | Filas | Por qué no es alerta |
|---|---|---|

## Verificación
Qué filas se comprobaron leyendo el CSV original y con qué método
(herramienta de lectura, script auxiliar, ambos). Discrepancias encontradas.

## Incertidumbre y limitaciones
Resolución temporal, filas idénticas, columnas ausentes, eventos no cubiertos por reglas,
y que una corrida no es una conclusión forense.
```

Reglas del formato: filas como números individuales o rangos explícitos
(`17, 19, 20` o `67–68, 70–71`), nunca "varias filas"; secretos siempre `[REDACTED]`;
la columna *Limitaciones* nunca vacía (si no hay, escribe "ninguna adicional").

### Paso 6 — Declarar la incertidumbre

Siempre cierra indicando lo que **no** puedes saber con este log: si filas idénticas son
eventos distintos o duplicados de registro, el orden real dentro del mismo minuto, si un
cambio de rol se aprobó por otro canal, si un token sigue siendo válido, etc. No
"resuelvas" estas dudas inventando reglas nuevas.

## 4. Lista de comprobación antes de responder

- [ ] Leí `references/detection-rules.md` en esta tarea.
- [ ] Cada alerta cita filas del CSV original y la regla exacta que cumple.
- [ ] Revisé y expliqué los casos por debajo del umbral y los eventos no-login.
- [ ] Ningún valor de secreto aparece en la respuesta (solo `[REDACTED]`).
- [ ] No consulté la red ni modifiqué el CSV.
- [ ] Marqué la incertidumbre y no atribuí culpa.
