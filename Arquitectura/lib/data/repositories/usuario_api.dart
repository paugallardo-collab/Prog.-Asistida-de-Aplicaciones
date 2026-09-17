import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';

class UsuarioApi implements UsuarioRepository {
  @override
  Future<List<Usuario>> obtener() async {
    final respuesta = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/users'))
        .timeout(const Duration(seconds: 15));

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron obtener los usuarios');
    }

    final datos = jsonDecode(respuesta.body) as List<dynamic>;
    return datos.map((dato) {
      return Usuario(
        id: dato['id'] as int,
        nombre: dato['name'] as String,
        email: dato['email'] as String,
      );
    }).toList();
  }
}
