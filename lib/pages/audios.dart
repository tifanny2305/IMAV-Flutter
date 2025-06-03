import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taller_1/auth/providers/audios_provider.dart';

class Audios extends StatefulWidget {
  const Audios({super.key});

  @override
  State<Audios> createState() => _AudiosState();
}

class _AudiosState extends State<Audios> {
  @override
  void initState() {
    super.initState();
    // Registrar el callback para "detener"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProv = context.read<AudioProvider>();
      audioProv.setOnDetenerCallback(() async {
        try {
          final idDiag = await audioProv.stopListening();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Texto enviado para diagnóstico #$idDiag')),
          );
          Navigator.pushNamed(context, 'diagnosticos');
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al detener: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Transcripción en vivo')),
      body: Column(
        children: [
          // 1) Área de texto que crece y hace scroll si es muy largo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                audioProv.speechText,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2) Botones y confianza van abajo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: audioProv.canStart
                    ? () => audioProv.startListening()
                    : null,
                child: const Text('Iniciar'),
              ),
              ElevatedButton(
                onPressed: audioProv.canContinue
                    ? () => audioProv.continueListening()
                    : null,
                child: const Text('Continuar'),
              ),
              ElevatedButton(
                onPressed: audioProv.canStop
                    ? () async {
                        try {
                          final idDiag = await audioProv.stopListening();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Texto enviado para diagnóstico #$idDiag'),
                            ),
                          );

                          // Redirigir a la vista de Diagnóstico
                          Navigator.pushNamed(context, 'diagnosticos');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Error al detener: ${e.toString()}'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    : null,
                child: const Text('Detener'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confianza
          Text(
            'Confianza: ${(audioProv.confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
