# Evidencias y últimos pasos

## Verificaciones realizadas

- `pytest.txt`: salida real de pytest, con 25 pruebas aprobadas.
- `mcp_stdio.json`: discovery y respuestas reales del servidor mediante el cliente MCP del SDK. Comprueba D1–D7, caso inexistente al registrar, tipo inválido y registro tras reiniciar el proceso.
- La traza anterior es una prueba cliente-servidor sin LLM. No se presenta como captura del Inspector ni como traza de un agente conectado.

## Capturas pendientes

La automatización pudo abrir el Inspector, pero la captura de la ventana devolvió otra aplicación y no fue posible completar su interacción de forma fiable. No se generaron imágenes simuladas. Las siguientes cinco capturas deben obtenerse antes de entregar:

| Archivo obligatorio | Qué debe verse |
|---|---|
| `parte1_server.png` | Código real de `server.py` con los tres `@mcp.tool()`, firmas y docstrings. |
| `inspector_tools.png` | Inspector conectado, con las tres herramientas descubiertas. |
| `inspector_pruebas.png` | Resultados reales D1–D7, incluidos el duplicado y las validaciones. Usar capturas adicionales si no caben legiblemente en una. |
| `pytest.png` | Terminal después de ejecutar pytest; deben verse las pruebas aprobadas. |
| `agente_tools.png` | Conversación nueva del agente mostrando llamadas MCP reales, argumentos y resultados. Incluir consultas de los tres casos, registro de INC-003 y error de INC-999; añadir imágenes si hace falta. |

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
