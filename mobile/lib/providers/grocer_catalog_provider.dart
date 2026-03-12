import 'package:flutter/material.dart';
import '../data/models/product.dart';
import '../data/models/category.dart';
import '../data/services/api_service.dart';

class GrocerCatalogProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Product> _products = [];
  /// Produits existants en BDD (autres épiciers) pas encore dans mon catalogue pour une catégorie.
  List<Product> _availableProducts = [];
  List<Category> _myCategories = [];
  List<Category> _retiredCategories = [];
  List<Category> _allCategories = [];
  List<Product> _inactiveProductsForRestore = [];
  bool _isLoading = false;
  String? _error;
  int? _currentCategoryId;

  List<Product> get products => _products;
  List<Product> get availableProducts => _availableProducts;
  List<Category> get myCategories => _myCategories;
  List<Category> get retiredCategories => _retiredCategories;
  List<Category> get allCategories => _allCategories;
  List<Product> get inactiveProductsForRestore => _inactiveProductsForRestore;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Catégories où l'épicier a des produits (actifs ou retirés). GET /categories/store/:storeId.
  Future<void> fetchCategoriesByStore(int? storeId) async {
    if (storeId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/categories/store/$storeId?includeRetired=true') as Map<String, dynamic>;
      final list = response['categories'] as List<dynamic>? ?? [];
      final categories = list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
      _myCategories = categories.where((c) => (c.productCount ?? 0) > 0).toList();
      _retiredCategories = categories.where((c) => c.isRetired).toList();
    } catch (e) {
      _myCategories = [];
      _retiredCategories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Produits inactifs dans une catégorie (pour restauration avec sélection multiple).
  Future<void> fetchInactiveProductsForCategory(String? token, int categoryId) async {
    if (token == null) return;
    try {
      final response = await _api.get('/epicier/categories/$categoryId/inactive-products', token: token);
      final list = response as List<dynamic>;
      _inactiveProductsForRestore = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _inactiveProductsForRestore = [];
    }
    notifyListeners();
  }

  /// Restaurer une catégorie en réactivant les produits sélectionnés (sélection multiple).
  Future<bool> restoreCategoryWithProducts(String? token, int categoryId, List<int> productIds) async {
    if (token == null || productIds.isEmpty) return false;
    try {
      await _api.post('/epicier/categories/$categoryId/restore', {'product_ids': productIds}, token: token);
      _inactiveProductsForRestore = [];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Toutes les catégories (pour dropdown et "catégorie existante").
  Future<void> fetchAllCategories() async {
    try {
      final response = await _api.get('/categories');
      final list = response as List<dynamic>;
      _allCategories = list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _allCategories = [];
    }
    notifyListeners();
  }

  /// Liste des produits de l'épicier. Si [categoryId] est fourni, filtre par catégorie.
  Future<void> fetchProducts(String? token, {int? categoryId}) async {
    if (token == null) return;
    _currentCategoryId = categoryId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final endpoint = categoryId != null
          ? '/epicier/products?categorie_id=$categoryId'
          : '/epicier/products';
      final response = await _api.get(endpoint, token: token);
      final list = response as List<dynamic>;
      _products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Produits existants en BDD (autres épiciers) dans cette catégorie, pas encore dans mon catalogue.
  Future<void> fetchAvailableProductsForCategory(String? token, int categoryId) async {
    if (token == null) return;
    try {
      final response = await _api.get('/epicier/products/available-for-category/$categoryId', token: token);
      final list = response as List<dynamic>;
      _availableProducts = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _availableProducts = [];
    }
    notifyListeners();
  }

  /// Copier un produit existant (d'un autre épicier) dans mon catalogue. [prix] optionnel pour surcharger.
  Future<bool> copyProductToCatalogue(String? token, int productId, {double? prix}) async {
    if (token == null) return false;
    try {
      final body = prix != null ? {'prix': prix} : <String, dynamic>{};
      await _api.post('/epicier/products/copy/$productId', body, token: token);
      await _refetchAfterCrud(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Réintégrer au catalogue un produit que j'avais retiré. [prix] optionnel pour mettre à jour le prix.
  Future<bool> restoreProductToCatalogue(String? token, int productId, {double? prix}) async {
    if (token == null) return false;
    try {
      final body = prix != null ? {'prix': prix} : <String, dynamic>{};
      await _api.put('/epicier/products/$productId/restore', body, token: token);
      await _refetchAfterCrud(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> _refetchAfterCrud(String? token) async {
    if (token == null) return;
    if (_currentCategoryId != null) {
      await fetchProducts(token, categoryId: _currentCategoryId);
    } else {
      await fetchProducts(token);
    }
  }

  /// Upload d'une image produit. Retourne le chemin à enregistrer en image_principale ou null en cas d'erreur.
  /// [productName] optionnel : nom du produit pour nommer le fichier côté serveur.
  Future<String?> uploadProductImage(String? token, int categoryId, List<int> bytes, String filename, {String? productName}) async {
    if (token == null) return null;
    try {
      final path = await _api.uploadProductImage(
        token: token,
        categorieId: categoryId,
        bytes: bytes,
        filename: filename,
        productName: productName,
      );
      return path;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> createProduct(String? token, Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await _api.post('/epicier/products', data, token: token);
      await _refetchAfterCrud(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String? token, int productId, Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await _api.put('/epicier/products/$productId', data, token: token);
      await _refetchAfterCrud(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String? token, int productId) async {
    if (token == null) return false;
    try {
      await _api.delete('/epicier/products/$productId', token: token);
      await _refetchAfterCrud(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Retirer une catégorie du catalogue : supprime tous les produits de l'épicier dans cette catégorie.
  /// La catégorie n'est pas supprimée de la base de données (elle reste disponible pour les autres).
  Future<bool> removeCategoryFromCatalogue(String? token, int categoryId) async {
    if (token == null) return false;
    try {
      await _api.delete('/epicier/categories/$categoryId', token: token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Créer une nouvelle catégorie (épicier). Retourne la catégorie créée ou null.
  Future<Category?> createCategory(String? token, String nom) async {
    if (token == null || nom.trim().isEmpty) return null;
    try {
      final response = await _api.post('/categories', {'nom': nom.trim()}, token: token);
      final created = Category.fromJson(response as Map<String, dynamic>);
      _allCategories = [..._allCategories, created]..sort((a, b) => a.nom.compareTo(b.nom));
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
