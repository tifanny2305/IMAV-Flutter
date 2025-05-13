import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UsuarioProvider with ChangeNotifier {
  String? _correo;
  String? _token;
  bool _isAuthenticated = false;

  // URL base de tu API NestJS (ajusta a tu IP o dominio)
  final String _baseUrl = 'http://10.0.2.2:3000/api/auth';

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

  void logout() {
    _correo = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
