import 'package:flutter/material.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Contador(),
    );
  }
}

const String _contadorImageUrl =
    'https://thumbs.dreamstime.com/b/n%C3%BAmeros-divertidos-de-la-historieta-25978523.jpg';

class Contador extends StatefulWidget {
  const Contador({super.key});

  @override
  State<Contador> createState() => _ContadorState();
}

class _ContadorState extends State<Contador> {
  int numero = 0;

  void sumar() {
    setState(() {
      numero++;
    });
  }

  void restar() {
    setState(() {
      numero--;
    });
  }

  void _abrirPantallaRuta() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PantallaRuta()));
  }

  void _botonSinAccion() {}

  Widget _buildImage() {
    return Center(
      child: Image.network(
        _contadorImageUrl,
        width: 250,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Mi Contador'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImage(),
            const SizedBox(height: 20),
            const Text(
              'Contador',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              '$numero',
              style: const TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _botonSinAccion,
                  child: const Text('•', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _abrirPantallaRuta,
                  child: const Text('Ir', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: restar,
                  child: const Text('-', style: TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 25),
                ElevatedButton(
                  onPressed: sumar,
                  child: const Text('+', style: TextStyle(fontSize: 30)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PantallaRuta extends StatelessWidget {
  const PantallaRuta({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Pantalla Ruta'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              _contadorImageUrl,
              width: 250,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  size: 80,
                  color: Colors.grey,
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Regresar'),
            ),
          ],
        ),
      ),
    );
  }
}
