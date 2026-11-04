import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  // Restaurar sesión al iniciar la app
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      // Si hay token guardado, consideramos al usuario autenticado.
      // En una app real podríamos validar el token con el backend.
      // Por ahora, lo dejamos para que el usuario vaya al dashboard.
      // Nota: Aquí necesitaríamos guardar el user completo.
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;

        // Guardar token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        // Guardar usuario
        _user = User.fromJson(data['user']);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });

      if (response.statusCode == 201) {
        // ❌ NO guardamos el token ni el usuario
        // El usuario debe iniciar sesión manualmente
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Trae los datos más recientes del usuario desde el backend.
  Future<bool> loadProfile() {
    return _runRequest(() async {
      final response = await _apiService.get('/users/me');
      _user = User.fromJson(response.data);
    });
  }

  Future<bool> updateProfile(String name, String currency) {
    return _runRequest(() async {
      final response = await _apiService.put('/users/me', data: {
        'name': name,
        'currency': currency,
      });
      _user = User.fromJson(response.data);
    });
  }

  // El backend responde 204 (sin cuerpo), por eso aquí no se modifica _user.
  Future<bool> changePassword(String current, String newPass) {
    return _runRequest(() async {
      await _apiService.put('/users/me/password', data: {
        'currentPassword': current,
        'newPassword': newPass,
      });
    });
  }

  // Pasos comunes de las peticiones de perfil: activa isLoading, ejecuta la
  // petición, guarda el mensaje de error si falla y avisa a la pantalla.
  Future<bool> _runRequest(Future<void> Function() request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    var success = false;
    try {
      await request();
      success = true;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _user = null;
    notifyListeners();
  }
}