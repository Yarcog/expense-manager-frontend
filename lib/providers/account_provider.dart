import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/api_service.dart';

class AccountProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Account> _accounts = [];
  bool _isLoading = false;
  bool _loadFailed = false;
  String? _errorMessage;

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Indica si falló la carga de la lista. Sirve para no confundir
  /// "no se pudo cargar" con "no tienes cuentas".
  bool get loadFailed => _loadFailed;

  Future<void> loadAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/accounts');
      _accounts = (response.data as List)
          .map((json) => Account.fromJson(json))
          .toList();
      _loadFailed = false;
    } catch (e) {
      _errorMessage = e.toString();
      _loadFailed = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Olvida las cuentas en memoria. El provider sigue vivo al cerrar sesión,
  /// así que esto evita mostrar las cuentas del usuario anterior.
  void clear() {
    _accounts = [];
    _loadFailed = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> createAccount({
    required String name,
    required String type,
    required double initialBalance,
    required String color,
  }) async {
    _errorMessage = null;
    try {
      final response = await _api.post('/accounts', data: {
        'name': name,
        'type': type,
        'initialBalance': initialBalance,
        'color': color,
      });

      _accounts.add(Account.fromJson(response.data));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(String id) async {
    _errorMessage = null;
    try {
      await _api.delete('/accounts/$id');
      _accounts.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
