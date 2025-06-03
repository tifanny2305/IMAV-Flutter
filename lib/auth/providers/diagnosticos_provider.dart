import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taller_1/Services/socket_service.dart';
import 'package:taller_1/models/diagnosticos.dart';

class DiagnosticosProvider extends ChangeNotifier {
  final SocketService _socketService;
  List<Diagnostico> diagnosticos = [];

  DiagnosticosProvider(this._socketService);

  Future<void> cargarDiagnosticos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final userId = prefs.getInt('userId');

    if (token.isEmpty || userId == null) {
      diagnosticos = [];
      notifyListeners();
      return;
    }

    try {
      // 1) Conectamos con el token JWT
      await _socketService.connect(token);

      // 2) Pedimos la lista “ya filtrada” desde el backend
      final listaInicial = await _socketService.fetchDiagnosticos();
      print('➡️ [Flutter] Lista recibida desde backend: $listaInicial');

      // Como el gateway ya filtra por usuario en server, tomamos todo:
      diagnosticos = listaInicial;
      notifyListeners();

      // 3) Si el backend emite 'refrescar-diagnosticos', volvemos a pedir la lista:
      _socketService.onRefrescarDiagnosticos(() async {
        final nuevaLista = await _socketService.fetchDiagnosticos();
        diagnosticos = nuevaLista;
        print('🔁 [Flutter] Lista refrescada: $diagnosticos');
        notifyListeners();
      });

      // 4) También podemos suscribirnos a “nuevo-diagnostico” (si el evento viene dirigido a este mecánico)
      _socketService.onNuevoDiagnostico((nuevo) {
        diagnosticos.add(nuevo);
        print('➕ [Flutter] Nuevo diagnóstico agregado: $nuevo');
        notifyListeners();
      });
    } catch (e) {
      diagnosticos = [];
      print('❌ [Flutter] Error en cargarDiagnosticos: $e');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    //_socketService.disconnect();
    super.dispose();
  }
}
