import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/active_toggle.dart';
import '../../../screens/auth/welcome_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_orders_screen.dart';
import '../../widgets/admin/admin_header.dart';

class AdminCategoryProductsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const AdminCategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<AdminCategoryProductsScreen> createState() =>
      _AdminCategoryProductsScreenState();
}

class _AdminCategoryProductsScreenState
    extends State<AdminCategoryProductsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String? _expandedKey;

  static const _primary = Color(0xFF2D5016);
  static const _bg = Color(0xFFFDF6F0);
  static const _pageSize = 8;
  int _page = 0;

  String? get _token => context.read<AuthProvider>().token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _searchCtrl.addListener(() => setState(() => _page = 0));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null) {
      setState(() { _loading = false; _error = 'Non connecté'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.get('/admin/categories/${widget.categoryId}/products', token: token);
      if (data is List) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e as Map)));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final q = _searchCtrl.text.trim().toLowerCase();
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final p in _products) {
      final nom = (p['nom'] as String?) ?? '';
      if (q.isNotEmpty && !nom.toLowerCase().contains(q)) continue;
      final pid = p['id'];
      final key = pid == null ? null : pid.toString();
      if (key == null) continue;
      groups.putIfAbsent(key, () => []).add(p);
    }
    final entries = groups.entries.toList();
    entries.sort((a, b) {
      final an = (a.value.first['nom'] as String?) ?? '';
      final bn = (b.value.first['nom'] as String?) ?? '';
      return an.compareTo(bn);
    });
    return Map.fromEntries(entries);
  }

  int get _totalPages {
    final n = _grouped.length;
    return n == 0 ? 0 : (n / _pageSize).ceil();
  }

  List<String> get _pageKeys {
    final keys = _grouped.keys.toList();
    final start = _page * _pageSize;
    final end = min(start + _pageSize, keys.length);
    return start < keys.length ? keys.sublist(start, end) : [];
  }

  int get _activeProducts {
    final seen = <String>{};
    int count = 0;
    for (final p in _products) {
      final key = p['id'] == null ? null : p['id'].toString();
      if (key == null) continue;
      if (!seen.contains(key)) {
        seen.add(key);
        final items = _products.where((x) => (x['id']?.toString() ?? '') == key);
        if (items.any((x) => x['is_active'] == true)) count++;
      }
    }
    return count;
  }

  Future<void> _toggleAllInGroup(String key, List<Map<String, dynamic>> items, bool active) async {
    final token = _token;
    if (token == null) return;
    try {
      final epicierIds = items
          .map((p) => p['epicier_id'])
          .whereType<num>()
          .map((n) => n.toInt())
          .toSet();
      for (final epicierId in epicierIds) {
        final endpoint = active
            ? '/admin/products/${items.first['id']}/activate'
            : '/admin/products/${items.first['id']}/deactivate';
        await _api.patch(endpoint, {'epicier_id': epicierId}, token: token);
      }
      if (mounted) {
        _snack(active ? 'Produit activé globalement' : 'Produit désactivé globalement');
        _load();
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _editProductAll(List<Map<String, dynamic>> items) async {
    final token = _token;
    if (token == null || items.isEmpty) return;
    final stores = await _api.get('/admin/stores', token: token);
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminProductFormScreen(
          token: token,
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
          stores: stores is List ? stores : [],
          product: items.first,
          existingItems: items,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final token = _token;
    if (token == null) return;
    final stores = await _api.get('/admin/stores', token: token);
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminProductFormScreen(
          token: token,
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
          stores: stores is List ? stores : [],
          product: product,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  Future<void> _addProduct() async {
    final token = _token;
    if (token == null) return;
    final stores = await _api.get('/admin/stores', token: token);
    final storeList = stores is List ? stores : [];
    if (storeList.isEmpty) {
      if (mounted) _snack('Aucun épicier disponible.');
      return;
    }
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminProductFormScreen(
          token: token,
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
          stores: storeList,
          product: null,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  String _prix(dynamic v) {
    if (v == null) return '—';
    if (v is num) return '${v.toStringAsFixed(2)} DH';
    return '$v DH';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_loading && _error == null) _buildStats(),
            Expanded(child: _buildBody()),
            if (!_loading && _error == null && _totalPages > 1) _buildPagination(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Produit'),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3,
      selectedItemColor: _primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 1) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminOrdersScreen()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminCategoriesScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Utilisateurs'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Commandes'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Catégories'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Réglages'),
      ],
    );
  }

  Widget _buildHeader() {
    return AdminHeader(
      title: widget.categoryName,
      showBackButton: true,
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.85))),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final total = _grouped.length;
    final active = _activeProducts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _statChip('$total', 'Produits', Colors.black87),
          const SizedBox(width: 10),
          _statChip('$active', 'Actifs', const Color(0xFF4CBB5E)),
          const SizedBox(width: 10),
          _statChip('${total - active}', 'Inactifs', const Color(0xFFF2A93B)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primary));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ],
        ),
      );
    }
    final groups = _grouped;
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isNotEmpty ? 'Aucun résultat.' : 'Aucun produit.\nAjoutez-en un.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    final keys = _pageKeys;
    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: keys.length,
        itemBuilder: (ctx, i) => _buildProductCard(keys[i], groups[keys[i]]!),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 0 ? () => setState(() => _page--) : null,
            color: _primary,
          ),
          const SizedBox(width: 4),
          ...List.generate(_totalPages, (i) {
            final isActive = i == _page;
            if (_totalPages > 7 && (i - _page).abs() > 2 && i != 0 && i != _totalPages - 1) {
              if (i == 1 || i == _totalPages - 2) {
                return const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('…'));
              }
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => setState(() => _page = i),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : _primary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < _totalPages - 1 ? () => setState(() => _page++) : null,
            color: _primary,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String key, List<Map<String, dynamic>> items) {
    final first = items.first;
    final nom = first['nom'] as String? ?? '';
    final someActive = items.any((p) => p['is_active'] == true);
    final isExpanded = _expandedKey == key;
    final globalInactive = !someActive;
    final prix = first['prix'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedKey = isExpanded ? null : key),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: isExpanded ? Radius.zero : const Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _buildImage(first),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          globalInactive ? 'Inactif' : 'Actif',
                          style: TextStyle(
                            fontSize: 12,
                            color: globalInactive ? Colors.orange.shade700 : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Prix: ${_prix(prix)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  ActiveToggle(
                    value: someActive,
                    onChanged: (v) => _toggleAllInGroup(key, items, v),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _editProductAll(items),
                    color: _primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Modifier pour tous',
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    (first['description'] as String?)?.trim().isNotEmpty == true
                        ? (first['description'] as String)
                        : '—',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> p) {
    final path = p['image_principale'] as String?;
    if (path != null && path.isNotEmpty) {
      final url = path.startsWith('http') ? path : ApiConstants.formatImageUrl(path);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(url, width: 50, height: 50, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: _primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.inventory_2, color: _primary, size: 24),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulaire produit (admin)
// ---------------------------------------------------------------------------
class _AdminProductFormScreen extends StatefulWidget {
  final String token;
  final int categoryId;
  final String categoryName;
  final List<dynamic> stores;
  final Map<String, dynamic>? product;
  final List<Map<String, dynamic>>? existingItems;

  const _AdminProductFormScreen({
    required this.token,
    required this.categoryId,
    required this.categoryName,
    required this.stores,
    this.product,
    this.existingItems,
  });

  @override
  State<_AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<_AdminProductFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _prixCtrl;
  late TextEditingController _descCtrl;
  String? _imagePath;
  bool _saving = false;
  bool _uploading = false;

  final Set<int> _storeIdsToApply = {};

  bool get _isCreate => widget.product == null;
  bool get _isEditAll => !_isCreate && widget.existingItems != null && widget.existingItems!.isNotEmpty;
  bool get _isEditSingle => !_isCreate && !_isEditAll;

  int? get _productId {
    final id = widget.product?['id'] ?? widget.existingItems?.first['id'];
    if (id is int) return id;
    if (id == null) return null;
    return int.tryParse(id.toString());
  }

  bool get _hasStoresToApply => _storeIdsToApply.isNotEmpty;

  static const _primary = Color(0xFF2D5016);

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.product?['nom'] ?? '');
    _prixCtrl = TextEditingController(
      text: widget.product != null
          ? (widget.product!['prix'] is num
              ? (widget.product!['prix'] as num).toStringAsFixed(2)
              : widget.product!['prix'].toString())
          : '',
    );
    _descCtrl = TextEditingController(text: widget.product?['description'] ?? '');
    _imagePath = widget.product?['image_principale'];

    // Mode "global": on applique les modifications à tous les épiciers concernés
    // (sans affichage/gestion individuelle côté UI).
    if (_isCreate) {
      for (final s in widget.stores) {
        final id = (s is Map) ? s['id'] : null;
        if (id is num) _storeIdsToApply.add(id.toInt());
      }
    } else if (_isEditAll) {
      for (final item in widget.existingItems!) {
        final sid = item['epicier_id'];
        if (sid is num) _storeIdsToApply.add(sid.toInt());
      }
    } else {
      final sid = widget.product?['epicier_id'];
      if (sid is num) _storeIdsToApply.add(sid.toInt());
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prixCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: false);
      if (result == null || result.files.isEmpty) {
        setState(() => _uploading = false);
        return;
      }
      final file = result.files.single;
      if (file.bytes == null || file.name.isEmpty) {
        _snack('Impossible de lire le fichier');
        setState(() => _uploading = false);
        return;
      }
      final path = await _api.uploadProductImageAdmin(
        token: widget.token,
        categorieId: widget.categoryId,
        bytes: file.bytes!,
        filename: file.name,
        productName: _nomCtrl.text.trim().isEmpty ? null : _nomCtrl.text.trim(),
      );
      if (mounted) {
        setState(() { _imagePath = path; _uploading = false; });
        _snack('Image enregistrée');
      }
    } catch (e) {
      if (mounted) { setState(() => _uploading = false); _snack(e.toString().replaceAll('Exception: ', '')); }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasStoresToApply) {
      _snack('Aucun épicier concerné.');
      return;
    }
    final productId = _productId;
    if (!_isCreate && productId == null) {
      _snack('Données incomplètes (id du produit manquant).');
      return;
    }

    setState(() => _saving = true);
    try {
      final body = {
        'nom': _nomCtrl.text.trim(),
        'prix': double.tryParse(_prixCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        if (_imagePath != null) 'image_principale': _imagePath,
      };

      if (_isCreate) {
        for (final sid in _storeIdsToApply) {
          await _api.post(
            '/admin/products',
            {
              'epicier_id': sid,
              'categorie_id': widget.categoryId,
              ...body,
            },
            token: widget.token,
          );
        }
        if (mounted) { _snack('Produit créé'); Navigator.pop(context, true); }
      } else {
        for (final sid in _storeIdsToApply) {
          await _api.put(
            '/admin/products/$productId',
            {
              ...body,
              'epicier_id': sid, // indispensable pour mettre à jour le prix côté EpicierProduct
            },
            token: widget.token,
          );
        }
        if (mounted) { _snack('Produit modifié'); Navigator.pop(context, true); }
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final title = _isCreate ? 'Nouveau produit' : 'Modifier le produit';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Retour',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedItemColor: _primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Épiciers'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Catégories'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Réglages'),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _infoBanner(
              _isCreate
                  ? 'Le produit sera créé pour tous les épiciers actifs.'
                  : 'Les modifications seront appliquées au produit pour tous les épiciers concernés.',
              _isCreate ? Colors.blue : Colors.green,
            ),

            _field(_nomCtrl, 'Nom du produit', required: true),
            const SizedBox(height: 14),
            _field(_prixCtrl, 'Prix (DH)',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                required: true,
                isNumber: true),
            const SizedBox(height: 14),
            _field(_descCtrl, 'Description (optionnel)', maxLines: 3),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _imagePath!.startsWith('http') ? _imagePath! : ApiConstants.formatImageUrl(_imagePath!),
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 80, height: 80, child: Icon(Icons.broken_image)),
                    ),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickImage,
                  icon: _uploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(_uploading ? 'Upload...' : 'Image'),
                  style: OutlinedButton.styleFrom(foregroundColor: _primary),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isCreate ? 'Créer' : 'Enregistrer',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBanner(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color.shade800))),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, bool isNumber = false, TextInputType? keyboard, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return 'Requis';
              if (isNumber && double.tryParse(v.trim()) == null) return 'Nombre invalide';
              return null;
            }
          : null,
    );
  }
}
