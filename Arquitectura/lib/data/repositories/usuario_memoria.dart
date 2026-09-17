import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';

class UsuarioMemoria implements UsuarioRepository {
  @override
  Future<List<Usuario>> obtener() async {
    return const [
      Usuario(id: 1, nombre: 'Ana', email: 'ana@example.com'),
      Usuario(id: 2, nombre: 'Carlos', email: 'carlos@example.com'),
      Usuario(id: 3, nombre: 'elena', email: 'elena@example.com'),
    ];
  }
}
