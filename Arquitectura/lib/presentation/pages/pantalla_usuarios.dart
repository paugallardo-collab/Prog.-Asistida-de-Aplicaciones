import 'package:flutter/material.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/usecases/obtener_usuarios_con_vocal.dart';

class PantallaUsuarios extends StatefulWidget {
  final ObtenerUsuariosConVocal obtenerUsuarios;

  const PantallaUsuarios({super.key, required this.obtenerUsuarios});

  @override
  State<PantallaUsuarios> createState() => _PantallaUsuariosState();
}

class _PantallaUsuariosState extends State<PantallaUsuarios> {
  late Future<List<Usuario>> _usuarios;

  @override
  void initState() {
    super.initState();
    _usuarios = widget.obtenerUsuarios.ejecutar();
  }

  void _recargar() {
    setState(() {
      _usuarios = widget.obtenerUsuarios.ejecutar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios con vocal'),
        actions: [
          IconButton(
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: FutureBuilder<List<Usuario>>(
        future: _usuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar los usuarios'),
                  TextButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final usuarios = snapshot.data ?? [];
          if (usuarios.isEmpty) {
            return const Center(child: Text('No hay nombres con vocal'));
          }
          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${usuario.id}')),
                title: Text(usuario.nombre),
                subtitle: Text(usuario.email),
              );
            },
          );
        },
      ),
    );
  }
}
