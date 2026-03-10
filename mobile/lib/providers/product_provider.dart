import 'package:flutter/material.dart';
import '../data/models/product.dart';
import '../data/services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProductsByCategory(int storeId, int categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> response = await _apiService.get('/products/store/$storeId/category/$categoryId');
      _products = response.map((data) => Product.fromJson(data)).toList();
    } catch (e) {
      print('Erreur fetchProductsByCategory: $e');
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(int storeId, String query) async {
    if (query.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> response = await _apiService.get('/products/store/$storeId/search?q=$query');
      _products = response.map((data) => Product.fromJson(data)).toList();
    } catch (e) {
      print('Erreur searchProducts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
