import 'package:flutter/material.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/usecases/obtener_usuarios.dart';

class PantallaUsuarios extends StatefulWidget {
  final ObtenerUsuarios obtenerUsuarios;

  const PantallaUsuarios({super.key, required this.obtenerUsuarios});

  @override
  State<PantallaUsuarios> createState() => _PantallaUsuariosState();
}

class _PantallaUsuariosState extends State<PantallaUsuarios> {
  late Future<List<Usuario>> _usuarios;
  String _busqueda = '';

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
        title: const Text('Usuarios de la API'),
        actions: [
          IconButton(
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre',
                hintText: 'Escribe letras o un nombre',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (texto) {
                setState(() {
                  _busqueda = texto;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Usuario>>(
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
                final usuarios = widget.obtenerUsuarios.filtrar(
                  snapshot.data ?? [],
                  _busqueda,
                );
                if (usuarios.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron usuarios'),
                  );
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
          ),
        ],
      ),
    );
  }
}
