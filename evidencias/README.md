# Evidencias y últimos pasos

## Verificaciones realizadas

- `pytest.txt`: salida real de pytest, con 25 pruebas aprobadas.
- `mcp_stdio.json`: discovery y respuestas reales del servidor mediante el cliente MCP del SDK. Comprueba D1–D7, caso inexistente al registrar, tipo inválido y registro tras reiniciar el proceso.
- La traza anterior es una prueba cliente-servidor sin LLM. No se presenta como captura del Inspector ni como traza de un agente conectado.
- `parte1_server.png`: captura original aportada por la estudiante con las tres herramientas del servidor.
- `pytest.png`: captura original de la ejecución en el equipo de la estudiante, con 25 pruebas aprobadas y una advertencia.
- `inspector_tools.png`: captura original del Inspector conectado, con discovery de exactamente las tres herramientas y la llamada `tools/list` en el historial.
- `inspector_pruebas.png`: primera captura de resultados del Inspector (D1); muestra INC-001, INC-002 e INC-003 con cantidades 2, 6 y 5.
- `inspector_d2_1.png` a `inspector_d2_4.png`: capturas originales de D2 con los seis eventos de INC-002, de 02:10 a 02:15, usuario admin, IP de documentación 203.0.113.25 y LOGIN_FAILED.
- `inspector_d3.png`: captura de D3 con `consultar_eventos`, argumento INC-999 y error explícito de caso inexistente.
- `inspector_d4.png`: captura de D4 con INC-003, nivel alto, motivo y confirmación con estado registrada.
- `inspector_d5.png`: captura de D5 al repetir el registro anterior sin reiniciar, con error explícito de alerta duplicada para INC-003.
- `inspector_d6.png`: captura de D6 con INC-002, nivel critico y motivo Intentos repetidos; el servidor rechaza el nivel y enumera bajo, medio o alto.
- `inspector_d7.png`: captura de D7 con INC-002, nivel medio y motivo en blanco; el servidor rechaza el motivo con un mensaje explícito.
- `inspector_reinicio.png`: captura de la Parte 2c, después de detener y volver a iniciar el servidor siguiendo las instrucciones; INC-003 vuelve a aceptar el mismo registro válido, con estado registrada.
- `agente_tools.png`, `agente_listar_2.png` y `agente_listar_3.png`: capturas originales de la conversación nueva de Codex «Investiga casos con MCP Detective», con la llamada real Listar casos expandida y los resultados de los tres casos. No se incluyó la captura que repetía el resultado en formato JSON.
- `agente_error_999.png`: llamada real de Claude Code a `consultar_eventos` con `{"caso_id":"INC-999"}` y error del servidor visible en OUT; el agente comunica el error sin inventar eventos.

## Capturas pendientes

Las capturas incluidas se conservaron sin modificar y corresponden a las comprobaciones solicitadas. D1–D7 y el reinicio (2c) ya tienen capturas. La evidencia del agente está iniciada con el listado de casos; falta completar las demás llamadas antes de entregar:

| Archivo obligatorio | Qué debe verse |
|---|---|
| Llamadas pendientes del agente | Capturas de `consultar_eventos` para los tres casos y `registrar_alerta` para INC-003, con argumentos y resultados visibles. El listado ya está en `agente_tools.png` y sus dos continuaciones; el error de INC-999 está en `agente_error_999.png`. |

No mostrar tokens de sesión del Inspector, contraseñas ni otras credenciales. El enunciado no solicita grabaciones.

## Parte 3: conversación nueva

La configuración local de Codex puede generarse con `configurar_codex.py`, como explica el README principal. Esta conversación de implementación ya conoció el enunciado y no sirve para afirmar una investigación independiente.

En una conversación nueva en la carpeta del proyecto, enviar:

> Usa únicamente las herramientas MCP del servidor mcp_detective para esta investigación. No abras casos.json ni consultes archivos, terminal, búsquedas del repositorio, pruebas o respuestas.md para obtener eventos. Descubre las herramientas disponibles. Descubre qué casos hay, consulta los eventos de cada uno y muéstrame la evidencia con sus horas, usuarios e IP. No clasifiques un caso antes de consultar sus eventos.

Después:

> Basándote exclusivamente en los eventos que acabas de obtener con las tools MCP, registra una alerta para INC-003 con un nivel justificado. Explica los límites de esa evidencia sin afirmar con certeza una intrusión. Ejecuta realmente registrar_alerta y muestra sus argumentos y resultado.

Finalmente:

> Consulta INC-999 mediante consultar_eventos. Comunica el error real del servidor sin inventar eventos.

Guardar las capturas de las llamadas expandidas y actualizar en `respuestas.md` el estado de conexión para reflejar lo que efectivamente se realizó.

## Subir las capturas al mismo PR

En este equipo, el checkout aislado de la rama `deber5` está en `.entrega/`. Copiar las capturas a `.entrega/evidencias/` y actualizar allí `respuestas.md` y esta lista de pendientes. Desde la carpeta de trabajo:

```powershell
Copy-Item evidencias\*.png .entrega\evidencias\
git -C .entrega add evidencias/ respuestas.md
git -C .entrega commit -m "docs: agrega evidencias del Inspector y del agente"
git -C .entrega push
```

Si se trabaja desde otro clon del repositorio, cambiar a `deber5`, guardar allí las evidencias, hacer commit y push. El PR abierto se actualizará automáticamente. Entregar en el aula solo el enlace al PR.
