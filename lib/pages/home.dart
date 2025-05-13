import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel del Mecánico')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text("Iniciar grabación"),
              onPressed: () {
                Navigator.pushNamed(context, '/grabaciones');
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text("Historial"),
              onPressed: () {
                Navigator.pushNamed(context, '/historial');
              },
            ),
          ],
        ),
      ),
    );
  }
}
