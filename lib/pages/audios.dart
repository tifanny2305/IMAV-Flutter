import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:taller_1/auth/providers/audios_provider.dart';

class Audios extends StatefulWidget {
  const Audios({Key? key}) : super(key: key);

  @override
  State<Audios> createState() => _AudiosState();
}

class _AudiosState extends State<Audios> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();

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

// ==================== NUEVOS MÉTODOS PARA CÁMARA ====================
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false, // No necesitamos audio de cámara
        );

        await _cameraController!.initialize();

        if (mounted && !_isDisposed) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error inicializando cámara: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _capturarFotoDesdeCamera() async {
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cámara no disponible'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Capturar imagen desde la cámara en tiempo real
      final image = await _cameraController!.takePicture();

      // Usar el método del AudioProvider para procesar
      final audioProv = context.read<AudioProvider>();
      await audioProv.procesarImagenCapturada(image.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Foto capturada'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error capturando foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    try {
      final currentIndex = _cameras!.indexOf(_cameraController!.description);
      final nextIndex = (currentIndex + 1) % _cameras!.length;

      await _cameraController?.dispose();

      _cameraController = CameraController(
        _cameras![nextIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Error cambiando cámara: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioProvider>();

    return Scaffold(
      // ==================== AppBar TRANSPARENTE ====================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Diagnóstico en Vivo',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isCameraInitialized && _cameras != null && _cameras!.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.cameraswitch_outlined,
                    color: Colors.white),
                onPressed: _switchCamera,
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,

      body: Stack(
        children: [
          // ==================== FONDO DE CÁMARA ====================
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Inicializando cámara...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // ==================== GRID DE COMPOSICIÓN ====================
          if (_isCameraInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),

          // ==================== TRANSCRIPCIÓN OVERLAY ====================
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.record_voice_over,
                          color:
                              audioProv.isListening ? Colors.red : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          audioProv.isListening
                              ? 'Grabando...'
                              : 'Transcripción',
                          style: TextStyle(
                            color: audioProv.isListening
                                ? Colors.red
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Confianza: ${(audioProv.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      audioProv.speechText.isEmpty
                          ? 'Presiona "Iniciar" y habla...'
                          : audioProv.speechText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==================== INDICADOR DE GRABACIÓN ====================
          if (audioProv.isListening)
            Positioned(
              top: 60,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ==================== CONTROLES INFERIORES ====================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BotonAccionCamera(
                      icono: Icons.mic,
                      texto: 'Iniciar',
                      colorActivo: const Color(0xFF4CAF50),
                      habilitado: audioProv.canStart,
                      onPressed: audioProv.canStart
                          ? () => audioProv.startListening()
                          : null,
                    ),
                    _BotonAccionCamera(
                      icono: Icons.replay,
                      texto: 'Continuar',
                      colorActivo: const Color(0xFF2196F3),
                      habilitado: audioProv.canContinue,
                      onPressed: audioProv.canContinue
                          ? () => audioProv.continueListening()
                          : null,
                    ),
                    _BotonAccionCamera(
                      icono: Icons.camera_alt,
                      texto: 'Foto',
                      colorActivo: const Color(0xFFFF9800),
                      habilitado:
                          audioProv.canTakePhoto && _isCameraInitialized,
                      onPressed:
                          (audioProv.canTakePhoto && _isCameraInitialized)
                              ? _capturarFotoDesdeCamera // ← CAMBIADO AQUÍ
                              : null,
                    ),
                    _BotonAccionCamera(
                      icono: Icons.stop,
                      texto: 'Detener',
                      colorActivo: const Color(0xFFF44336),
                      habilitado: audioProv.canStop,
                      onPressed: audioProv.canStop
                          ? () async {
                              try {
                                final idDiag = await audioProv.stopListening();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Texto enviado (#$idDiag)')),
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
          ),
        ],
      ),
    );
  }
}

// ==================== BOTÓN MODIFICADO PARA CÁMARA ====================
class _BotonAccionCamera extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color colorActivo;
  final bool habilitado;
  final VoidCallback? onPressed;

  const _BotonAccionCamera({
    required this.icono,
    required this.texto,
    required this.colorActivo,
    required this.habilitado,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: habilitado ? colorActivo : Colors.grey.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onPressed,
              child: Icon(
                icono,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          texto,
          style: TextStyle(
            color: habilitado ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ==================== GRID PAINTER ====================
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1;

    // Líneas verticales (regla de tercios)
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Líneas horizontales (regla de tercios)
    for (int i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
