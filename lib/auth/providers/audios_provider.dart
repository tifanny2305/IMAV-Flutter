import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:taller_1/Services/socket_service.dart';

class AudioProvider with ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final SocketService socketService;

  bool _speechReady = false;
  bool _isListening = false;
  bool _socketReady = false;
  bool _listenersReady = false;
  int? diagnosticoId;

  String _buffer = '';
  double _confidence = 1.0;
  final List<String> _segments = [];

  // Estado público
  bool get isListening => _isListening;
  bool get canStart => !_isListening && _buffer.isEmpty;
  bool get canContinue => !_isListening && _buffer.isNotEmpty;
  bool get canStop => _isListening || _buffer.isNotEmpty;

  String get speechText =>
      _buffer.isEmpty ? 'Presiona “Iniciar” y habla…' : _buffer;
  double get confidence => _confidence;

  AudioProvider(this.socketService) {
    _initSpeech();
  }

  Future<void> _connectSocket() async {
    if (_socketReady && socketService.isConnected) {
      debugPrint('✅ Socket ya conectado');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        throw Exception('No hay token para conectar el socket');
      }

      await socketService.connect(token);
      _socketReady = true;

      debugPrint(
          '🔗 [AudioProvider] Socket conectado = ${socketService.isConnected}');

      // Registra listeners SOLO una vez
      if (!_listenersReady) {
        _setupSocketListeners();
        _listenersReady = true;
      }
    } catch (e) {
      debugPrint('❌ Error conectando socket: $e');
      rethrow;
    }
  }

  void _setupSocketListeners() {
    // Listener para "diagnostico-tomado"
    socketService.onDiagnosticoTomado((diagnostico) {
      debugPrint('✅ [AudioProvider] evento "diagnostico-tomado" recibido');
      // Aquí podrías actualizar el estado si es necesario
      notifyListeners();
    });

    // Listener para "diagnostico-finalizado"
    socketService.onDiagnosticoFinalizado((diagnostico) {
      debugPrint('✅ [AudioProvider] evento "diagnostico-finalizado" recibido');
      _resetState();
    });
  }

  void _resetState() {
    _segments.clear();
    _buffer = '';
    diagnosticoId = null;
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
    notifyListeners();
  }

  Future<void> ensureSocketReady() async {
    debugPrint('🔧 [AudioProvider] Verificando socket...');
    if (!_socketReady || !socketService.isConnected) {
      debugPrint('🔧 [AudioProvider] Conectando socket...');
      await _connectSocket();
    }
    debugPrint('✅ [AudioProvider] Socket listo');
  }

  void setDiagnosticoId(int id) {
    diagnosticoId = id;
    debugPrint('📝 [AudioProvider] ID diagnóstico establecido: $id');
  }

  Future<void> _initSpeech() async {
    try {
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (_isListening && (status == 'done' || status == 'notListening')) {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('STT error: $err');
          if (_isListening) {
            _isListening = false;
            notifyListeners();
          }
        },
      );

      if (!_speechReady) {
        throw Exception('Speech-to-text no disponible');
      }
      debugPrint('✅ Speech-to-text inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando STT: $e');
      rethrow;
    }
  }

  Future<void> startListening() async {
    debugPrint('🎤 Iniciando escucha...');

    if (!_speechReady) {
      await _initSpeech();
    }
    if (!_speechReady) return;

    try {
      await _speech.stop();

      _buffer = '';
      _segments.clear();
      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final fragment = result.recognizedWords.trim();
            if (fragment.isNotEmpty) {
              _segments.add(fragment);
              _buffer = _segments.join(' ');
              debugPrint('📝 Texto capturado: $fragment');
            }
            if (result.hasConfidenceRating && result.confidence > 0) {
              _confidence = result.confidence;
            }
            notifyListeners();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al iniciar escucha: $e');
      _isListening = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> continueListening() async {
    debugPrint('🎤 Continuando escucha...');

    if (!_speechReady || _isListening) return;

    try {
      await _speech.stop();

      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final fragment = result.recognizedWords.trim();
            if (fragment.isNotEmpty) {
              _segments.add(fragment);
              _buffer = _segments.join(' ');
              debugPrint('📝 Texto adicional: $fragment');
            }
            if (result.hasConfidenceRating && result.confidence > 0) {
              _confidence = result.confidence;
            }
            notifyListeners();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al continuar escucha: $e');
      _isListening = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<int?> stopListening() async {
    debugPrint('⏹️ Deteniendo escucha...');

    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }

    if (diagnosticoId == null) {
      throw Exception('No se ha establecido el ID del diagnóstico');
    }

    final textoFinal = _buffer.trim();
    debugPrint('📄 Texto final: "$textoFinal"');

    if (textoFinal.isEmpty) {
      throw Exception('Buffer vacío: no hay texto para enviar');
    }

    try {
      await ensureSocketReady();

      socketService.finalizarDiagnostico(
        id: diagnosticoId!,
        textoOriginal: textoFinal,
        textoDiagnostico: '',
        textoCliente: '',
      );

      debugPrint('✅ Diagnóstico enviado exitosamente');

      _segments.clear();
      _buffer = '';
      notifyListeners();

      return diagnosticoId!;
    } catch (e) {
      debugPrint('❌ Error enviando diagnóstico: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
