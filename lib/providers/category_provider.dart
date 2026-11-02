import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/categories');
      _categories = (response.data as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    try {
      final response = await _api.post('/categories', data: {
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
      });

      final newCategory = Category.fromJson(response.data);
      _categories.add(newCategory);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _api.delete('/categories/$id');
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}