import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:taller_1/Services/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:taller_1/Services/http_service.dart';

typedef OnDetenerCallback = Future<void> Function();
typedef OnCapturaCallback = Future<void> Function();

class AudioProvider with ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final SocketService socketService;

  bool get canTakePhoto => diagnosticoId != null;

  PorcupineManager? _porcupineIniciar;
  PorcupineManager? _porcupineContinuar;
  PorcupineManager? _porcupineDetener;
  PorcupineManager? _porcupineCaptura;

  final List<File> _imagenesTemporales = [];
  final List<Map<String, dynamic>> _imagenesMetadata = [];

  List<Map<String, dynamic>> get imagenesMetadata => _imagenesMetadata;

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
    _initPorcupineMultiples();
  }

  OnDetenerCallback? _onDetenerCallback;
  OnCapturaCallback? _onCapturaCallback;

  void setOnDetenerCallback(OnDetenerCallback callback) {
    _onDetenerCallback = callback;
  }

  void setOnCapturaCallback(OnCapturaCallback callback) {
    _onCapturaCallback = callback;
  }

  Future<void> _initPorcupineMultiples() async {
    // Cada clave trabaja con su propio modelo .ppn
    const String KEY_INICIAR =
        'HKVb97cL0NGbQUHp6l1M0o7lHvsFDjBhh8YmUaedxZqkW2PcXfNFdQ==';
    const String KEY_CONTINUAR =
        'SXsVFq1/dJGvJnsXqg1l7Twgo8y5Vmif3dRRDmfu/m7k5fVjLR0rig==';
    const String KEY_DETENER =
        'Og1QbccO6erg/eMNcEB4kLMObukHofBSnT0ywwG5vyNGxyMPF8AUPQ==';
    const String KEY_CAPTURA =
        'cxL8O6/D4Qnww5QMyvoaE58JVsUFqYU56rHJeNOVEEBc8a4BuYxXrQ==';

    // Comprobamos primero que los assets existen:
    bool existeParams = await rootBundle
        .load('assets/porcupine_params_es.pv')
        .then((_) => true)
        .catchError((_) => false);
    debugPrint('¿porcupine_params_es.pv existe? → $existeParams');

    bool existeIniciar = await rootBundle
        .load('assets/keywords/iniciar_es_android_v3_0_0.ppn')
        .then((_) => true)
        .catchError((_) => false);
    debugPrint('¿iniciar_es_android_v3_0_0.ppn existe? → $existeIniciar');

    bool existeContinuar = await rootBundle
        .load('assets/keywords/continuar_es_android_v3_0_0.ppn')
        .then((_) => true)
        .catchError((_) => false);
    debugPrint('¿continuar_es_android_v3_0_0.ppn existe? → $existeContinuar');

    bool existeDetener = await rootBundle
        .load('assets/keywords/finalizar_es_android_v3_0_0.ppn')
        .then((_) => true)
        .catchError((_) => false);
    debugPrint('¿detener_es_android_v3_0_0.ppn existe? → $existeDetener');

    bool existeCaptura = await rootBundle
        .load('assets/keywords/captura_es_android_v3_0_0.ppn')
        .then((_) => true)
        .catchError((_) => false);
    debugPrint('¿captura_es_android_v3_0_0.ppn existe? → $existeCaptura');

    if (!existeParams ||
        !existeIniciar ||
        !existeContinuar ||
        !existeDetener ||
        !existeCaptura) {
      debugPrint(
          '❌ Faltan assets de Porcupine. No inicializo instancias múltiples.');
      return;
    }

    try {
      // --- Instancia “Iniciar” ---
      _porcupineIniciar = await PorcupineManager.fromKeywordPaths(
        KEY_INICIAR,
        ['assets/keywords/iniciar_es_android_v3_0_0.ppn'],
        (int keywordIndex) {
          // índice siempre 0 aquí (solo un modelo en esta instancia)
          debugPrint('🔑 Porcupine(INICIAR) detectó “iniciar”');
          _onIniciarDetected();
        },
        modelPath: 'assets/porcupine_params_es.pv',
        sensitivities: [0.5],
        errorCallback: (error) {
          debugPrint('❌ Porcupine(INICIAR) error: $error');
        },
      );
      await _porcupineIniciar?.start();
      debugPrint('🔊 Porcupine(INICIAR) corriendo…');

      // --- Instancia “Continuar” ---
      _porcupineContinuar = await PorcupineManager.fromKeywordPaths(
        KEY_CONTINUAR,
        ['assets/keywords/continuar_es_android_v3_0_0.ppn'],
        (int keywordIndex) {
          debugPrint('🔑 Porcupine(CONTINUAR) detectó “continuar”');
          _onContinuarDetected();
        },
        modelPath: 'assets/porcupine_params_es.pv',
        sensitivities: [0.5],
        errorCallback: (error) {
          debugPrint('❌ Porcupine(CONTINUAR) error: $error');
        },
      );
      await _porcupineContinuar?.start();
      debugPrint('🔊 Porcupine(CONTINUAR) corriendo…');

      // --- Instancia FINALIZAR ---
      _porcupineDetener = await PorcupineManager.fromKeywordPaths(
        KEY_DETENER,
        ['assets/keywords/finalizar_es_android_v3_0_0.ppn'],
        (int keywordIndex) {
          debugPrint('🔑 Porcupine(FINALIZAR) detectó “finalizar”');
          _onDetenerDetected();
        },
        modelPath: 'assets/porcupine_params_es.pv',
        sensitivities: [0.5],
        errorCallback: (error) {
          debugPrint('❌ Porcupine(FINALIZAR) error: $error');
        },
      );
      await _porcupineDetener?.start();
      debugPrint('🔊 Porcupine(FINALIZAR) corriendo…');

      // --- Instancia “Captura” ---
      _porcupineCaptura = await PorcupineManager.fromKeywordPaths(
        KEY_CAPTURA,
        ['assets/keywords/captura_es_android_v3_0_0.ppn'],
        (int keywordIndex) {
          debugPrint('🔑 Porcupine(CAPTURA) detectó “captura”');
          _onCapturaDetected();
        },
        modelPath: 'assets/porcupine_params_es.pv',
        sensitivities: [0.5],
        errorCallback: (error) {
          debugPrint('❌ Porcupine(CAPTURA) error: $error');
        },
      );
      await _porcupineCaptura?.start();
      debugPrint('🔊 Porcupine(CAPTURA) corriendo…');
    } catch (e) {
      debugPrint('❌ Error inicializando instancias múltiples: $e');
    }
  }

  // -----------------------------------------
  // Métodos callback para cada hotword
  void _onIniciarDetected() {
    if (!_speechReady || _isListening) return;
    startListening();
  }

  void _onContinuarDetected() {
    if (!_speechReady || _isListening) return;
    if (_buffer.isNotEmpty) continueListening();
  }

  void _onDetenerDetected() {
    if (_isListening || _buffer.isNotEmpty) {
      if (_onDetenerCallback != null) {
        _onDetenerCallback!();
      } else {
        stopListening();
      }
    }
  }

  void _onCapturaDetected() {
    if (diagnosticoId != null) {
      debugPrint('📸 Comando "captura" detectado durante grabación');
      if (_onCapturaCallback != null) {
        _onCapturaCallback!();
      }
    } else {
      debugPrint(
          '⚠️ Comando "captura" ignorado - no está grabando o sin diagnóstico');
    }
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
    _imagenesTemporales.clear();
    _imagenesMetadata.clear();
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

      List<String> urlsImagenes = [];

      // 🔍 DEBUG: Estado de las imágenes antes de subir
      debugPrint('🔍 === ESTADO ANTES DE SUBIR ===');
      debugPrint('📸 Imágenes temporales: ${_imagenesTemporales.length}');
      debugPrint('📊 Metadata: ${_imagenesMetadata.length}');
      debugPrint('🆔 Diagnóstico ID: $diagnosticoId');

      for (int i = 0; i < _imagenesTemporales.length; i++) {
        final file = _imagenesTemporales[i];
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;
        debugPrint(
            '📁 Archivo $i: ${file.path} - Existe: $exists - Tamaño: $size bytes');
      }

      if (_imagenesTemporales.isNotEmpty) {
        debugPrint('🚀 === INICIANDO SUBIDA DE IMÁGENES ===');

        try {
          // Verificar archivos antes de enviar
          final archivosValidos = <File>[];
          for (final file in _imagenesTemporales) {
            if (await file.exists() && await file.length() > 0) {
              archivosValidos.add(file);
              debugPrint('✅ Archivo válido: ${file.path}');
            } else {
              debugPrint('❌ Archivo inválido o vacío: ${file.path}');
            }
          }

          if (archivosValidos.isEmpty) {
            debugPrint('⚠️ No hay archivos válidos para subir');
          } else {
            debugPrint(
                '📤 Subiendo ${archivosValidos.length} archivos válidos...');
            urlsImagenes =
                await HttpService.uploadImages(diagnosticoId!, archivosValidos);
            debugPrint('✅ URLs recibidas: ${urlsImagenes.length}');

            for (int i = 0; i < urlsImagenes.length; i++) {
              debugPrint('🔗 URL $i: ${urlsImagenes[i]}');
            }
          }
        } catch (uploadError) {
          debugPrint('❌ === ERROR EN SUBIDA ===');
          debugPrint('Error tipo: ${uploadError.runtimeType}');
          debugPrint('Error mensaje: $uploadError');
          debugPrint('Stack trace: ${StackTrace.current}');
          debugPrint('❌ === FIN ERROR SUBIDA ===');

          // Por ahora no fallar, pero sí loguear
          debugPrint('⚠️ Continuando sin imágenes debido al error');
        }
      } else {
        debugPrint('ℹ️ No hay imágenes para subir');
      }

      // Construir JSON con debugging
      debugPrint('🔧 === CONSTRUYENDO JSON ===');
      debugPrint('📝 Texto: "${_buffer.trim()}"');
      debugPrint('🔗 URLs disponibles: ${urlsImagenes.length}');
      debugPrint('📊 Metadata disponible: ${_imagenesMetadata.length}');

      final textoOriginalJson =
          _construirTextoOriginalJson(_buffer.trim(), urlsImagenes);
      debugPrint(
          '📋 JSON final length: ${textoOriginalJson.length} caracteres');

      /*socketService.finalizarDiagnostico(
        id: diagnosticoId!,
        textoOriginal: textoOriginalJson,
        textoDiagnostico: '',
        textoCliente: '',
      );*/

      await finalizarDiagnosticoConIA(textoOriginalJson);

      debugPrint('✅ Diagnóstico enviado exitosamente');

      _segments.clear();
      _buffer = '';
      _imagenesTemporales.clear();
      _imagenesMetadata.clear();
      notifyListeners();

      return diagnosticoId!;
    } catch (e) {
      debugPrint('❌ Error enviando diagnóstico: $e');
      rethrow;
    }
  }

  Future<void> finalizarDiagnosticoConIA(String textoOriginalJson) async {
    final iaResponse = await HttpService().procesarTextoIA(textoOriginalJson);

    socketService.finalizarDiagnostico(
      id: diagnosticoId!,
      textoOriginal: textoOriginalJson,
      textoDiagnostico: iaResponse['texto_diagnostico'],
      textoCliente: iaResponse['texto_cliente'],
    );
  }

  String _construirTextoOriginalJson(String transcripcion, List<String> urls) {
    final Map<String, dynamic> jsonData = {};

    // Si no hay fotos, todo es una sola transcripción
    if (_imagenesMetadata.isEmpty || urls.isEmpty) {
      jsonData['transcripcion_primera'] =
          transcripcion.replaceAll(' FOTO ', '').trim();
      return jsonEncode(jsonData);
    }

    // Crear lista de puntos de corte con URLs
    final List<Map<String, dynamic>> puntosCorte = [];

    for (int i = 0; i < _imagenesMetadata.length && i < urls.length; i++) {
      puntosCorte.add({
        'posicion': _imagenesMetadata[i]['posicion_en_texto'],
        'timestamp': _imagenesMetadata[i]['timestamp'],
        'url': urls[i],
        'descripcion_contexto': _imagenesMetadata[i]['descripcion_contexto'],
      });
    }

    // Ordenar por posición en el texto
    puntosCorte.sort((a, b) => a['posicion'].compareTo(b['posicion']));

    debugPrint('🔍 === DEBUG SEGMENTACIÓN ===');
    debugPrint('📝 Transcripción completa: "$transcripcion"');
    debugPrint('📊 Puntos de corte: ${puntosCorte.length}');
    for (int i = 0; i < puntosCorte.length; i++) {
      debugPrint(
          '   Punto $i: posición ${puntosCorte[i]['posicion']} - URL: ${puntosCorte[i]['url']}');
    }

    int posicionAnterior = 0;
    int numeroTranscripcion = 1;

    for (int i = 0; i < puntosCorte.length; i++) {
      final puntoCorte = puntosCorte[i];
      final posicionCorte = puntoCorte['posicion'] as int;

      // Extraer texto desde la posición anterior hasta esta foto
      String textoSegmento = '';
      if (posicionCorte > posicionAnterior) {
        // Buscar el inicio del marcador " FOTO " antes de la posición
        String textoCompleto =
            transcripcion.substring(posicionAnterior, posicionCorte);

        // Remover el marcador " FOTO " que puede estar al final
        textoSegmento = textoCompleto.replaceAll(' FOTO ', '').trim();
      }

      debugPrint('📄 Segmento $numeroTranscripcion: "$textoSegmento"');

      // Solo agregar si hay texto significativo
      if (textoSegmento.isNotEmpty) {
        final String keyTranscripcion =
            _obtenerNombreTranscripcion(numeroTranscripcion);
        final String keyImagenes = _obtenerNombreImagenes(numeroTranscripcion);

        jsonData[keyTranscripcion] = textoSegmento;

        // Agregar imagen(es) para esta transcripción
        final List<Map<String, dynamic>> imagenesSegmento = [];

        // Buscar todas las fotos que pertenecen a este segmento
        // (pueden ser varias si se tomaron consecutivamente)
        imagenesSegmento.add({
          'timestamp': puntoCorte['timestamp'],
          'url': puntoCorte['url'],
          'descripcion_contexto': puntoCorte['descripcion_contexto'],
        });

        // Verificar si hay más fotos consecutivas en este segmento
        int j = i + 1;
        while (j < puntosCorte.length) {
          final siguientePunto = puntosCorte[j];
          final siguientePosicion = siguientePunto['posicion'] as int;

          // Si la siguiente foto está muy cerca (menos de 10 caracteres),
          // considerarla parte del mismo segmento
          if (siguientePosicion - posicionCorte < 10) {
            imagenesSegmento.add({
              'timestamp': siguientePunto['timestamp'],
              'url': siguientePunto['url'],
              'descripcion_contexto': siguientePunto['descripcion_contexto'],
            });
            i = j; // Saltar esta foto en la siguiente iteración
            j++;
          } else {
            break;
          }
        }

        jsonData[keyImagenes] = imagenesSegmento;
        numeroTranscripcion++;
      }

      // Actualizar posición: saltar el marcador " FOTO " (6 caracteres)
      posicionAnterior = posicionCorte + 6;
    }

    // Agregar texto restante después de la última foto
    if (posicionAnterior < transcripcion.length) {
      final textoFinal = transcripcion
          .substring(posicionAnterior)
          .replaceAll(' FOTO ', '')
          .trim();

      debugPrint('📄 Texto final: "$textoFinal"');

      if (textoFinal.isNotEmpty) {
        final String keyTranscripcion =
            _obtenerNombreTranscripcion(numeroTranscripcion);
        jsonData[keyTranscripcion] = textoFinal;
      }
    }

    debugPrint('🎯 JSON final keys: ${jsonData.keys.toList()}');
    return jsonEncode(jsonData);
  }

  String _obtenerNombreTranscripcion(int numero) {
    return 'transcripcion_$numero';
  }

  String _obtenerNombreImagenes(int numero) {
    return 'imagenes_$numero';
  }

  String extraerContextoDesdeTexto() {
    final palabras = _buffer.split(' ');
    if (palabras.length <= 2) return 'Sin contexto';
    final contexto = palabras.sublist(palabras.length - 5, palabras.length - 1);
    return contexto.join(' ');
  }

  Future<void> tomarFoto(BuildContext context) async {
    debugPrint('📸 === INICIANDO TOMA DE FOTO ===');

    if (_isListening) {
      await _speech.stop(); // Pausar grabación
      _isListening = false;
    }

    try {
      final picker = ImagePicker();
      debugPrint('📷 Abriendo cámara...');

      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        debugPrint('📁 Archivo seleccionado: ${pickedFile.path}');

        final File imageFile = File(pickedFile.path);

        // Verificaciones exhaustivas
        final exists = await imageFile.exists();
        debugPrint('✅ Archivo existe: $exists');

        if (exists) {
          final fileSize = await imageFile.length();
          debugPrint('📊 Tamaño del archivo: $fileSize bytes');

          if (fileSize > 0) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;

            // Agregar marcador al texto (como tenías antes)
            _buffer += ' FOTO ';
            debugPrint('📝 Marcador agregado al buffer: FOTO');

            // 🔥 CRÍTICO: Agregar a la lista temporal
            _imagenesTemporales.add(imageFile);
            debugPrint(
                '📸 Imagen agregada a lista temporal. Total: ${_imagenesTemporales.length}');

            // 🔥 CRÍTICO: Crear metadata (esto faltaba en tu código)
            final metadata = {
              'timestamp': timestamp,
              'posicion_en_texto': _buffer.length,
              'descripcion_contexto': extraerContextoDesdeTexto(),
              'path_temporal': imageFile.path,
              'size_bytes': fileSize,
            };

            _imagenesMetadata.add(metadata);
            debugPrint('📊 Metadata creada: $metadata');
            debugPrint('📊 Total metadata: ${_imagenesMetadata.length}');

            // Verificar que se puede leer el archivo
            try {
              final bytes = await imageFile.readAsBytes();
              debugPrint('✅ Archivo leíble: ${bytes.length} bytes en memoria');
            } catch (readError) {
              debugPrint('❌ Error leyendo archivo: $readError');
            }
          } else {
            debugPrint('❌ Archivo vacío (0 bytes)');
          }
        } else {
          debugPrint('❌ El archivo no existe en la ruta especificada');
        }
      } else {
        debugPrint('📷 Usuario canceló la toma de foto');
      }

      debugPrint('📸 === FIN TOMA DE FOTO ===');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error en toma de foto: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> procesarImagenCapturada(String imagePath) async {
    debugPrint('📸 === PROCESANDO IMAGEN CAPTURADA ===');

    if (_isListening) {
      // Pausar grabación temporalmente
      await _speech.stop();
      _isListening = false;
    }

    try {
      final File imageFile = File(imagePath);

      // Verificaciones
      final exists = await imageFile.exists();
      debugPrint('✅ Archivo existe: $exists');

      if (exists) {
        final fileSize = await imageFile.length();
        debugPrint('📊 Tamaño del archivo: $fileSize bytes');

        if (fileSize > 0) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          // Agregar marcador al texto
          _buffer += ' FOTO ';
          debugPrint('📝 Marcador agregado al buffer: FOTO');

          // Agregar a la lista temporal
          _imagenesTemporales.add(imageFile);
          debugPrint(
              '📸 Imagen agregada a lista temporal. Total: ${_imagenesTemporales.length}');

          // Crear metadata
          final metadata = {
            'timestamp': timestamp,
            'posicion_en_texto': _buffer.length,
            'descripcion_contexto': extraerContextoDesdeTexto(),
            'path_temporal': imageFile.path,
            'size_bytes': fileSize,
            'capturada_en_vivo': true, // Marca para distinguir de gallery
          };

          _imagenesMetadata.add(metadata);
          debugPrint('📊 Metadata creada: $metadata');
          debugPrint('📊 Total metadata: ${_imagenesMetadata.length}');

          // Verificar que se puede leer el archivo
          try {
            final bytes = await imageFile.readAsBytes();
            debugPrint('✅ Archivo leíble: ${bytes.length} bytes en memoria');
          } catch (readError) {
            debugPrint('❌ Error leyendo archivo: $readError');
          }
        } else {
          debugPrint('❌ Archivo vacío (0 bytes)');
          throw Exception('Imagen capturada está vacía');
        }
      } else {
        debugPrint('❌ El archivo no existe en la ruta especificada');
        throw Exception('No se pudo acceder a la imagen capturada');
      }

      debugPrint('📸 === FIN PROCESAMIENTO IMAGEN ===');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error procesando imagen capturada: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
