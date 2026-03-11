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
  double? _ratingRange; // null = Toutes, 0 = [0-1], 1 = [1-2], etc.
  bool? _statusFilter; // null = Toutes, true = Ouvert, false = Fermé

  List<Store> get stores => _stores;
  Store? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  double? get ratingRange => _ratingRange;
  bool? get statusFilter => _statusFilter;
  
  int get totalPages {
    final filtered = filteredStores;
    if (filtered.isEmpty) return 1;
    return (filtered.length / _itemsPerPage).ceil();
  }

  List<Store> get filteredStores {
    return _stores.where((s) {
      final matchesSearch = s.nomBoutique.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesRating = true;
      if (_ratingRange != null) {
        matchesRating = s.rating >= _ratingRange! && s.rating < (_ratingRange! + 1.0);
      }

      bool matchesStatus = true;
      if (_statusFilter != null) {
        matchesStatus = s.isOpen == _statusFilter;
      }

      return matchesSearch && matchesRating && matchesStatus;
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

  void updateFilters({String? search, double? ratingRange, bool? clearRating, bool? status, bool? clearStatus}) {
    if (search != null) _searchQuery = search;
    
    if (clearRating == true) {
      _ratingRange = null;
    } else if (ratingRange != null) {
      _ratingRange = ratingRange;
    }

    if (clearStatus == true) {
      _statusFilter = null;
    } else if (status != null) {
      _statusFilter = status;
    }

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
