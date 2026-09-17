import 'dart:async';

import 'package:arquitectura_usuarios/data/repositories/usuario_memoria.dart';
import 'package:arquitectura_usuarios/domain/entities/usuario.dart';
import 'package:arquitectura_usuarios/domain/repositories/usuario_repository.dart';
import 'package:arquitectura_usuarios/domain/usecases/obtener_usuarios_con_vocal.dart';
import 'package:arquitectura_usuarios/domain/usecases/obtener_usuarios.dart';
import 'package:arquitectura_usuarios/presentation/pages/pantalla_usuarios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RepositorioPrueba implements UsuarioRepository {
  Future<List<Usuario>> respuesta;
  int solicitudes = 0;
  RepositorioPrueba(this.respuesta);

  @override
  Future<List<Usuario>> obtener() {
    solicitudes++;
    return respuesta;
  }
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

  testWidgets('Muestra todos los usuarios antes de buscar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaUsuarios(
          obtenerUsuarios: ObtenerUsuarios(UsuarioMemoria()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('elena'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
  });

  testWidgets('Busca al escribir, permite limpiar y no vuelve a pedir datos', (
    tester,
  ) async {
    final repository = RepositorioPrueba(UsuarioMemoria().obtener());
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaUsuarios(obtenerUsuarios: ObtenerUsuarios(repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' AR ');
    await tester.pumpAndSettle();
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);
    expect(find.text('elena'), findsNothing);
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron usuarios'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('elena'), findsOneWidget);
    expect(repository.solicitudes, 1);
  });

  testWidgets('Muestra carga y luego lista vacía', (tester) async {
    final pendiente = Completer<List<Usuario>>();
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaUsuarios(
          obtenerUsuarios: ObtenerUsuarios(RepositorioPrueba(pendiente.future)),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pendiente.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron usuarios'), findsOneWidget);
  });

  testWidgets('Muestra error y permite reintentar', (tester) async {
    final pendiente = Completer<List<Usuario>>();
    final repository = RepositorioPrueba(pendiente.future);
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaUsuarios(obtenerUsuarios: ObtenerUsuarios(repository)),
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
