import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HttpService {
  static const String baseUrl = 'http://192.168.1.5:3000';

  static Future<List<String>> uploadImages(
      int diagnosticoId, List<File> imagenes) async {
    if (imagenes.isEmpty) return [];

    print('🔍 === DEBUG COMPLETO INICIADO ===');
    print('📋 Diagnóstico ID: $diagnosticoId');
    print('📸 Cantidad de imágenes: ${imagenes.length}');

    // Construir URL con /api
    final uploadUrl = '$baseUrl/api/diagnosticos/$diagnosticoId/upload-images';
    print('🔗 URL de upload: $uploadUrl');

    try {
      // 1. Probar conectividad básica primero
      print('🔍 1. Probando conectividad básica...');
      try {
        final basicTest = await http.get(
          Uri.parse('$baseUrl/api/diagnosticos'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 5));
        print('✅ Conectividad básica: ${basicTest.statusCode}');
      } catch (e) {
        print('❌ Error conectividad: $e');
      }

      // 2. Verificar que el diagnóstico específico existe
      print('🔍 2. Verificando diagnóstico específico...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      try {
        final diagTest = await http.get(
          Uri.parse('$baseUrl/api/diagnosticos/$diagnosticoId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 5));
        print('✅ Diagnóstico existe: ${diagTest.statusCode}');
        if (diagTest.statusCode == 200) {
          final diagData = jsonDecode(diagTest.body);
          print('📋 Estado del diagnóstico: ${diagData['estado']}');
        }
      } catch (e) {
        print('❌ Error verificando diagnóstico: $e');
      }

      // 3. Probar el endpoint con método GET (para ver si existe)
      print('🔍 3. Probando endpoint con GET...');
      try {
        final endpointTest = await http.get(
          Uri.parse(uploadUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 5));
        print('📡 GET al endpoint: ${endpointTest.statusCode}');
        print('📄 Respuesta GET: ${endpointTest.body}');
      } catch (e) {
        print('❌ Error en GET: $e');
      }

      // 4. Crear la petición multipart
      print('🔍 4. Creando petición multipart...');
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      print('🔑 Token agregado: ${token.length} caracteres');

      // Agregar archivos
      print('🔍 5. Agregando archivos...');
      for (int i = 0; i < imagenes.length; i++) {
        final file = imagenes[i];
        final size = await file.length();

        print('📁 Archivo $i: ${file.path} (${size} bytes)');

        final multipartFile = await http.MultipartFile.fromPath(
          'images', // Campo 'images' como espera el backend
          file.path,
          filename:
              'imagen_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        request.files.add(multipartFile);
      }

      print('📊 Petición preparada:');
      print('   - URL: ${request.url}');
      print('   - Método: ${request.method}');
      print('   - Headers: ${request.headers}');
      print('   - Archivos: ${request.files.length}');

      // 5. Enviar petición
      print('🚀 5. Enviando petición POST...');
      final response = await request.send();

      print('📡 === RESPUESTA RECIBIDA ===');
      print('🔢 Status: ${response.statusCode}');
      print('📋 Headers: ${response.headers}');
      print('🌐 Reason: ${response.reasonPhrase}');

      final responseBody = await response.stream.bytesToString();
      print('📄 Body completo: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(responseBody);
        final urls = List<String>.from(jsonData['urls']);
        print('✅ URLs extraídas: $urls');
        return urls;
      } else {
        print('❌ Error HTTP ${response.statusCode}');
        throw Exception('Error HTTP ${response.statusCode}: $responseBody');
      }
    } catch (e, stackTrace) {
      print('❌ === ERROR COMPLETO ===');
      print('Tipo: ${e.runtimeType}');
      print('Mensaje: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> procesarTextoIA(String textoOriginalJson) async {
    final url = Uri.parse('http://192.168.1.5:8000/procesar-json');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'texto_original': textoOriginalJson}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error en IA: ${response.body}');
    }
  }
}
