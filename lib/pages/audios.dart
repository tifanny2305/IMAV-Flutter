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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          style: const TextStyle(fontSize: 20, color: Colors.black87),
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
              top: 16,   // Un poco debajo del AppBar
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
                  // ------ BOTÓN “INICIAR” ------
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: ElevatedButton(
                        onPressed: audioProv.canStart
                            ? () => audioProv.startListening()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              audioProv.canStart ? Colors.white : Colors.grey[200],
                          elevation: audioProv.canStart ? 2 : 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: audioProv.canStart
                                ? const BorderSide(
                                    color: Color(0xFF14126E),
                                    width: 1.5,
                                  )
                                : BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic,
                              size: 18,
                              color: audioProv.canStart
                                  ? const Color(0xFF14126E)
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Iniciar',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: audioProv.canStart
                                      ? const Color(0xFF14126E)
                                      : Colors.grey[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ------ BOTÓN “CONTINUAR” COMO ÍCONO + TEXTO EN COLUMNA ------
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: audioProv.canContinue
                            ? () => audioProv.continueListening()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              audioProv.canContinue ? Colors.white : Colors.grey[200],
                          elevation: audioProv.canContinue ? 2 : 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: audioProv.canContinue
                                ? const BorderSide(
                                    color: Color(0xFF7E57C2),
                                    width: 1.5,
                                  )
                                : BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.replay,
                              size: 20,
                              color: audioProv.canContinue
                                  ? const Color(0xFF7E57C2)
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                'Continuar',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: audioProv.canContinue
                                      ? const Color(0xFF7E57C2)
                                      : Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ------ BOTÓN “DETENER” ------
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      child: ElevatedButton(
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
                                  Navigator.pushNamed(context, 'diagnosticos');
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error al detener: ${e.toString()}'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              audioProv.canStop ? Colors.white : Colors.grey[200],
                          elevation: audioProv.canStop ? 2 : 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: audioProv.canStop
                                ? const BorderSide(
                                    color: Color(0xFFC62828),
                                    width: 1.5,
                                  )
                                : BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.stop,
                              size: 18,
                              color: audioProv.canStop
                                  ? const Color(0xFFC62828)
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Detener',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: audioProv.canStop
                                      ? const Color(0xFFC62828)
                                      : Colors.grey[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
