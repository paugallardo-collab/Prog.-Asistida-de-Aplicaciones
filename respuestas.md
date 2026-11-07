# Deber 5 — MCP Detective

## 1. Arquitectura

El LLM decide qué herramienta necesita y propone sus argumentos. El host (Codex o Claude Code) organiza la conversación, ofrece las herramientas al modelo y coordina su ejecución. El cliente MCP transporta las solicitudes y respuestas entre el host y el servidor. El servidor MCP ejecuta las funciones de Python: lee los casos, valida los argumentos y conserva las alertas en memoria. Quien ejecuta Python es el proceso local del servidor, iniciado por el host; el modelo interpreta sus resultados.

`listar_casos` y `consultar_eventos` solo leen. `registrar_alerta` cambia el estado de la instancia. Las tres herramientas se registran mediante `@mcp.tool()` en `mcp-detective/server.py`.

## 2. Evidencia y límites

El patrón de INC-003 merece investigación: el conjunto de datos del ejercicio muestra cuatro accesos fallidos de `admin`, de 03:00 a 03:03, y un acceso exitoso a las 03:04 desde la misma IP de documentación, `192.0.2.50`, en el panel de administración. Justifica una prioridad alta de revisión por la cuenta y el sistema involucrados. No demuestra una intrusión: los registros no identifican a la persona detrás de la cuenta ni explican si estaba autorizada. Un usuario legítimo también puede equivocarse antes de iniciar sesión. Haría falta corroborar el contexto y la actividad posterior.

Esta explicación se basa en el enunciado y sirve de reflexión. La investigación de la Parte 3 debe repetirse en una conversación nueva obteniendo los eventos únicamente mediante MCP; no se presenta esta reflexión como prueba de esa investigación.

## 3. Validación y seguridad

El servidor rechaza los casos inexistentes, los niveles distintos de `bajo`, `medio` o `alto`, los motivos que no son texto o quedan en blanco y las alertas duplicadas. La lógica lanza `ValueError` antes de guardar. No basta con confiar en el LLM: puede equivocarse en los argumentos, y otro cliente puede enviar datos inválidos. El servidor garantiza el contrato de forma determinista, incluida una sola alerta por caso durante la vida del proceso, algo que una respuesta del modelo por sí sola no garantiza.

Con el SDK 2.3.0, las tools traducen los `ValueError` previstos a `ToolError` para que MCP conserve el mensaje comprensible y marque `is_error=True`. Sin esta adaptación, el SDK oculta el detalle como error inesperado. No se devuelven confirmaciones falsas ni listas vacías por un caso desconocido. Las alertas no se escriben en disco; un proceso nuevo empieza sin ellas.

## Agente, conexión y reproducción

Se utilizó **OpenAI Codex en VS Code** para implementar y verificar el proyecto. El cliente Python del SDK comprobó discovery de exactamente tres herramientas y llamadas reales por `stdio`; su traza está en [evidencias/mcp_stdio.json](evidencias/mcp_stdio.json). Ese cliente no usa un LLM. En la conversación nueva «Investiga casos con MCP Detective», Codex ejecutó Listar casos, como muestran [agente_tools.png](evidencias/agente_tools.png) y sus continuaciones. La investigación se continuó en una sesión nueva de **Claude Code en VS Code**, con el mismo servidor configurado por stdio en `.mcp.json`. Se comprobó la conexión mediante `/mcp` y llamadas reales: [agente_error_999.png](evidencias/agente_error_999.png) muestra nombre, argumento y error de INC-999, sin eventos inventados. [agente_alerta_1.png](evidencias/agente_alerta_1.png) muestra la llamada de registro para INC-003 y [agente_alerta_2.png](evidencias/agente_alerta_2.png) muestra su resultado original con estado registrada. Falta incorporar las capturas de las consultas de los tres casos para completar la evidencia visual.

Instalación, desde la raíz de esta entrega, con Python 3.11+ y Node.js:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m pytest mcp-detective -q
.\.venv\Scripts\python.exe mcp-detective\verificar_mcp.py
.\.venv\Scripts\mcp.exe dev mcp-detective/server.py
```

Para conectar Codex, ejecutar `.\.venv\Scripts\python.exe configurar_codex.py` y abrir una conversación nueva en esta carpeta. La configuración local contiene las rutas absolutas del Python activo y de `server.py`, sin credenciales. El host debe cargar la configuración del proyecto de confianza. Comprobar `/mcp` y pedir discovery; luego verificar las invocaciones con nombre, argumentos y resultado. Los prompts y la lista exacta de capturas están en [evidencias/README.md](evidencias/README.md).

Referencias consultadas: [SDK MCP v2](https://py.sdk.modelcontextprotocol.io/), [errores del SDK](https://py.sdk.modelcontextprotocol.io/servers/handling-errors/) y [configuración MCP de Codex](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).

Para conectar **Claude Code**, desde la carpeta de la entrega:

```powershell
$pythonMcp = (Resolve-Path .venv/Scripts/python.exe).Path
$servidorMcp = (Resolve-Path mcp-detective/server.py).Path
claude mcp add --transport stdio --scope project mcp_detective $pythonMcp $servidorMcp
```

Abrir una conversación nueva de Claude Code, aprobar el servidor del proyecto cuando lo solicite y verificar `/mcp`: debe mostrar `mcp_detective` conectado. Obtener la evidencia únicamente mediante las herramientas MCP. [Documentación de Claude Code](https://code.claude.com/docs/en/mcp).
