import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

class ObtenerUsuarios {
  final UsuarioRepository repository;

  ObtenerUsuarios(this.repository);

  Future<List<Usuario>> ejecutar() => repository.obtener();

  List<Usuario> filtrar(List<Usuario> usuarios, String texto) {
    final busqueda = texto.trim().toLowerCase();
    return usuarios.where((usuario) {
      return usuario.nombre.toLowerCase().contains(busqueda);
    }).toList();
  }
}
