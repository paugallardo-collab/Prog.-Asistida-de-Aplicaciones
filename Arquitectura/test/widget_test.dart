import 'dart:async';

import 'package:arquitectura_usuarios/data/repositories/usuario_memoria.dart';
import 'package:arquitectura_usuarios/domain/entities/usuario.dart';
import 'package:arquitectura_usuarios/domain/repositories/usuario_repository.dart';
import 'package:arquitectura_usuarios/domain/usecases/obtener_usuarios_con_vocal.dart';
import 'package:arquitectura_usuarios/presentation/pages/pantalla_usuarios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RepositorioPrueba implements UsuarioRepository {
  Future<List<Usuario>> respuesta;
  RepositorioPrueba(this.respuesta);

  @override
  Future<List<Usuario>> obtener() => respuesta;
}

void main() {
  test(
    'Filtra las cinco vocales y descarta consonantes y nombre vacío',
    () async {
      final nombres = [
        'Ana',
        'elena',
        'INES',
        'Oscar',
        'ursula',
        'Carlos',
        '',
        'Luis',
      ];
      final usuarios = [
        for (var i = 0; i < nombres.length; i++)
          Usuario(id: i, nombre: nombres[i], email: 'prueba@example.com'),
      ];
      final caso = ObtenerUsuariosConVocal(
        RepositorioPrueba(Future.value(usuarios)),
      );
      final resultado = await caso.ejecutar();
      expect(resultado.map((u) => u.nombre), [
        'Ana',
        'elena',
        'INES',
        'Oscar',
        'ursula',
      ]);
    },
  );

  testWidgets('Muestra Ana y elena con memoria, pero no Carlos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaUsuarios(
          obtenerUsuarios: ObtenerUsuariosConVocal(UsuarioMemoria()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('elena'), findsOneWidget);
    expect(find.text('Carlos'), findsNothing);
  });

  testWidgets('Muestra carga y luego lista vacía', (tester) async {
    final pendiente = Completer<List<Usuario>>();
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaUsuarios(
          obtenerUsuarios: ObtenerUsuariosConVocal(
            RepositorioPrueba(pendiente.future),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pendiente.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No hay nombres con vocal'), findsOneWidget);
  });

  testWidgets('Muestra error y permite reintentar', (tester) async {
    final pendiente = Completer<List<Usuario>>();
    final repository = RepositorioPrueba(pendiente.future);
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaUsuarios(
          obtenerUsuarios: ObtenerUsuariosConVocal(repository),
        ),
      ),
    );
    pendiente.completeError(Exception('Fallo simulado'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar los usuarios'), findsOneWidget);
    repository.respuesta = UsuarioMemoria().obtener();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('elena'), findsOneWidget);
  });
}
