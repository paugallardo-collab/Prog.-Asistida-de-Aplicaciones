#!/usr/bin/env python3
"""Comprobación cruzada de las reglas de references/detection-rules.md.

Uso:
    python analyze_logs.py LOGS.csv [--json] [--col ip=src_ip ...]

- Solo lectura: no modifica el CSV ni escribe archivos.
- Sin red y sin dependencias externas (biblioteca estándar).
- Las filas citadas son números de línea del CSV original (encabezado = fila 1).
- Los valores de secretos se sustituyen por [REDACTED] en toda la salida.

El script es una ayuda: el agente debe verificar sus resultados contra las filas
originales y reportar cualquier discrepancia.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta

REQUIRED = ("timestamp", "ip", "user", "event", "result", "detail")
WINDOW = timedelta(minutes=5)  # ventana <= 5 min, ambos extremos incluidos
BRUTE_FORCE_MIN = 6            # R1
SPRAY_MIN_USERS = 5            # R2
SECRET_RE = re.compile(
    r"(?i)(token|password|secret|api_key|apikey)=([^;\s,]+)|(authorization:)\s*([^;,]+)"
)


def redact(text: str) -> str:
    def _sub(m: re.Match) -> str:
        if m.group(1):
            return f"{m.group(1)}=[REDACTED]"
        return f"{m.group(3)} [REDACTED]"

    return SECRET_RE.sub(_sub, text)


def redact_obj(obj):
    """Redacta recursivamente todas las cadenas de la salida (no solo `detail`)."""
    if isinstance(obj, str):
        return redact(obj)
    if isinstance(obj, list):
        return [redact_obj(x) for x in obj]
    if isinstance(obj, dict):
        return {k: redact_obj(v) for k, v in obj.items()}
    return obj


def load(path: str, mapping: dict[str, str]):
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        header = reader.fieldnames or []
        cols = {name: mapping.get(name, name) for name in REQUIRED}
        missing = [f"{k} (columna '{v}')" for k, v in cols.items() if v not in header]
        rows, problems = [], []
        start_line = reader.line_num + 1
        for rec in reader:
            # Sin .strip(): la coincidencia de event/result/ip/user debe ser exacta.
            row = {k: (rec.get(v) or "") for k, v in cols.items()}
            row["row"] = start_line  # línea donde empieza el registro
            if reader.line_num != start_line:
                problems.append(f"registro de la fila {start_line} ocupa varias líneas")
            try:
                row["t"] = datetime.fromisoformat(row["timestamp"].strip())
            except ValueError:
                row["t"] = None
                problems.append(f"fila {start_line}: timestamp no interpretable")
            rows.append(row)
            start_line = reader.line_num + 1
    # Fechas con y sin zona horaria no son comparables: no se asume ninguna zona.
    aware = [r for r in rows if r["t"] is not None and r["t"].tzinfo is not None]
    naive = [r for r in rows if r["t"] is not None and r["t"].tzinfo is None]
    if aware and naive:
        for r in naive:
            r["t"] = None
        problems.append("zonas horarias mezcladas: las filas sin zona ("
                        + ", ".join(str(r["row"]) for r in naive)
                        + ") no se usan en ventanas ni en antes/después")
    return header, missing, rows, problems


def best_window(events, key=None):
    """Ventana anclada en cada evento con más elementos (o más claves distintas)."""
    best = []
    for anchor in events:
        win = [e for e in events if anchor["t"] <= e["t"] <= anchor["t"] + WINDOW]
        score = len({key(e) for e in win}) if key else len(win)
        best_score = len({key(e) for e in best}) if key else len(best)
        if score > best_score:
            best = win
    return best


def analyze(rows):
    timed = [r for r in rows if r["t"] is not None]
    ordered = sorted(timed, key=lambda r: (r["t"], r["row"]))  # orden estable
    untimed = [r for r in rows if r["t"] is None]  # R3/R4 se evalúan igualmente
    fails = [r for r in ordered if r["event"] == "login" and r["result"] == "failed"]
    out = {"alerts": [], "context": [], "false_positives": [], "limitations": []}

    # Filas idénticas (no se deduplican; se informa la sensibilidad).
    identical = defaultdict(list)
    for r in rows:
        identical[tuple(r[c] for c in REQUIRED)].append(r["row"])
    dup_groups = [v for v in identical.values() if len(v) > 1]
    dup_rows = {n for g in dup_groups for n in g[1:]}

    # R1 — fuerza bruta
    by_pair = defaultdict(list)
    for r in fails:
        by_pair[(r["ip"], r["user"])].append(r)
    for (ip, user), evs in by_pair.items():
        win = best_window(evs)
        rows_w = [e["row"] for e in win]
        if len(win) >= BRUTE_FORCE_MIN:
            last = win[-1]
            succ_rows = [
                r for r in ordered
                if r["event"] == "login" and r["result"] == "success"
                and r["ip"] == ip and r["user"] == user
                # posterior en el orden estable (t, fila) y dentro de los 5 min siguientes
                and (r["t"], r["row"]) > (last["t"], last["row"])
                and r["t"] <= last["t"] + WINDOW
            ]
            succ = [r["row"] for r in succ_rows]
            distinct = len([n for n in rows_w if n not in dup_rows])
            out["alerts"].append({
                "rule": "R1 fuerza bruta probable",
                "severity": "alta" if succ else "media",
                "ip": ip, "user": user, "count": len(win),
                "start": win[0]["timestamp"], "end": last["timestamp"],
                "rows": rows_w, "subsequent_success_rows": succ,
                "subsequent_success_same_timestamp_rows":
                    [r["row"] for r in succ_rows if r["t"] == last["t"]],
                "count_if_identical_rows_were_duplicates": distinct,
            })
        elif len(win) >= 2:
            out["false_positives"].append({
                "case": f"{len(win)} login/failed {ip} -> {user} en 5 min (< {BRUTE_FORCE_MIN})",
                "rows": rows_w,
            })

    # R2 — password spraying
    by_ip = defaultdict(list)
    for r in fails:
        by_ip[r["ip"]].append(r)
    for ip, evs in by_ip.items():
        win = best_window(evs, key=lambda e: e["user"])
        users = sorted({e["user"] for e in win})
        if len(users) >= SPRAY_MIN_USERS:
            last = win[-1]
            # "Posterior" = después del último fallo en el orden estable (t, fila).
            later = [r for r in ordered if r["ip"] == ip and r["event"] == "login"
                     and r["result"] == "success" and (r["t"], r["row"]) > (last["t"], last["row"])]
            out["alerts"].append({
                "rule": "R2 password spraying probable",
                "severity": "alta" if later else "media",
                "ip": ip, "users": users, "distinct_users": len(users),
                "start": win[0]["timestamp"], "end": last["timestamp"],
                "rows": [e["row"] for e in win],
                "subsequent_success_rows": [r["row"] for r in later],
                "subsequent_success_same_timestamp_rows":
                    [r["row"] for r in later if r["t"] == last["t"]],
            })

    # R3 — token expuesto / R4 — cambio de rol no aprobado / contexto
    for r in ordered + untimed:
        detail = r["detail"]
        if "token=" in detail.lower():
            out["alerts"].append({
                "rule": "R3 token potencialmente expuesto", "severity": "alta",
                "ip": r["ip"], "user": r["user"], "start": r["timestamp"],
                "rows": [r["row"]], "event": f"{r['event']}/{r['result']}",
                "detail_redacted": redact(detail),
            })
        elif SECRET_RE.search(detail):
            out["context"].append({"row": r["row"], "note": "posible secreto fuera de R3",
                                   "detail_redacted": redact(detail)})
        if (r["event"] == "role_change" and "approved=false" not in detail
                and re.search(r"(?i)approved\s*=\s*false", detail)):
            out["context"].append({"row": r["row"], "note": "variante no exacta de approved=false "
                                   "(no cuenta para R4)", "detail_redacted": redact(detail)})
        if (r["event"] == "role_change" and r["result"] == "success"
                and "approved=false" in detail):  # subcadena literal, como fija R4
            alert = {
                "rule": "R4 escalada no autorizada según el registro", "severity": "alta",
                "ip": r["ip"], "user": r["user"], "start": r["timestamp"],
                "rows": [r["row"]], "detail_redacted": redact(detail),
            }
            if r["t"] is None:
                alert["context_rows_prev_5min"] = "no evaluable (timestamp no interpretable)"
            else:
                # Previos en el orden estable (t, fila), dentro de los 5 min anteriores.
                prior = [p for p in ordered
                         if (p["user"] == r["user"] or p["ip"] == r["ip"])
                         and (p["t"], p["row"]) < (r["t"], r["row"])
                         and p["t"] >= r["t"] - WINDOW]
                alert["context_rows_prev_5min"] = [p["row"] for p in prior]
                alert["context_same_timestamp_rows"] = [p["row"] for p in prior
                                                        if p["t"] == r["t"]]
            out["alerts"].append(alert)
        if r["event"] not in ("login", "role_change") and "token=" not in detail.lower():
            if r["event"] != "healthcheck":
                out["context"].append({"row": r["row"], "note": f"evento no cubierto por reglas: "
                                       f"{r['event']}/{r['result']}", "detail_redacted": redact(detail)})

    # R5 — healthcheck no es login/failed
    hc = [r["row"] for r in ordered if r["event"] == "healthcheck"]
    if hc:
        out["false_positives"].append({"case": "healthcheck no es login/failed", "rows": hc})

    # Limitaciones
    if dup_groups:
        out["limitations"].append(
            "filas idénticas (no deduplicadas, conteo tal cual): "
            + "; ".join(", ".join(map(str, g)) for g in dup_groups))
    events = Counter((r["event"], r["result"]) for r in rows)
    variants = [f"{e!r}/{s!r}" for (e, s) in events if "login" in e.lower() and
                (e, s) not in (("login", "failed"), ("login", "success"))]
    if variants:
        out["limitations"].append("variantes de login no contadas: " + ", ".join(variants))
    padded = sorted({r["row"] for r in rows for c in ("ip", "user", "event", "result")
                     if r[c] != r[c].strip()})
    if padded:
        out["limitations"].append("campos con espacios al inicio/final (no se normalizan): filas "
                                  + ", ".join(map(str, padded)))
    if timed and all(r["t"].second == 0 for r in timed):
        out["limitations"].append("resolución de minuto: orden dentro del mismo minuto incierto")
    out["summary"] = {
        "data_rows": len(rows),
        "first": ordered[0]["timestamp"] if ordered else None,
        "last": ordered[-1]["timestamp"] if ordered else None,
        "already_sorted": [r["row"] for r in timed] == [r["row"] for r in ordered],
        "event_result_counts": {f"{e}/{s}": n for (e, s), n in sorted(events.items())},
    }
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("csv")
    ap.add_argument("--json", action="store_true", help="salida JSON")
    ap.add_argument("--col", action="append", default=[],
                    help="mapeo de columna, p. ej. ip=src_ip (repetible)")
    args = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")  # consolas Windows (cp1252)
    mapping = dict(m.split("=", 1) for m in args.col)

    header, missing, rows, problems = load(args.csv, mapping)
    if missing:
        print(redact(f"Columnas no encontradas: {', '.join(missing)}. Encabezado: {header}. "
                     "Usa --col nombre=columna o analiza manualmente."), file=sys.stderr)
        return 2
    result = analyze(rows)
    result["limitations"] += problems
    result["summary"]["header"] = header
    result = redact_obj(result)  # ningún campo de la salida muestra secretos

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    s = result["summary"]
    print(f"Filas de datos: {s['data_rows']} | {s['first']} -> {s['last']} | "
          f"ordenado: {s['already_sorted']}")
    print("event/result:", s["event_result_counts"])
    for section in ("alerts", "context", "false_positives", "limitations"):
        print(f"\n== {section} ==")
        for item in result[section]:
            print(" -", item if isinstance(item, str) else json.dumps(item, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
