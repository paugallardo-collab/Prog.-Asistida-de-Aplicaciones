"""Pruebas del contrato, con una instancia aislada por prueba."""

import pytest

from server import Detective


@pytest.fixture
def detective() -> Detective:
    return Detective()


def test_lista_exactamente_tres_casos(detective):
    assert detective.listar() == [
        {"id": "INC-001", "sistema": "portal_acceso", "cantidad_eventos": 2},
        {"id": "INC-002", "sistema": "portal_acceso", "cantidad_eventos": 6},
        {"id": "INC-003", "sistema": "panel_administracion", "cantidad_eventos": 5},
    ]


def test_consulta_desconocida_falla(detective):
    with pytest.raises(ValueError, match="INC-999.*no existe"):
        detective.consultar("INC-999")


def test_consulta_seis_fallos_exactos(detective):
    assert detective.consultar("INC-002") == [
        {"hora": f"02:{minuto}", "usuario": "admin", "ip": "203.0.113.25",
         "evento": "LOGIN_FAILED"}
        for minuto in range(10, 16)
    ]


def test_consulta_no_expone_estado_mutable(detective):
    eventos = detective.consultar("INC-001")
    eventos[0]["usuario"] = "modificado"
    eventos.clear()
    assert detective.consultar("INC-001")[0]["usuario"] == "ana"
    assert detective.listar()[0]["cantidad_eventos"] == 2


@pytest.mark.parametrize("nivel", ["bajo", "medio", "alto"])
def test_registro_valido(detective, nivel):
    assert detective.registrar("INC-003", nivel, "Requiere revisión") == {
        "caso_id": "INC-003", "nivel": nivel,
        "motivo": "Requiere revisión", "estado": "registrada",
    }


def test_duplicado_en_misma_instancia(detective):
    detective.registrar("INC-003", "alto", "Revisar los eventos")
    with pytest.raises(ValueError, match="duplicada.*INC-003"):
        detective.registrar("INC-003", "medio", "Otro motivo")


@pytest.mark.parametrize("nivel", ["critico", "ALTO", "", None, 3, []])
def test_rechaza_nivel_invalido_sin_consumir_caso(detective, nivel):
    with pytest.raises(ValueError, match="bajo, medio o alto"):
        detective.registrar("INC-002", nivel, "Intentos repetidos")
    assert detective.registrar("INC-002", "medio", "Revisar")["estado"] == "registrada"


@pytest.mark.parametrize("motivo", ["", "   ", "\t\n", None, 42, []])
def test_rechaza_motivo_invalido_sin_consumir_caso(detective, motivo):
    with pytest.raises(ValueError, match="motivo.*texto"):
        detective.registrar("INC-002", "medio", motivo)
    assert detective.registrar("INC-002", "medio", "Revisar")["estado"] == "registrada"


def test_registro_desconocido_falla(detective):
    with pytest.raises(ValueError, match="INC-999.*no existe"):
        detective.registrar("INC-999", "alto", "Revisar")


def test_alertas_independientes_por_caso(detective):
    for caso in detective.listar():
        assert detective.registrar(caso["id"], "bajo", "Revisar")["estado"] == "registrada"


def test_nueva_instancia_no_hereda_alertas(detective):
    detective.registrar("INC-003", "alto", "Revisar")
    assert Detective().registrar("INC-003", "alto", "Revisar")["estado"] == "registrada"


def test_respuesta_no_permite_eludir_duplicado(detective):
    respuesta = detective.registrar("INC-003", "alto", "Revisar")
    respuesta.clear()
    with pytest.raises(ValueError, match="duplicada"):
        detective.registrar("INC-003", "alto", "Revisar")


def test_carga_desde_otro_directorio(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    assert len(Detective().listar()) == 3
