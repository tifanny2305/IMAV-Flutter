import 'package:flutter/material.dart';

class Grabaciones extends StatelessWidget {
  const Grabaciones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grabaciones')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text("Iniciar grabación"),
              onPressed: () {
                // Aquí puedes agregar la lógica para iniciar la grabación
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text("Historial"),
              onPressed: () {
                // Aquí puedes agregar la lógica para mostrar el historial
              },
            ),
          ],
        ),
      ),
    );
  }
}