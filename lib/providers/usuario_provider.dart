import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';

class UsuarioProvider with ChangeNotifier {
  Usuario? _usuario;
  bool _isAuthenticated = false;
  String? _token; // si usas JWT u otro token de autenticación

  // URL base de tu API (ajusta esta)
  final String _baseUrl = 'https://tubackend.com/api';

  // Getters
  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _isAuthenticated;

  // Login con API
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _usuario = Usuario.fromJson(data['usuario']);
        _token = data['token'];  // si tu backend devuelve un token
        _isAuthenticated = true;

        notifyListeners();
        return true;
      } else {
        print('Error de login: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  // Registro con API
  Future<bool> registrarUsuario(Usuario usuario) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson()),
      );

      if (response.statusCode == 201) {
        print('Usuario registrado con éxito');
        return true;
      } else {
        print('Error en registro: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en registro: $e');
      return false;
    }
  }

  // Obtener perfil (requiere token)
  Future<bool> obtenerPerfil() async {
    if (_token == null) return false;

    final url = Uri.parse('$_baseUrl/perfil');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _usuario = Usuario.fromJson(data['usuario']);
        notifyListeners();
        return true;
      } else {
        print('Error al obtener perfil: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error al obtener perfil: $e');
      return false;
    }
  }

  // Logout
  void logout() {
    _usuario = null;
    _isAuthenticated = false;
    _token = null;
    notifyListeners();
  }
}
