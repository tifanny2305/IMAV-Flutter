import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taller_1/auth/providers/audios_provider.dart';

class Audios extends StatefulWidget {
  const Audios({Key? key}) : super(key: key);

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
      // ********************** AppBar con degradado **********************
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 20, 18, 110), // #14126E
                Color.fromARGB(255, 22, 16, 190), // #160CBE
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Transcripción en vivo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ********************** Fondo rosa pastel **********************
      backgroundColor: const Color(0xFFF9F5FF),

      body: Stack(
        children: [
          Column(
            children: [
              // Espacio debajo del AppBar
              const SizedBox(height: 16),

              // ********************** Card de transcripción **********************
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 200),
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Text(
                          audioProv.speechText.isEmpty
                              ? 'Presiona “Iniciar” y habla…'
                              : audioProv.speechText,
                          style: const TextStyle(
                              fontSize: 20, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ********************** Texto de Confianza **********************
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Confianza: ${(audioProv.confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

              const SizedBox(height: 80), // Margen para la barra inferior
            ],
          ),

          // ********************** Indicador “Grabando…” justo debajo del AppBar **********************
          if (audioProv.isListening)
            const Positioned(
              top: 16, // Un poco debajo del AppBar
              right: 24, // mismo padding horizontal que el Card
              child: _GrabandoIndicator(),
            ),

          // ********************** Barra inferior con tres botones **********************
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 6,
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BotonAccion(
                    icono: Icons.mic,
                    texto: 'Iniciar',
                    colorActivo: const Color(0xFF14126E),
                    habilitado: audioProv.canStart,
                    onPressed: audioProv.canStart
                        ? () => audioProv.startListening()
                        : null,
                  ),
                  _BotonAccion(
                    icono: Icons.replay,
                    texto: 'Continuar',
                    colorActivo: const Color(0xFF7E57C2),
                    habilitado: audioProv.canContinue,
                    onPressed: audioProv.canContinue
                        ? () => audioProv.continueListening()
                        : null,
                  ),
                  _BotonAccion(
                    icono: Icons.camera_alt,
                    texto: 'Foto',
                    colorActivo: const Color(0xFF009688),
                    habilitado: audioProv.canTakePhoto,
                    onPressed: audioProv.canTakePhoto
                        ? () => audioProv.tomarFoto(context)
                        : null,
                  ),
                  _BotonAccion(
                    icono: Icons.stop,
                    texto: 'Detener',
                    colorActivo: const Color(0xFFC62828),
                    habilitado: audioProv.canStop,
                    onPressed: audioProv.canStop
                        ? () async {
                            try {
                              final idDiag = await audioProv.stopListening();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Texto enviado (#$idDiag)')),
                              );
                              Navigator.pushNamed(context, 'diagnosticos');
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al detener: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Botón reutilizable con diseño vertical
class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color colorActivo;
  final bool habilitado;
  final VoidCallback? onPressed;

  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.colorActivo,
    required this.habilitado,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = habilitado ? colorActivo : Colors.grey[400];
    final fondo = Colors.white; // Siempre blanco para evitar salto visual
    final borde = BorderSide(
      color: habilitado ? colorActivo : Colors.grey[300]!,
      width: 1.5,
    );

    return Flexible(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borde,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget separado para el indicador “Grabando…”
class _GrabandoIndicator extends StatelessWidget {
  const _GrabandoIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 600),
          child: SizedBox(
            width: 12,
            height: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        SizedBox(width: 6),
        Text(
          'Grabando…',
          style: TextStyle(
            fontSize: 14,
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
