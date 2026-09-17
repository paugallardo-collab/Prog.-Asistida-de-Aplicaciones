import 'package:flutter/material.dart';

import 'data/repositories/usuario_memoria.dart';
import 'domain/usecases/obtener_usuarios_con_vocal.dart';
import 'presentation/pages/pantalla_usuarios.dart';

void main() {
  final repository = UsuarioMemoria();
  final obtenerUsuarios = ObtenerUsuariosConVocal(repository);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arquitectura de usuarios',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: PantallaUsuarios(obtenerUsuarios: obtenerUsuarios),
    ),
  );
}
