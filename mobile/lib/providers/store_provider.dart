import 'package:flutter/material.dart';
import '../data/models/store.dart';
import '../data/services/api_service.dart';

class StoreProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Store> _stores = [];
  Store? _selectedStore;
  bool _isLoading = false;
  int _currentPage = 1;
  final int _itemsPerPage = 4; // Comme dans la maquette (on affiche 4 épiciers par page)
  String _searchQuery = "";
  double _minRating = 0.0;

  List<Store> get stores => _stores;
  Store? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  
  int get totalPages {
    final filtered = filteredStores;
    if (filtered.isEmpty) return 1;
    return (filtered.length / _itemsPerPage).ceil();
  }

  List<Store> get filteredStores {
    return _stores.where((s) {
      final matchesSearch = s.nomBoutique.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRating = s.rating >= _minRating;
      return matchesSearch && matchesRating;
    }).toList();
  }

  // Liste filtrée et paginée pour l'UI
  List<Store> get paginatedStores {
    final filtered = filteredStores;
    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  void updateFilters({String? search, double? rating}) {
    if (search != null) _searchQuery = search;
    if (rating != null) _minRating = rating;
    _currentPage = 1; // Retour à la page 1 si on change de filtre
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  Future<void> fetchStores() async {
    _isLoading = true;
    _currentPage = 1; // Reset page on fetch
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
