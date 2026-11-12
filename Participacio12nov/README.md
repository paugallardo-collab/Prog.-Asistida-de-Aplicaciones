# Participación Semana 12: Cyber Detective (`incident-investigator`)

Agent Skill para investigar logs CSV de autenticación de forma reproducible. Cada alerta
cita las filas del CSV original, los secretos se redactan y nada se inventa. Probado con
Claude Code 2.1.322.

## Contenido

| Ruta | Qué es |
|---|---|
| [`incident-investigator/SKILL.md`](incident-investigator/SKILL.md) | El skill: `description` con señales de activación y de no activación, procedimiento en 6 pasos, cuándo abrir la referencia, formato de salida, seguridad |
| [`incident-investigator/references/detection-rules.md`](incident-investigator/references/detection-rules.md) | Reglas R1–R5, convenciones (ventana ≤ 5 min con los dos extremos incluidos, coincidencia exacta, numeración de filas, filas idénticas) y severidad orientativa |
| [`incident-investigator/scripts/analyze_logs.py`](incident-investigator/scripts/analyze_logs.py) | Opcional. Comprobación cruzada de solo lectura, sin dependencias, que redacta secretos y admite `--col` para CSV con otros nombres de columna |
| [`hallazgos.md`](hallazgos.md) | Informe de hallazgos con filas, verificación manual y por qué 3 fallos no son fuerza bruta |
| [`comparacion.md`](comparacion.md) | Misión 5: sin skill frente a con skill, en sesiones independientes |
| [`respuestas.md`](respuestas.md) | Misión 6: skill frente a plugin, y Ralph Loop |
| [`evidencias/`](evidencias/) | Trazas reales de las pruebas A, B, C (+ C2) y de la Misión 5. Ver su [README](evidencias/README.md) |
| `logs_sinteticos.csv` | Original sin modificar. SHA-256 `67ee039fcb45396bb9285fdcbc1430e45af52c5a1920c4dbd5f3eb9b92904756` |

## Instalación (Claude Code)

Claude Code descubre los skills de proyecto en `.claude/skills/<nombre>/SKILL.md`:

```bash
mkdir -p .claude/skills && cp -r incident-investigator .claude/skills/
```

Para comprobarlo, `incident-investigator` debe aparecer en la lista de skills de la
sesión (en modo `-p --output-format stream-json`, en el campo `skills` del evento `init`).

## Resultados de activación

| Prueba | Prompt (resumen) | ¿Se invocó `Skill`? | ¿Era lo esperado? |
|---|---|---|---|
| A: explícita | "Utiliza incident-investigator para investigar…" | Sí, y leyó `detection-rules.md` | Sí |
| B: contextual | "Revisa estos registros de autenticación… ¿intentos sospechosos…?" | **Sí, sin que se nombrara** | Sí |
| C: control negativo | "Cuántos eventos hay por hora…; no investigues" | No | Sí |
| C2: control extra | "¿Cuántos login fallidos hay por usuario?" | No | Sí |

### Misión 4: ajuste de `description`

**No hizo falta ajustarla.** B se activó y C no, al primer intento. Para no darlo por
bueno solo con C, que incluye la pista "no investigues", añadí el control C2: un conteo
de *logins fallidos*, cercano al dominio de seguridad, sin esa pista. Tampoco activó el
skill. La `description` ya tenía desde el diseño inicial:

- **Señales positivas** que nombran la tarea y el material: "investigar, auditar o revisar
  registros buscando intentos de acceso sospechosos…", con ejemplos de frases.
- **Límites explícitos:** "NO lo uses para conteos, estadísticas, agregaciones por hora o
  usuario, gráficos, limpieza o conversión…, ni cuando el usuario pida no investigar".

Si C2 hubiera activado el skill, el ajuste previsto era reforzar ese límite con un ejemplo
literal ("contar fallos por usuario es un conteo, no una investigación") y repetir C2 una vez.

## Cambios posteriores a las pruebas (revisión independiente con Codex)

Después de las pruebas pedí una segunda opinión a Codex (sesión de solo lectura). Confirmó
los hallazgos, las filas, los conteos y la `description`, y señaló tres defectos del
script que **no afectan a este CSV** pero sí a otros CSV compatibles. Los comprobé y los
corregí:

1. `analyze_logs.py` hacía `.strip()` de todos los campos, y eso rompía la *coincidencia
   exacta* (`" login"` contaba como `login`). Ahora no normaliza: las variantes con
   espacios se informan como limitación.
2. R4 normalizaba espacios y mayúsculas (`approved= false`). Ahora exige la subcadena
   literal y las variantes quedan como señal de contexto. La referencia lo aclara.
3. R2 consideraba "posterior" un éxito del mismo minuto aunque estuviera en una fila
   anterior. Ahora usa el orden estable `(timestamp, fila)`, igual que R1, y marca los
   empates de timestamp. La referencia lo aclara.

`SKILL.md` no cambió. Las pruebas A, B, C, C2 y la Misión 5 se hicieron con la versión
anterior del script y de esos dos párrafos de la referencia. Ejecuté el script corregido
sobre `logs_sinteticos.csv` y da **las mismas alertas, las mismas filas y los mismos
descartes**: la única diferencia son dos campos nuevos, vacíos
(`subsequent_success_same_timestamp_rows`). También lo probé con un CSV de casos límite.

**Segunda revisión de Codex** (sobre la rama ya confirmada). Señaló 7 puntos; los
comprobé todos y los corregí:

4. R1 excluía un éxito posterior si estaba en una fila anterior del archivo (CSV
   desordenado). Ahora usa el orden estable `(timestamp, fila)`.
5. Una fila con timestamp inválido quedaba fuera de R3/R4. Ahora R3 y R4 se evalúan
   siempre y se declara que el contexto temporal no es evaluable.
6. Mezclar fechas con y sin zona horaria hacía fallar el script (`TypeError`). Ahora las
   filas sin zona se excluyen de las ventanas y se informa la limitación.
7. El contexto de R4 podía incluir filas posteriores del mismo minuto. Ahora solo incluye
   las previas en el orden estable y marca los empates.
8. La redacción solo se aplicaba a `detail`. Ahora cubre toda la salida.
9. `comparacion.md` decía que la sesión con skill no usó "interno/externo", pero en una
   tabla escribió "IPs internas". Corregí la interpretación; la respuesta registrada no se
   tocó.
10. `evidencias/README.md` afirmaba un aislamiento de red que la configuración no
    demuestra. Lo cambié por lo comprobado: 0 comandos de red en las 6 trazas.

Con el script corregido, `logs_sinteticos.csv` sigue dando las mismas alertas, filas y
descartes; solo aparecen 3 campos nuevos vacíos. Probé además cada defecto con un CSV que
lo reproduce.
