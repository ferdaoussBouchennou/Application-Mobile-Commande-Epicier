import 'package:flutter/material.dart';
import '../data/models/cart_item.dart';
import '../data/services/api_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CartItem> _items = [];
  double _total = 0.0;
  bool _loading = false;
  String? _error;
  int? _pendingTabIndex;


  List<CartItem> get items => List.unmodifiable(_items);
  double get total => _total;
  bool get loading => _loading;
  String? get error => _error;
  int? get pendingTabIndex => _pendingTabIndex;

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
      // Keep previous items on error so we don't show empty after a failed refetch
      if (_items.isEmpty) {
        _total = 0;
      }
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

  Future<void> addToCart(String? token, int produitId, {int quantite = 1, int? epicierId}) async {
    if (token == null) return;
    try {
      final body = <String, dynamic>{'produit_id': produitId, 'quantite': quantite};
      if (epicierId != null) body['epicier_id'] = epicierId;
      await _api.post('/panier/items', body, token: token);
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

  /// Fetch available pickup slots for a store. Returns { creneaux: [{ label, value }], nom_boutique }.
  Future<Map<String, dynamic>?> fetchCreneaux(String? token, int storeId) async {
    try {
      final res = await _api.get('/stores/$storeId/creneaux', token: token);
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create order from cart for the given epicier and pickup datetime. Returns success message or throws.
  Future<void> confirmOrder(String? token, int epicierId, String dateRecuperation) async {
    if (token == null) throw Exception('Non connecté');
    await _api.post(
      '/commandes',
      {'epicier_id': epicierId, 'date_recuperation': dateRecuperation},
      token: token,
    );
    await fetchCart(token);
  }

  void setPendingTabIndex(int index) {
    _pendingTabIndex = index;
    notifyListeners();
  }

  void clearPendingTabIndex() {
    _pendingTabIndex = null;
    notifyListeners();
  }
}
