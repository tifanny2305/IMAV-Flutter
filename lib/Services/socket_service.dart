import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:taller_1/models/diagnosticos.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final String _serverUrl = 'http://192.168.1.4:3000';
  bool _isConnecting = false;

  IO.Socket get socket {
    if (_socket == null) {
      throw Exception('Socket no inicializado. Llama a connect() primero.');
    }
    return _socket!;
  }

  bool get isConnected => _socket?.connected ?? false;

  // Conecta al WebSocket con configuración optimizada
  Future<void> connect(String token) async {
    if (_isConnecting) {
      print('⏳ Ya conectando socket...');
      return;
    }

    if (_socket?.connected == true) {
      print('✅ Socket ya conectado');
      return;
    }

    _isConnecting = true;
    final completer = Completer<void>();

    try {
      _socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableReconnection()
            .setReconnectionAttempts(3)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(5000) // Timeout de conexión
            .setAuth({'token': token})
            .build(),
      );

      _socket!.on('connect', (_) {
        print('✅ WS conectado exitosamente');
        _isConnecting = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _socket!.on('disconnect', (reason) {
        print('❌ WS desconectado: $reason');
        _isConnecting = false;
      });

      _socket!.on('connect_error', (err) {
        print('⚠️ Error al conectar WebSocket: $err');
        _isConnecting = false;
        if (!completer.isCompleted) {
          completer.completeError(Exception('Error de conexión: $err'));
        }
      });

      // Timeout manual para evitar esperas infinitas
      Timer(Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          _isConnecting = false;
          completer.completeError(Exception('Timeout de conexión'));
        }
      });

      await completer.future;
    } catch (e) {
      _isConnecting = false;
      rethrow;
    }
  }

  // Método simplificado para tomar diagnóstico sin esperar respuesta
  void tomarDiagnostico(int id) {
    if (!isConnected) {
      print('⚠️ Socket no conectado');
      throw Exception('Socket no conectado');
    }
    
    print('🚀 [SocketService] Emito "tomar-diagnostico" con id=$id');
    _socket!.emit('tomar-diagnostico', {'diagnosticoId': id});
  }

  void onDiagnosticoTomado(void Function(Diagnostico) callback) {
    if (!isConnected) return;
    
    _socket!.on('diagnostico-tomado', (data) {
      print('👂 [SocketService] evento "diagnostico-tomado" → $data');
      try {
        final diag = Diagnostico.fromJson(data as Map<String, dynamic>);
        callback(diag);
      } catch (e) {
        print('❌ Error parseando diagnostico-tomado: $e');
      }
    });
  }

  void onDiagnosticoFinalizado(void Function(Diagnostico) callback) {
    if (!isConnected) return;
    
    _socket!.on('diagnostico-finalizado', (data) {
      print('👂 [SocketService] evento "diagnostico-finalizado" → $data');
      try {
        final diag = Diagnostico.fromJson(data as Map<String, dynamic>);
        callback(diag);
      } catch (e) {
        print('❌ Error parseando diagnostico-finalizado: $e');
      }
    });
  }

  // Método con timeout para evitar esperas infinitas
  Future<List<Diagnostico>> fetchDiagnosticos() async {
    if (!isConnected) {
      throw Exception('Socket no conectado');
    }

    final completer = Completer<List<Diagnostico>>();
    
    // Timeout de 10 segundos
    final timer = Timer(Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Timeout al obtener diagnósticos'));
      }
    });

    _socket!.emit('listar-diagnosticos');
    _socket!.once('lista-diagnosticos', (data) {
      timer.cancel();
      print('🔍 Payload lista-diagnosticos: $data');
      
      try {
        if (data == null || data is! List) {
          completer.complete(<Diagnostico>[]);
          return;
        }

        final rawList = data.cast<dynamic>();
        final listaSegura = rawList.where((e) => e != null && e is Map<String, dynamic>);
        final resultList = listaSegura
            .map((e) => Diagnostico.fromJson(e as Map<String, dynamic>))
            .toList();

        completer.complete(resultList);
      } catch (ex) {
        print('❌ Error parseando lista diagnósticos: $ex');
        completer.completeError(ex);
      }
    });

    return completer.future;
  }

  void onNuevoDiagnostico(void Function(Diagnostico) callback) {
    if (!isConnected) return;
    
    _socket!.on('nuevo-diagnostico', (data) {
      try {
        final diag = Diagnostico.fromJson(data as Map<String, dynamic>);
        callback(diag);
      } catch (e) {
        print('❌ Error parseando nuevo-diagnostico: $e');
      }
    });
  }

  void onRefrescarDiagnosticos(void Function() callback) {
    if (!isConnected) return;
    _socket!.on('refrescar-diagnosticos', (_) => callback());
  }

  void finalizarDiagnostico({
    required int id,
    required String textoOriginal,
    required String textoDiagnostico,
    required String textoCliente,
  }) {
    if (!isConnected) {
      print('⚠️ SocketService: no conectado');
      throw Exception('Socket no conectado');
    }

    print('🚀 Emisión -> finalizar-diagnostico: {'
        'diagnosticoId: $id, '
        'textoOriginal: "$textoOriginal", '
        'textoDiagnostico: "$textoDiagnostico", '
        'textoCliente: "$textoCliente"}');

    _socket!.emit('finalizar-diagnostico', {
      'diagnosticoId': id,
      'textoOriginal': textoOriginal,
      'textoDiagnostico': textoDiagnostico,
      'textoCliente': textoCliente,
    });
  }

  void off(String event) {
    _socket?.off(event);
  }

  void enviarTextoOriginal(int id, String textoOriginal) {
    if (!isConnected) {
      print('⚠️ Socket no conectado para enviar texto');
      return;
    }
    
    _socket!.emit('actualizarTextoOriginal', {
      'id': id,
      'textoOriginal': textoOriginal,
    });
    print('🚀 Enviado evento "actualizarTextoOriginal" {id: $id, textoOriginal: (...)}');
  }

    void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
  }
}