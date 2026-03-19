import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/cart_item.dart';
import '../data/services/api_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CartItem> _items = [];
  bool _loading = false;
  String? _error;
  int? _pendingTabIndex;

  List<CartItem> get items => List.unmodifiable(_items);
  double get total => _items.fold(0, (sum, i) => sum + i.lineTotal);
  bool get loading => _loading;
  String? get error => _error;
  int? get pendingTabIndex => _pendingTabIndex;

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantite);
  int get articleCount => _items.length;

  CartProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('local_cart');
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        _items = list.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e))).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart from prefs: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_items.map((e) => e.toJson()).toList());
      await prefs.setString('local_cart', jsonStr);
    } catch (e) {
      debugPrint('Error saving cart to prefs: $e');
    }
  }

  // Still called by UI to "refresh" from local or trigger things
  Future<void> fetchCart(String? token) async {
    // Already loaded in constructor, but ensure UI gets notified
    notifyListeners();
  }

  Future<void> updateQuantity(String? token, int produitId, int quantite) async {
    if (quantite <= 0) {
      await removeItem(token, produitId);
      return;
    }
    final idx = _items.indexWhere((e) => e.produitId == produitId);
    if (idx >= 0) {
      _items[idx].quantite = quantite;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> removeItem(String? token, int produitId) async {
    _items.removeWhere((e) => e.produitId == produitId);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> addToCart({
    required int produitId,
    required String nom,
    required double prix,
    String? imagePrincipale,
    int? epicierId,
    int quantite = 1,
  }) async {
    final idx = _items.indexWhere((e) => e.produitId == produitId);
    if (idx >= 0) {
      _items[idx].quantite += quantite;
    } else {
      _items.add(CartItem(
        produitId: produitId,
        nom: nom,
        prix: prix,
        imagePrincipale: imagePrincipale,
        epicierId: epicierId,
        quantite: quantite,
      ));
    }
    await _saveToPrefs();
    notifyListeners();
  }

  void _recomputeTotal() {
    // Logic moved to 'total' getter
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchCreneaux(String? token, int storeId, {String? date}) async {
    try {
      String url = '/stores/$storeId/creneaux';
      if (date != null) url += '?date=$date';
      final res = await _api.get(url, token: token);
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> confirmOrder(String? token, int epicierId, String dateRecuperation) async {
    if (token == null) throw Exception('Non connecté');
    
    // Filter items for this epicier (some might have epicierId null if they were added generically, though not typical now)
    final grocerItems = _items.where((i) => i.epicierId == epicierId || i.epicierId == null).toList();
    
    if (grocerItems.isEmpty) {
      throw Exception('Aucun article de cet épicier dans votre panier');
    }

    await _api.post(
      '/commandes',
      {
        'epicier_id': epicierId,
        'date_recuperation': dateRecuperation,
        'items': grocerItems.map((i) => {
          'produit_id': i.produitId,
          'quantite': i.quantite,
        }).toList(),
      },
      token: token,
    );

    // Remove these items from local cart
    _items.removeWhere((i) => i.epicierId == epicierId || i.epicierId == null);
    await _saveToPrefs();
    notifyListeners();
  }

  void clearCart() {
    _items = [];
    _saveToPrefs();
    notifyListeners();
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
