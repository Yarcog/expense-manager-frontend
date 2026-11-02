import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/transactions');
      _transactions = (response.data as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
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
  }) async {
    try {
      final response = await _api.post('/transactions', data: {
        'categoryId': categoryId,
        'type': type,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
      });

      final newTransaction = Transaction.fromJson(response.data);
      _transactions.insert(0, newTransaction);
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
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}