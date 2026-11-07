"""Añade el servidor al proyecto actual sin modificar la configuración global."""

import json
import sys
import tomllib
from pathlib import Path


def configurar() -> None:
    raiz = Path(__file__).resolve().parent
    archivo = raiz / ".codex" / "config.toml"
    anterior = archivo.read_text(encoding="utf-8") if archivo.exists() else ""
    servidores = tomllib.loads(anterior).get("mcp_servers", {})
    if "mcp_detective" in servidores:
        raise SystemExit("mcp_detective ya está configurado; revisa .codex/config.toml.")
    bloque = (
        "\n[mcp_servers.mcp_detective]\n"
        f"command = {json.dumps(sys.executable.replace(chr(92), '/'))}\n"
        f"args = [{json.dumps((raiz / 'mcp-detective' / 'server.py').as_posix())}]\n"
        "startup_timeout_sec = 30\n"
        "tool_timeout_sec = 30\n"
    )
    archivo.parent.mkdir(exist_ok=True)
    archivo.write_text(anterior.rstrip() + "\n" + bloque, encoding="utf-8")
    print("Configurado MCP Detective en .codex/config.toml.")
    print("Abre una conversación nueva de Codex en esta carpeta para cargarlo.")


if __name__ == "__main__":
    configurar()
