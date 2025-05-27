import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AudioProvider with ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;

  String _buffer = '';
  double _confidence = 1.0;

  // Estado público
  bool get isListening => _isListening;
  bool get canStart => !_isListening && _buffer.isEmpty;
  bool get canContinue => !_isListening && _buffer.isNotEmpty;
  bool get canStop => _isListening || _buffer.isNotEmpty;

  String get speechText =>
      _buffer.isEmpty ? 'Presiona “Iniciar” y habla…' : _buffer;
  double get confidence => _confidence;

  AudioProvider() {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        debugPrint('STT status: $status');
        if (_isListening && (status == 'done' || status == 'notListening')) {
          // el motor cortó por silencio → pasa a “pausado”
          _isListening = false;
          notifyListeners();
        }
      },
      onError: (err) => debugPrint('STT init error: $err'),
    );
    if (!_speechReady) {
      throw Exception('Speech-to-text no disponible');
    }
  }

  /// 1️⃣ Iniciar desde cero
  Future<void> startListening() async {
    if (!_speechReady) await _initSpeech();
    if (!_speechReady) return;

    _buffer = '';
    _isListening = true;
    _startSession();
    notifyListeners();
  }

  /// 2️⃣ Continuar acumulando (tras silencio)
  Future<void> continueListening() async {
    if (!_speechReady || _isListening) return;

    _isListening = true;
    _startSession();
    notifyListeners();
  }

  /// 3️⃣ Detener y volcar resultado final
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    // imprime el buffer completo
    debugPrint('📋 Transcripción final: $_buffer');

    // resetea para la siguiente sesión
    _buffer = '';
    notifyListeners();
  }

  void _startSession() {
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            // acumulamos en el buffer
            _buffer = _buffer.isEmpty ? words : '$_buffer $words';
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
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
