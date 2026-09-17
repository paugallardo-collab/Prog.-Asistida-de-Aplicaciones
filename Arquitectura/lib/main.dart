import 'package:flutter/material.dart';

import 'data/repositories/usuario_api.dart';
import 'domain/usecases/obtener_usuarios.dart';
import 'presentation/pages/pantalla_usuarios.dart';

void main() {
  final repository = UsuarioApi();
  final obtenerUsuarios = ObtenerUsuarios(repository);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arquitectura de usuarios',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: PantallaUsuarios(obtenerUsuarios: obtenerUsuarios),
    ),
  );
}
