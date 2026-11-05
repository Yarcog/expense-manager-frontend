import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  bool _loadFailed = false;
  String? _errorMessage;
  int _changeCount = 0;

  /// Aumenta cada vez que se crea o elimina una transacción. Le permite a otras
  /// pantallas saber cuándo recalcular, sin reaccionar a una simple recarga.
  int get changeCount => _changeCount;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Indica si falló la carga de la lista. Sirve para no confundir
  /// "no se pudo cargar" con "no tienes transacciones".
  bool get loadFailed => _loadFailed;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/transactions');
      _transactions = (response.data as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
      _loadFailed = false;
    } catch (e) {
      _errorMessage = e.toString();
      _loadFailed = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTransaction({
    required String categoryId,
    required String type,
    required double amount,
    required String description,
    required DateTime date,
    String? accountId,
  }) async {
    try {
      final response = await _api.post('/transactions', data: {
        'categoryId': categoryId,
        'type': type,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'accountId': ?accountId,
      });

      final newTransaction = Transaction.fromJson(response.data);
      _transactions.insert(0, newTransaction);
      _changeCount++;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _api.delete('/transactions/$id');
      _transactions.removeWhere((t) => t.id == id);
      _changeCount++;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}