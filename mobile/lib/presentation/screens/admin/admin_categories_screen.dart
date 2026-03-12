import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/active_toggle.dart';
import '../auth/login_screen.dart';
import 'admin_category_products_screen.dart';
import 'admin_orders_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  static const _primary = Color(0xFF2D5016);
  static const _bg = Color(0xFFFDF6F0);
  static const _pageSize = 8;
  int _page = 0;

  String? get _token => context.read<AuthProvider>().token;

  int get _totalPages => (_filtered.length / _pageSize).ceil();
  List<Map<String, dynamic>> get _pageItems {
    final start = _page * _pageSize;
    final end = min(start + _pageSize, _filtered.length);
    return start < _filtered.length ? _filtered.sublist(start, end) : [];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_categories)
          : _categories.where((c) => (c['nom'] as String).toLowerCase().contains(q)).toList();
      _page = 0;
    });
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null) {
      setState(() { _loading = false; _error = 'Non connecté'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.get('/admin/categories', token: token);
      if (data is List) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e as Map)));
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  int get _totalCategories => _categories.length;
  int get _totalProducts => _categories.fold(0, (s, c) => s + ((c['productCount'] as int?) ?? 0));
  int get _totalActive => _categories.fold(0, (s, c) => s + ((c['activeProductCount'] as int?) ?? 0));

  Future<void> _createCategory() async {
    final nom = await _showNameDialog('Nouvelle catégorie');
    if (nom == null || nom.isEmpty || !mounted) return;
    try {
      await _api.post('/admin/categories', {'nom': nom.trim()}, token: _token!);
      if (mounted) { _snack('Catégorie créée'); _load(); }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _editCategory(Map<String, dynamic> c) async {
    final nom = await _showNameDialog('Modifier', initialValue: c['nom'] as String?);
    if (nom == null || nom.isEmpty || !mounted) return;
    try {
      await _api.put('/admin/categories/${c['id']}', {'nom': nom.trim()}, token: _token!);
      if (mounted) { _snack('Catégorie modifiée'); _load(); }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _toggleCategory(Map<String, dynamic> c, bool active) async {
    final token = _token;
    if (token == null) return;
    try {
      if (active) {
        await _api.patch('/admin/categories/${c['id']}/activate', {}, token: token);
      } else {
        await _api.delete('/admin/categories/${c['id']}', token: token);
      }
      if (mounted) { _snack(active ? 'Catégorie réactivée' : 'Catégorie désactivée'); _load(); }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<String?> _showNameDialog(String title, {String? initialValue}) async {
    final ctrl = TextEditingController(text: initialValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Nom de la catégorie',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, ctrl.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: _primary),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_loading && _error == null) _buildSearchBar(),
            Expanded(child: _buildBody()),
            if (!_loading && _error == null && _totalPages > 1) _buildPagination(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCategory,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catégorie'),
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
            MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Catégories',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF26444),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
                  );
                },
                tooltip: 'Déconnexion',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.85))),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une catégorie...',
          prefixIcon: const Icon(Icons.search, color: _primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () { _searchController.clear(); })
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
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
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty ? 'Aucun résultat.' : 'Aucune catégorie.\nCréez-en une.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    final items = _pageItems;
    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildCategoryCard(items[i]),
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

  Widget _buildCategoryCard(Map<String, dynamic> c) {
    final total = (c['productCount'] as int?) ?? 0;
    final active = (c['activeProductCount'] as int?) ?? 0;
    final isActive = active > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCategoryProductsScreen(
              categoryId: c['id'] as int,
              categoryName: c['nom'] as String,
            ),
          ),
        ).then((_) => _load()),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive ? _primary.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.category, color: isActive ? _primary : Colors.orange.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['nom'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editCategory(c),
                color: _primary,
                tooltip: 'Renommer',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              ActiveToggle(
                value: isActive,
                onChanged: (v) => _toggleCategory(c, v),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
