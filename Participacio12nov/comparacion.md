# Comparación: sin skill frente a con skill (Misión 5)

## Condiciones del experimento

- **Dos sesiones independientes**, cada una con su propio proceso `claude -p`, sin
  `--continue` ni `--resume` y con `--no-session-persistence`. Ids de sesión:
  sin skill `aee2f87d-…`, con skill `f4375b52-…`.
- **El mismo prompt**, el mismo CSV (mismo SHA-256), el mismo modelo (`claude-opus-5-5`,
  effort `high`) y las mismas herramientas (`Read, Glob, Grep, Bash, Skill`, sin red ni MCP).
- **Sin skill:** carpeta con solo el CSV. `incident-investigator` no aparece en
  `init.skills`, y no había `SKILL.md`, `detection-rules.md` ni script.
- **Con skill:** carpeta idéntica más `.claude/skills/incident-investigator/`. La traza
  confirma que el skill se invocó y que se leyó la referencia.
- Las trazas están en [`evidencias/mision5_sin_skill.md`](evidencias/mision5_sin_skill.md)
  y [`evidencias/mision5_con_skill.md`](evidencias/mision5_con_skill.md).

> Prompt: *«Investiga los logs sintéticos, identifica incidentes justificables y distingue
> señales de seguridad de actividad normal. Devuelve evidencia concreta.»*

## Tabla comparativa

| Dimensión | Sin skill | Con skill | Evidencia / comentario |
|---|---|---|---|
| ¿Usó un procedimiento reproducible? | **Parcial.** Leyó el CSV e hizo una agregación ad hoc por IP, usuario y resultado. No fijó umbrales ni ventanas: decidió cada incidente con un razonamiento narrativo ("ritmo de ~2 intentos/min", "ritmo humano"). | **Sí.** Siguió los pasos del skill: inspeccionó columnas y valores de `event/result`, comprobó el orden, leyó `detection-rules.md`, aplicó R1–R5 (incluidas las que no dan alerta), verificó a mano, cruzó con el script y usó el formato fijo. | Con otro CSV, la versión con skill aplicaría los mismos criterios. En la versión sin skill, el criterio depende de cómo razone el modelo en cada corrida. |
| ¿Citó filas concretas? | **En los 4 incidentes, sí**, y son correctas (17–28, 33, 57/59, 67–74). **En los descartes, no siempre:** healthbot sin filas, y "11 fallos sueltos" con un conteo por usuario pero sin filas. | **Sí, también en los descartes:** 38/39/41 (+42), 78/80–84, 24/31, y los 9 fallos sueltos (3, 7, 14, 34, 46, 47, 51, 60, 87). | Comprobé las filas de las dos respuestas contra el CSV (ver `hallazgos.md`). Ninguna de las dos citó filas inexistentes. |
| Alertas sustentadas | Las mismas 4. Severidades sin criterio declarado (CRÍTICO, ALTO, MEDIO). Añadió afirmaciones que el log no sostiene: "IP **externa**, fuera del rango interno 192.0.2.x", "sugiere **enumeración previa**", y recomendó **bloquear las IP**. Bajó el token a MEDIO "porque el valor es de demostración", es decir, razonó a partir del contenido del secreto. | Las mismas 4, cada una con su regla (R1–R4), su severidad según la tabla de la referencia y su limitación. Trató todas las IP como direcciones de documentación (RFC 5737), sin distinguir "internas" de "externas". | Detectar los incidentes no fue la diferencia: este CSV es fácil. La diferencia es cuánto de cada afirmación sale de una regla y cuánto de una suposición. |
| Falsos positivos detectados o evitados | Descartó bien maria/192.0.2.25, healthbot y los fallos sueltos, pero por intuición y sin aplicar un umbral. **No detectó las filas idénticas** (19/20, 22/23, 25/26) y describió los 8 fallos como "8 seguidos". | Descartó los mismos casos aplicando el umbral (3 < 6; `healthcheck` ≠ `login/failed`; 8 min > ventana). **Señaló que la alerta R1 depende de las filas idénticas: si fueran duplicados quedarían 5 fallos, por debajo del umbral de 6.** | Es el matiz más fino del archivo, y solo lo vio la versión con skill, gracias a la convención de filas idénticas de la referencia. |
| ¿Ocultó posibles tokens? | **No.** Su respuesta final incluía el valor completo de `token=` en la fila 33. Lo comprobé en la traza cruda; en el PR aparece redactado por mí. | **Sí.** Escribió `token=[REDACTED]`. Además redactó el CSV con `sed` *antes* de leerlo, así que el valor no aparece ni una vez en su traza cruda. | Fue la diferencia más concreta y verificable. Es justo lo que pide la regla 3 de seguridad del skill. |
| ¿Reconoció incertidumbre? | **Poco.** Dijo que el log no muestra qué pasó tras el acceso a `admin` y que la "campaña" es una hipótesis. No mencionó la resolución de minuto ni los duplicados, y dio por buenas las IP como "internas/externas". | **Sí, en una sección propia:** filas idénticas, resolución de minuto (indicando cuándo afecta y cuándo no), validez del token, quién hizo el cambio de rol y si se aprobó por otra vía, "no es una conclusión forense". | — |
| ¿Qué hizo gracias al skill? | — | Se activó **sin que el prompt lo nombrara**. Leyó la referencia, aplicó umbrales explícitos, hizo la verificación cruzada con el script, redactó el CSV antes de leerlo, siguió el formato estándar y no atribuyó culpa. | Se ve en la secuencia de la traza: `Skill` → `Read detection-rules.md` → `Read analyze_logs.py` → lectura redactada → `Bash analyze_logs.py`. |

### Algo que la sesión sin skill hizo mejor

La versión sin skill aportó dos observaciones correctas que la versión con skill no
mencionó:

1. **`guest` no tiene ningún `login` registrado** antes del `access/denied` (fila 57) y el
   `role_change` (fila 59).
2. **El rol de origen figura como `user`** aunque la cuenta se llama `guest`.

También dio una cronología y recomendaciones de respuesta. Las recomendaciones quedan
fuera del alcance del skill y en parte se basaban en tratar las IP como reales.

## Qué aportó el skill en concreto

En orden de importancia, con su evidencia:

1. **Contener la filtración del secreto.** Sin skill, el token se imprimió completo. Con
   skill no llegó ni al contexto del modelo. Es una mejora de seguridad real y binaria, no
   estética.
2. **La referencia (`detection-rules.md`)** cambió el resultado: convirtió "parece un
   ataque" en "cumple R1 (≥ 6 en ≤ 5 min)". Gracias a la convención de filas idénticas
   salió a la luz que la alerta principal depende de si 19/20, 22/23 y 25/26 son
   duplicados (8 frente a 5). Sin la referencia no se detectó.
3. **El procedimiento** hizo que se reportaran también los resultados negativos con filas
   (los 28 `login/failed` quedan clasificados) y que se verificara contra el CSV y el
   script.
4. **La contención de invenciones:** no se atribuyó "interno/externo" a IP ficticias, no se
   habló de enumeración ni se recomendó bloquear direcciones de documentación.
5. **La activación:** se activó sola en B y en la Misión 5 y no se activó en los
   controles C y C2 (ver `evidencias/`).
6. **El formato** hace comparables las respuestas entre corridas (A, B y la Misión 5 dieron
   la misma tabla). Por sí solo es lo menos importante.

**Lo que no aportó:** la *detección* de los 4 incidentes. El modelo sin skill también los
encontró, con filas correctas. En un CSV tan pequeño y con señales tan claras
("login after multiple failures", `approved=false`), el valor del skill está en el
rigor, la seguridad y la reproducibilidad, no en encontrar más cosas.

**Qué cambiaría:** añadiría a R4 una comprobación de contexto, "¿hay un `login` previo del
mismo usuario?, ¿el rol de origen coincide con la cuenta?", porque es lo que la versión
sin skill vio y la versión con skill pasó por alto. No lo cambié después del experimento
para no alterar la versión evaluada.

## Coste y tiempo

| Métrica | Sin skill | Con skill | Fiabilidad |
|---|---|---|---|
| Tokens de salida | 4 538 | 5 515 | Dato de la API en el evento `result`. Fiable. |
| Turnos del agente | 6 | 10 | Contados en la traza. |
| Coste estimado (USD) | 0,26 | 0,33 | Estimación del propio CLI (`total_cost_usd`). Orientativo. |
| Tiempo | no disponible | no disponible | Las corridas se lanzaron en paralelo y el `duration_ms` que reportaron (~5,4 M ms) no corresponde al tiempo real, que fueron minutos. No lo considero fiable. |

El skill cuesta más (≈ +20 % de tokens de salida y más turnos) porque carga y aplica las
instrucciones, lee la referencia y verifica.

## Límites de esta comparación

- Es **una corrida por condición**: una comparación didáctica, no una prueba estadística.
  Otra corrida sin skill podría haber redactado el token, o no.
- El prompt no pedía ocultar secretos. Lo que se mide es la conducta **por defecto** de
  cada condición.
- Dentro de la misma sesión, las alertas de la versión con skill coinciden con el script
  del skill. Por eso la verificación independiente de las filas es la mía (`hallazgos.md`),
  no la del agente.
