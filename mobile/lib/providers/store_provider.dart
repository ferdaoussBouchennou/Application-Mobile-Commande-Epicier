import 'package:flutter/material.dart';
import '../data/models/store.dart';
import '../data/services/api_service.dart';

class StoreProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Store> _stores = [];
  Store? _selectedStore;
  bool _isLoading = false;

  List<Store> get stores => _stores;
  Store? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;

  Future<void> fetchStores() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> response = await _apiService.get('/stores');
      _stores = response.map((data) => Store.fromJson(data)).toList();
    } catch (e) {
      print('Erreur fetchStores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStoreDetails(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/stores/$id');
      _selectedStore = Store.fromJson(response);
    } catch (e) {
      print('Erreur fetchStoreDetails: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
