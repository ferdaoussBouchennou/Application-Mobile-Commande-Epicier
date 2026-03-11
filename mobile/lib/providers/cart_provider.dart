import 'package:flutter/material.dart';
import '../data/models/cart_item.dart';
import '../data/services/api_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CartItem> _items = [];
  double _total = 0.0;
  bool _loading = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  double get total => _total;
  bool get loading => _loading;
  String? get error => _error;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantite);
  int get articleCount => _items.length;

  Future<void> fetchCart(String? token) async {
    if (token == null || token.isEmpty) {
      _items = [];
      _total = 0;
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/panier', token: token);
      _items = (res['articles'] as List?)
          ?.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [];
      _total = double.tryParse((res['total']?.toString()) ?? '0') ?? 0.0;
    } catch (e) {
      _error = e.toString();
      _items = [];
      _total = 0;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String? token, int produitId, int quantite) async {
    if (token == null) return;
    try {
      if (quantite <= 0) {
        await removeItem(token, produitId);
        return;
      }
      await _api.put('/panier/items/$produitId', {'quantite': quantite}, token: token);
      final i = _items.indexWhere((e) => e.produitId == produitId);
      if (i >= 0) {
        _items[i].quantite = quantite;
        _recomputeTotal();
        notifyListeners();
      } else {
        await fetchCart(token);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeItem(String? token, int produitId) async {
    if (token == null) return;
    try {
      await _api.delete('/panier/items/$produitId', token: token);
      _items.removeWhere((e) => e.produitId == produitId);
      _recomputeTotal();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addToCart(String? token, int produitId, {int quantite = 1}) async {
    if (token == null) return;
    try {
      await _api.post('/panier/items', {'produit_id': produitId, 'quantite': quantite}, token: token);
      await fetchCart(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _recomputeTotal() {
    double sum = 0;
    for (final i in _items) {
      sum += i.prix * i.quantite;
    }
    _total = sum;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
