"""Comprueba D1–D7 y el reinicio usando un cliente MCP real, sin LLM.

No importa server.py ni lee casos.json: toda consulta pasa por stdio.
Esta verificación complementa al Inspector; no reemplaza la Parte 3.
"""

import asyncio
import json
import sys
from pathlib import Path

from mcp import Client
from mcp.client.stdio import StdioServerParameters


async def verificar() -> dict:
    parametros = StdioServerParameters(
        command=sys.executable,
        args=[str(Path(__file__).resolve().with_name("server.py"))],
        cwd=str(Path(__file__).resolve().parent.parent),
    )
    traza: dict = {"cliente": "SDK MCP (sin LLM)", "transporte": "stdio", "llamadas": []}

    async def llamar(cliente, prueba, nombre, argumentos, error=False, mensaje=""):
        resultado = await cliente.call_tool(nombre, argumentos)
        serializado = resultado.model_dump(mode="json", by_alias=True)
        traza["llamadas"].append({"prueba": prueba, "tool": nombre,
                                  "argumentos": argumentos, "resultado": serializado})
        assert resultado.is_error == error, (prueba, serializado)
        texto = " ".join(getattr(bloque, "text", "") for bloque in resultado.content)
        if mensaje:
            assert mensaje in texto, (prueba, texto)
        if error:
            return texto
        if resultado.structured_content is not None:
            contenido = resultado.structured_content
            return contenido.get("result", contenido)
        bloques = [json.loads(b.text) for b in resultado.content if hasattr(b, "text")]
        return bloques[0] if len(bloques) == 1 else bloques

    alerta = {"caso_id": "INC-003", "nivel": "alto",
              "motivo": "Cuatro fallos y un acceso exitoso desde la misma IP; requiere investigación"}
    async with Client(parametros) as cliente:
        herramientas = await cliente.list_tools()
        traza["discovery"] = herramientas.model_dump(mode="json", by_alias=True)
        assert {tool.name for tool in herramientas.tools} == {
            "listar_casos", "consultar_eventos", "registrar_alerta"}
        casos = await llamar(cliente, "D1", "listar_casos", {})
        # El SDK encapsula las listas en structuredContent; el contenido de texto es JSON.
        if isinstance(casos, dict):
            casos = casos["result"]
        assert [caso["id"] for caso in casos] == ["INC-001", "INC-002", "INC-003"]
        eventos = await llamar(cliente, "D2", "consultar_eventos", {"caso_id": "INC-002"})
        if isinstance(eventos, dict):
            eventos = eventos["result"]
        assert len(eventos) == 6
        assert all(e["evento"] == "LOGIN_FAILED" and e["usuario"] == "admin" for e in eventos)
        await llamar(cliente, "D3", "consultar_eventos", {"caso_id": "INC-999"}, True, "no existe")
        registrada = await llamar(cliente, "D4", "registrar_alerta", alerta)
        assert registrada == {**alerta, "estado": "registrada"}
        await llamar(cliente, "D5", "registrar_alerta", alerta, True, "duplicada")
        await llamar(cliente, "D6", "registrar_alerta",
                     {"caso_id": "INC-002", "nivel": "critico", "motivo": "Intentos repetidos"},
                     True, "bajo, medio o alto")
        await llamar(cliente, "D7", "registrar_alerta",
                     {"caso_id": "INC-002", "nivel": "medio", "motivo": "   "}, True, "motivo")
        await llamar(cliente, "extra-caso", "registrar_alerta",
                     {"caso_id": "INC-999", "nivel": "alto", "motivo": "Revisar"}, True, "no existe")
        await llamar(cliente, "extra-tipo", "registrar_alerta",
                     {"caso_id": "INC-002", "nivel": "medio", "motivo": 42}, True)
    # Salir del contexto termina el servidor; este bloque lanza un proceso nuevo.
    async with Client(parametros) as cliente_nuevo:
        reinicio = await llamar(cliente_nuevo, "2c-proceso-nuevo", "registrar_alerta", alerta)
        assert reinicio["estado"] == "registrada"
    traza["estado"] = "D1–D7, validación de tipos y reinicio: correctos"
    return traza


if __name__ == "__main__":
    # Este archivo es el cliente de pruebas, NO el servidor stdio.
    print(json.dumps(asyncio.run(verificar()), ensure_ascii=False, indent=2))
