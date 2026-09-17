import 'package:arquitectura_usuarios/data/repositories/usuario_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../ejemplo/main_sin_capas.dart';

const respuestaJson = '''[
  {"id":1,"name":"Ana","email":"ana@example.com"},
  {"id":2,"name":"Carlos","email":"carlos@example.com"}
]''';

void main() {
  test('API convierte JSON sin aplicar el filtro', () async {
    await http.runWithClient(
      () async {
        final usuarios = await UsuarioApi().obtener();
        expect(usuarios.map((u) => u.nombre), ['Ana', 'Carlos']);
        expect(usuarios.first.id, 1);
        expect(usuarios.first.email, 'ana@example.com');
      },
      () => MockClient((request) async {
        expect(
          request.url.toString(),
          'https://jsonplaceholder.typicode.com/users',
        );
        return http.Response(respuestaJson, 200);
      }),
    );
  });

  test('API comunica un estado HTTP fallido', () async {
    await http.runWithClient(() async {
      await expectLater(UsuarioApi().obtener(), throwsException);
    }, () => MockClient((request) async => http.Response('Error', 500)));
  });

  testWidgets('Versión inicial consulta y filtra usuarios', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: PantallaInicial()));
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Carlos'), findsNothing);
    }, () => MockClient((request) async => http.Response(respuestaJson, 200)));
  });
}
