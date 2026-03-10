import 'package:flutter/material.dart';
import '../data/models/category.dart';
import '../data/services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Category> _categories = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> fetchCategories(int storeId, {int page = 1}) async {
    _isLoading = true;
    _currentPage = page;
    notifyListeners();

    try {
      final response = await _apiService.get('/categories/store/$storeId?page=$page&limit=9');
      
      if (response is Map<String, dynamic>) {
        final List<dynamic> catList = response['categories'];
        _categories = catList.map((data) => Category.fromJson(data)).toList();
        _totalPages = response['totalPages'];
      }
    } catch (e) {
      print('Erreur fetchCategories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextPage(int storeId) {
    if (_currentPage < _totalPages) {
      fetchCategories(storeId, page: _currentPage + 1);
    }
  }

  void previousPage(int storeId) {
    if (_currentPage > 1) {
      fetchCategories(storeId, page: _currentPage - 1);
    }
  }

  Future<void> searchCategories(int storeId, String query) async {
    if (query.isEmpty) {
      return fetchCategories(storeId);
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/categories/store/$storeId?q=$query&limit=9');
      
      if (response is Map<String, dynamic>) {
        final List<dynamic> catList = response['categories'];
        _categories = catList.map((data) => Category.fromJson(data)).toList();
        _totalPages = response['totalPages'];
        _currentPage = 1;
      }
    } catch (e) {
      print('Erreur searchCategories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
