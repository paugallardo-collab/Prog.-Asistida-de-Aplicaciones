# Evidencias — Deber 5

Las capturas originales documentan la implementación, las pruebas del Inspector y el uso real del MCP por agentes en VS Code.

| Comprobación del enunciado | Archivos |
|---|---|
| Parte 1: tres herramientas en el servidor | `parte1_server.png` |
| Parte 2a: discovery de las tres herramientas | `inspector_tools.png` |
| D1: listado de tres casos | `inspector_pruebas.png` |
| D2: seis fallos de INC-002 | `inspector_d2_1.png` a `inspector_d2_4.png` |
| D3: consulta de INC-999 rechazada | `inspector_d3.png` |
| D4: alerta válida registrada | `inspector_d4.png` |
| D5: alerta duplicada rechazada | `inspector_d5.png` |
| D6: nivel inválido rechazado | `inspector_d6.png` |
| D7: motivo en blanco rechazado | `inspector_d7.png` |
| Parte 2b: 25 pruebas pytest aprobadas | `pytest.png` |
| Parte 2c: registro aceptado después de reiniciar | `inspector_reinicio.png` |
| Parte 3: listado de casos desde Codex en una conversación nueva | `agente_tools.png`, `agente_listar_2.png`, `agente_listar_3.png` |
| Parte 3: consultas de INC-001, INC-002 e INC-003 desde Claude Code en una sesión nueva | `agente_consultas.png` |
| Parte 3: llamada de registro para INC-003 y resultado original con estado registrada | `agente_alerta_1.png`, `agente_alerta_2.png` |
| Parte 3: consulta de INC-999 y error real comunicado por el agente | `agente_error_999.png` |

La investigación final se realizó en el chat de Claude Code «Casos y eventos de mcp_detective», usando las herramientas MCP para obtener los eventos. Las capturas del agente muestran las llamadas de la interfaz y sus resultados; el resultado de la alerta también está abierto en el visor de tool output.

`pytest.txt` conserva la salida de las pruebas. `mcp_stdio.json` contiene la verificación automatizada del protocolo, D1–D7 y el reinicio mediante un cliente del SDK sin LLM; se distingue de las capturas del agente.

Las imágenes se conservaron sin modificar. Las capturas de continuación permiten leer los resultados sin sustituirlos por imágenes generadas ni repetir el mismo contenido en dos formatos.
