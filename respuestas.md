# Deber 5 — MCP Detective

## 1. Arquitectura

El LLM decide qué herramienta necesita, propone sus argumentos e interpreta lo que recibe. El host organiza la conversación y coordina las llamadas; en este trabajo se usaron Codex y Claude Code en VS Code. El cliente MCP transporta las solicitudes y respuestas por stdio. El servidor MCP es el proceso local que ejecuta realmente Python: recupera los casos, valida las entradas y guarda las alertas en memoria.

`listar_casos` y `consultar_eventos` solo leen. `registrar_alerta` cambia el estado. Las tres se registran con `@mcp.tool()` en `server.py`.

## 2. Evidencia y límites

INC-003 merece investigación porque los eventos muestran cuatro fallos de `admin`, de 03:00 a 03:03, seguidos de un acceso exitoso a las 03:04 desde la misma IP de documentación, 192.0.2.50, en el panel de administración. Se registró una alerta de nivel alto por el patrón y por la cuenta administrativa involucrada.

Eso no demuestra una intrusión: los logs no dicen quién estaba usando la cuenta ni si tenía autorización. Podría ser una persona legítima que corrigió sus credenciales. Haría falta verificar el contexto con el dueño de la cuenta y revisar la actividad posterior. El motivo registrado reconoce expresamente este límite.

## 3. Validación y seguridad

El servidor rechaza INC-999, los niveles distintos de bajo/medio/alto, los motivos que no son texto o quedan en blanco y las alertas duplicadas. La lógica lanza `ValueError` antes de guardar. En SDK 2.3.0, las tools traducen esos errores previstos a `ToolError` para que MCP conserve un mensaje comprensible y marque la llamada como fallida.

No es suficiente confiar en el modelo: puede generar argumentos equivocados y otro cliente puede mandar datos inválidos. El servidor garantiza de forma determinista las validaciones y una única alerta por caso durante la vida del proceso. Una respuesta del LLM por sí sola no garantiza esas restricciones. Al reiniciar, las alertas desaparecen porque no se escriben en disco.

## Agentes y comprobación de conexión

Se usó **OpenAI Codex en VS Code** para implementar y probar el proyecto. La investigación final se realizó en una **conversación nueva de Claude Code en VS Code**, «Casos y eventos de mcp_detective». Se comprobó la conexión en `/mcp` y mediante las llamadas reales del chat: consultas de los tres casos, registro de INC-003 y consulta de INC-999. La evidencia de eventos se obtuvo con las herramientas MCP, sin abrir `casos.json` ni usar la terminal para investigar.

[agente_tools.png](evidencias/agente_tools.png) y sus continuaciones muestran el listado inicial desde otra conversación nueva de Codex. [agente_consultas.png](evidencias/agente_consultas.png) muestra las tres consultas desde Claude Code. [agente_alerta_1.png](evidencias/agente_alerta_1.png) y [agente_alerta_2.png](evidencias/agente_alerta_2.png) muestran el registro y su confirmación. [agente_error_999.png](evidencias/agente_error_999.png) muestra el error real sin eventos inventados. El índice completo está en [evidencias/README.md](evidencias/README.md).

## Instalación y ejecución

Requisitos: Python 3.11+, Node.js con npx y Claude Code para la investigación. Desde la raíz de la entrega, en PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m pytest mcp-detective -q
.\.venv\Scripts\mcp.exe dev mcp-detective/server.py
```

En el Inspector, usar STDIO, la ruta absoluta de `.venv/Scripts/python.exe` como Command y la ruta absoluta de `mcp-detective/server.py` como Arguments. Las 25 pruebas pasan y D1–D7 y el reinicio se comprobaron en el Inspector.

Para conectar Claude Code desde esta carpeta:

```powershell
$pythonMcp = (Resolve-Path .venv/Scripts/python.exe).Path
$servidorMcp = (Resolve-Path mcp-detective/server.py).Path
claude mcp add --transport stdio --scope project mcp_detective $pythonMcp $servidorMcp
```

Abrir una conversación nueva, aprobar el servidor del proyecto cuando lo solicite y comprobar que `/mcp` muestre `mcp_detective` conectado. La configuración local `.mcp.json` no lleva tokens ni contraseñas. Para Codex también se incluye `configurar_codex.py`, que genera su configuración local con rutas absolutas.

Referencias técnicas: [SDK MCP v2](https://py.sdk.modelcontextprotocol.io/), [errores del SDK](https://py.sdk.modelcontextprotocol.io/servers/handling-errors/) y [MCP en Claude Code](https://code.claude.com/docs/en/mcp).
