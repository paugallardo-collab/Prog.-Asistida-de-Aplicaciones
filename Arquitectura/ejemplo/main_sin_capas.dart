import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(home: PantallaInicial()));
}

// Versión inicial: mezcla intencionalmente datos, regla e interfaz.
class PantallaInicial extends StatefulWidget {
  const PantallaInicial({super.key});

  @override
  State<PantallaInicial> createState() => _PantallaInicialState();
}

class _PantallaInicialState extends State<PantallaInicial> {
  late final Future<List<dynamic>> _usuarios;

  @override
  void initState() {
    super.initState();
    _usuarios = _cargarUsuarios();
  }

  Future<List<dynamic>> _cargarUsuarios() async {
    final respuesta = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users'),
    );
    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron obtener los usuarios');
    }
    final datos = jsonDecode(respuesta.body) as List<dynamic>;
    return datos.where((usuario) {
      final nombre = (usuario['name'] as String).toLowerCase();
      return RegExp(r'^[aeiou]').hasMatch(nombre);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios: versión inicial')),
      body: FutureBuilder<List<dynamic>>(
        future: _usuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar usuarios'));
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
                title: Text(usuario['name'] as String),
                subtitle: Text(usuario['email'] as String),
              );
            },
          );
        },
      ),
    );
  }
}
