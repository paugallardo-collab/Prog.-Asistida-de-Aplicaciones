import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

class ObtenerUsuariosConVocal {
  final UsuarioRepository repository;

  ObtenerUsuariosConVocal(this.repository);

  Future<List<Usuario>> ejecutar() async {
    final usuarios = await repository.obtener();
    return usuarios.where((usuario) {
      final nombre = usuario.nombre.toLowerCase();
      return RegExp(r'^[aeiou]').hasMatch(nombre);
    }).toList();
  }
}
