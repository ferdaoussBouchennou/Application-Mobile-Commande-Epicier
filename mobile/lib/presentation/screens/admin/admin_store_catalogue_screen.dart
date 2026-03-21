import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart' as model;
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';
import 'admin_product_form_screen.dart';
import 'admin_category_form_screen.dart';
import '../../../screens/auth/welcome_screen.dart';

class AdminStoreCatalogueScreen extends StatefulWidget {
  final UserModel storeOwner;

  const AdminStoreCatalogueScreen({super.key, required this.storeOwner});

  @override
  State<AdminStoreCatalogueScreen> createState() => _AdminStoreCatalogueScreenState();
}

class _AdminStoreCatalogueScreenState extends State<AdminStoreCatalogueScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Product> _products = [];
  List<model.Category> _categories = [];
  int? _selectedCategoryId;
  bool _showCategories = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchCategories(),
      _fetchProducts(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCategories() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      debugPrint('AdminStoreCatalogueScreen DEBUG: FETCH CATEGORIES token=$token, isLoggedIn=${auth.isLoggedIn}');
      final List<dynamic> data = await _apiService.get('/admin/categories', token: token);
      if (mounted) {
        setState(() {
          _categories = data.map((json) => model.Category.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur catégories: $e')));
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      debugPrint('AdminStoreCatalogueScreen DEBUG: FETCH PRODUCTS token=$token, isLoggedIn=${auth.isLoggedIn}');
      String url = '/admin/stores/${widget.storeOwner.store?['id']}/products';
      String query = '';
      if (_searchController.text.isNotEmpty) {
        query += 'search=${_searchController.text}&';
      }
      if (_selectedCategoryId != null) {
        query += 'categoryId=$_selectedCategoryId&';
      }
      if (query.isNotEmpty) {
        url += '?${query.substring(0, query.length - 1)}';
      }

      final List<dynamic> data = await _apiService.get(url, token: token);
      if (mounted) {
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur produits: $e')));
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.patch('/admin/products/$productId/deactivate', {
          'epicier_id': widget.storeOwner.store?['id']
        }, token: token);
        _fetchProducts();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)))
                : RefreshIndicator(
                    onRefresh: _showCategories ? _fetchCategories : _fetchProducts,
                    color: const Color(0xFF2D5016),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_showCategories) ...[
                              _buildCategoryGrid(),
                            ] else ...[
                              _buildCategoryFilters(),
                              const SizedBox(height: 20),
                              _buildTitleRow(),
                              const SizedBox(height: 12),
                              _buildProductList(),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String storeName = widget.storeOwner.store?['nom_boutique'] ?? widget.storeOwner.fullName;
    
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2D5016),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (!_showCategories) {
                        setState(() {
                          _showCategories = true;
                          _selectedCategoryId = null;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showCategories ? 'Catalogue' : (_categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => model.Category(id: 0, nom: 'Produits', productCount: 0, storeCount: 0, ruptureCount: 0)).nom),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                      ),
                      Text(
                        _showCategories ? storeName : storeName,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF26444),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _fetchProducts(),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Catégories',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E), fontFamily: 'Outfit'),
            ),
            InkWell(
              onTap: () => _navigateToCategoryForm(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 18, color: Color(0xFFF26444)),
                    SizedBox(width: 4),
                    Text('Ajouter', style: TextStyle(color: Color(0xFFF26444), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_categories.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text('Aucune catégorie.')))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _buildCategoryCard(cat);
            },
          ),
      ],
    );
  }

  Future<void> _navigateToCategoryForm({model.Category? category}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminCategoryFormScreen(category: category)),
    );
    if (result == true) _loadData();
  }

  Widget _buildCategoryCard(model.Category cat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryId = cat.id;
            _showCategories = false;
            _fetchProducts();
          });
        },
        onLongPress: () => _navigateToCategoryForm(category: cat),
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF6F0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: cat.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(ApiConstants.formatImageUrl(cat.imageUrl), fit: BoxFit.cover),
                        )
                      : const Icon(Icons.category_outlined, size: 30, color: Color(0xFF2D5016)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cat.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D1A0E)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${cat.productCount} produits',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer'),
                      content: const Text('Voulez-vous vraiment supprimer cette catégorie ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      final token = Provider.of<AuthProvider>(context, listen: false).token;
                      await _apiService.delete('/admin/categories/${cat.id}', token: token);
                      _loadData();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tous', null),
          ..._categories.map((c) => _buildFilterChip(c.nom, c.id)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? id) {
    bool isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedCategoryId = id;
            _fetchProducts();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2D5016),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Produits',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E), fontFamily: 'Outfit'),
        ),
        InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminProductFormScreen(
                storeOwner: widget.storeOwner,
                initialCategoryId: _selectedCategoryId,
              )),
            );
            if (result == true) _fetchProducts();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, size: 18, color: Color(0xFFF26444)),
                SizedBox(width: 4),
                Text('Ajouter', style: TextStyle(color: Color(0xFFF26444), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text('Aucun produit found.'),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF6F0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: product.imagePrincipale != null
                ? Image.network(
                    ApiConstants.formatImageUrl(product.imagePrincipale),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.shopping_basket, color: Colors.orange, size: 30),
                  )
                : const Icon(Icons.shopping_basket, color: Colors.orange, size: 30),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nom,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Unité: ${product.description ?? "N/A"}', // Example, normally unit/type
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_shared, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        product.categoryName ?? 'Sans catégorie',
                        style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Price & Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.prix.toStringAsFixed(0)} DH',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5016)),
              ),
              if (product.ruptureStock)
                const Text('Rupture', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
              else
                const Text('En stock', style: TextStyle(color: Color(0xFF4CBB5E), fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildIconButton(Icons.edit_outlined, const Color(0xFFE8F5E9), const Color(0xFF4CBB5E), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminProductFormScreen(storeOwner: widget.storeOwner, product: product)),
                    ).then((value) {
                      if (value == true) _fetchProducts();
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildIconButton(Icons.delete_outline, const Color(0xFFFFEBEE), Colors.red, () => _deleteProduct(product.id)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color bg, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
