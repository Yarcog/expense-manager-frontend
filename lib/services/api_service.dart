import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_report.dart';

class ApiService {
  // ⚠️ IMPORTANTE:
  // 10.0.2.2 es la IP especial del emulador de Android para acceder a localhost de la PC.
  // Si usas un celular físico, cámbialo por la IP de tu PC (ej: 192.168.1.100).
  final String baseUrl = 'http://10.0.2.2:8080/api';

  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Interceptor: Agrega el token JWT automáticamente a cada petición
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // --- MÉTODOS GENÉRICOS ---

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- MANEJO DE ERRORES ---

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      // Intenta extraer el mensaje de error del backend
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Error del servidor: ${e.response!.statusCode}';
    }
    return 'Error de conexión con el servidor.';

  }
  // Obtener reporte por categoría
  Future<List<CategoryReport>> getCategoryReport({String type = 'EXPENSE'}) async {
    try {
      final response = await _dio.get('/reports/by-category', queryParameters: {'type': type});
      final List<dynamic> data = response.data;
      return data.map((json) => CategoryReport.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}