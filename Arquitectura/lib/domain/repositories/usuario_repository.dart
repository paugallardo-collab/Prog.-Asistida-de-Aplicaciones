import '../entities/usuario.dart';

abstract class UsuarioRepository {
  Future<List<Usuario>> obtener();
}
