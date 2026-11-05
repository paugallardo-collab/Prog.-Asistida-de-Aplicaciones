# Deber 5 — MCP Detective

Servidor local del sistema ficticio Centinela, con el SDK oficial MCP **2.3.0**, transporte `stdio` y exactamente tres herramientas. Python 3.11+; Node.js y `npx` para el Inspector.

| Herramienta | Comportamiento |
|---|---|
| `listar_casos()` | Devuelve id, sistema y cantidad de eventos, sin clasificaciones. |
| `consultar_eventos(caso_id)` | Devuelve los registros exactos o falla si el caso no existe. |
| `registrar_alerta(caso_id, nivel, motivo)` | Valida y registra una alerta en memoria; rechaza duplicados. |

Los datos se cargan desde `__file__`. El servidor no usa red ni imprime en stdout. Reiniciarlo elimina las alertas. La lógica de negocio usa `ValueError`; la capa MCP adapta esos errores a `ToolError` para preservar mensajes en SDK 2.3.

## Instalación y pruebas

Ejecutar desde la raíz de esta entrega:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\mcp.exe version
.\.venv\Scripts\python.exe -m pytest mcp-detective -q
.\.venv\Scripts\python.exe mcp-detective\verificar_mcp.py
```

Si se usa `uv`, los equivalentes son `uv venv --python 3.12 .venv` y `uv pip install --python .venv/Scripts/python.exe -r requirements.txt`. No se deben mezclar versiones del SDK.

`test_server.py` incluye 25 casos de prueba aislados. `verificar_mcp.py` lanza procesos reales del servidor, descubre las tres tools y verifica D1–D7, argumentos de tipo incorrecto y la pérdida de estado al terminar el primer proceso y lanzar otro. Es un cliente de pruebas sin LLM; no reemplaza la evidencia del agente ni las capturas del Inspector.

## Inspector

```powershell
.\.venv\Scripts\mcp.exe dev mcp-detective/server.py
```

En la interfaz, seleccionar `STDIO`, poner en **Command** la ruta absoluta de `.venv/Scripts/python.exe` y en **Arguments** la ruta absoluta de `mcp-detective/server.py`. Así se usa el entorno ya instalado. Conectar y abrir **Tools**. La CLI del SDK puede abrir Inspector v1 y mostrar un aviso de deprecación; este servidor también atiende clientes MCP anteriores. No incluir en capturas la URL de sesión con su token local.

| Prueba | Tool y argumentos | Resultado esperado |
|---|---|---|
| D1 | `listar_casos {}` | Tres casos, con cantidades 2, 6 y 5. |
| D2 | `consultar_eventos {"caso_id":"INC-002"}` | Seis `LOGIN_FAILED` de `admin`. |
| D3 | `consultar_eventos {"caso_id":"INC-999"}` | Error: el caso no existe. |
| D4 | `registrar_alerta {"caso_id":"INC-003","nivel":"alto","motivo":"Cuatro fallos y un acceso exitoso desde la misma IP; requiere investigación"}` | `estado: registrada`. |
| D5 | Repetir D4 sin reiniciar | Error de alerta duplicada. |
| D6 | `registrar_alerta {"caso_id":"INC-002","nivel":"critico","motivo":"Intentos repetidos"}` | Error de nivel inválido. |
| D7 | `registrar_alerta {"caso_id":"INC-002","nivel":"medio","motivo":"   "}` | Error de motivo en blanco. |

Para 2c, después de D5 terminar y volver a iniciar el proceso del servidor desde el Inspector. Repetir D4: debe aceptarse. El script de verificación también comprueba este comportamiento con dos procesos independientes.

## Conectar el agente

```powershell
.\.venv\Scripts\python.exe configurar_codex.py
```

El script genera `.codex/config.toml` del proyecto con rutas absolutas. Conserva las demás entradas y se detiene si `mcp_detective` ya existe. La configuración es local y está excluida de Git. Abrir una conversación nueva de Codex en esta carpeta; comprobar `/mcp` y discovery. Si el host requiere marcar el proyecto como de confianza, hacerlo en su interfaz.

Durante esa investigación no se debe abrir ni buscar `casos.json`, tampoco leer las pruebas o la reflexión para obtener evidencia. Usar exclusivamente `listar_casos` y `consultar_eventos` para conocer los eventos. Los prompts están preparados en [evidencias/README.md](evidencias/README.md).

## Entrega

[respuestas.md](respuestas.md) contiene la reflexión. [evidencias/README.md](evidencias/README.md) distingue las verificaciones realizadas de las cinco capturas pendientes y explica cómo completarlas. No se exige una grabación de pantalla en el enunciado.

La rama de entrega es `deber5`, con pull request hacia `main`. En el aula virtual se entrega únicamente el enlace al PR. Completar las capturas y la sesión nueva antes de enviarlo al aula.
