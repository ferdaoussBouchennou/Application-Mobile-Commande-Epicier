import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/auth/welcome_screen.dart';
import 'admin_validation_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_category_form_screen.dart';
import '../../../data/models/category.dart' as model;
import 'admin_category_products_screen.dart';
import '../../widgets/admin/admin_bottom_nav.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final ApiService _api = ApiService();
  List<model.Category> _categories = [];
  List<model.Category> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  static const _primary = Color(0xFF2D5016);
  static const _bg = Color(0xFFFDF6F0);
  static const _pageSize = 8;
  int _page = 0;

  String? get _token => context.read<AuthProvider>().token;

  int get _totalPages => (_filtered.length / _pageSize).ceil();
  List<model.Category> get _pageItems {
    final start = _page * _pageSize;
    final end = min(start + _pageSize, _filtered.length);
    return start < _filtered.length ? _filtered.sublist(start, end) : <model.Category>[];
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
          : _categories.where((c) => c.nom.toLowerCase().contains(q)).toList();
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
          _categories = data.map((e) => model.Category.fromJson(e)).toList();
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  int get _totalCategories => _categories.length;
  int get _totalProducts => _categories.fold(0, (s, c) => s + c.productCount);
  int get _totalStores => _categories.fold(0, (s, c) => s + c.storeCount);

  Future<void> _navigateToForm({model.Category? category}) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminCategoryFormScreen(category: category)),
    );
    if (res == true) _load();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
        onPressed: () => _navigateToForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catégorie'),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
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
                    MaterialPageRoute(builder: (_) => WelcomeScreen()),
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

    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: _pageItems.length,
        itemBuilder: (context, index) => _buildCategoryRow(_pageItems[index]),
      ),
    );
  }

  Widget _buildCategoryRow(model.Category cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCategoryProductsScreen(
              categoryId: cat.id,
              categoryName: cat.nom,
            ),
          ),
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF6F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.category_outlined, size: 22, color: Color(0xFF2D5016)),
        ),
        title: Text(
          cat.nom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
        ),
        subtitle: Text(
          '${cat.productCount} produits',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFFB99D6B)),
              onPressed: () => _navigateToForm(category: cat),
              tooltip: 'Modifier la catégorie',
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, -2))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
              if (i == 1 || i == _totalPages - 2) return const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('…'));
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
}
