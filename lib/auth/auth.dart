import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UsuarioProvider with ChangeNotifier {
  String? _correo;
  String? _token;
  bool _isAuthenticated = false;

  //final String _baseUrl = 'http://10.0.2.2:3000/api/auth';
  final String _baseUrl = 'https://imav-motors-back.onrender.com/api/auth';

  // Getters
  String? get correo => _correo;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;

  // Login
  Future<bool> login(String correo, String clave) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'clave': clave,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        _correo = data['correo'];
        _token = data['token'];
        _isAuthenticated = true;

        // Decodifica el JWT para extraer el campo "id"
        final Map<String, dynamic> payload = JwtDecoder.decode(_token!);
        final int userId = payload['id'];

        // Guarda el token y correo en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', _token!);
        await prefs.setString('userEmail', _correo!);
        await prefs.setInt('userId', userId);
        

        print('✔️ Token guardado: $_token');
        print('✔️ Correo guardado: $_correo');
        print('✔️ userId extraído y guardado: $userId');

        notifyListeners();
        return true;
      } else {
        print('❌ Error de login: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userEmail');

    _correo = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<String?> cargarTokenDesdePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString('authToken');
    if (guardado != null && guardado.isNotEmpty) {
      _token = guardado;
      _correo = prefs.getString('userEmail');
      _isAuthenticated = true;
      notifyListeners();
    }
    return _token;
  }
}
