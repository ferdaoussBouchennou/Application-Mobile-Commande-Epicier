import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/product.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/grocer_catalog_provider.dart';
import '../grocer_theme.dart';
import 'grocer_product_form_screen.dart';

/// Affiche tous les produits de l'épicier appartenant à une catégorie. Permet d'ajouter, modifier, supprimer.
class GrocerCategoryProductsScreen extends StatefulWidget {
  final Category category;

  const GrocerCategoryProductsScreen({super.key, required this.category});

  @override
  State<GrocerCategoryProductsScreen> createState() => _GrocerCategoryProductsScreenState();
}

class _GrocerCategoryProductsScreenState extends State<GrocerCategoryProductsScreen> {
  bool _selectionModeProducts = false;
  final Set<int> _selectedProductIds = {};

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final catalog = context.read<GrocerCatalogProvider>();
    await catalog.fetchProducts(auth.token, categoryId: widget.category.id);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Choix : ajouter un produit existant (BDD) ou créer un nouveau (même logique que catégories).
  void _showAddProductChoice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(ctx),
                    color: GrocerTheme.primary,
                    tooltip: 'Retour',
                  ),
                  const Expanded(
                    child: Text(
                      'Que voulez-vous faire ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GrocerTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisir un produit déjà existant dans la base ou créer un nouveau produit.',
                style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openExistingProductList();
                },
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Choisir un produit existant'),
                style: FilledButton.styleFrom(
                  backgroundColor: GrocerTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openNewProductForm();
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Créer un nouveau produit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GrocerTheme.primary,
                  side: const BorderSide(color: GrocerTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExistingProductList() async {
    final auth = context.read<AuthProvider>();
    final catalog = context.read<GrocerCatalogProvider>();
    await catalog.fetchAvailableProductsForCategory(auth.token, widget.category.id);
    if (!mounted) return;
    if (catalog.availableProducts.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aucun produit existant'),
          content: const Text(
            'Aucun produit existant à ajouter pour cette catégorie. Créez un nouveau produit si besoin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Retour'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openNewProductForm();
              },
              style: FilledButton.styleFrom(backgroundColor: GrocerTheme.primary),
              child: const Text('Créer un nouveau produit'),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _ExistingProductsMultiSelectSheet(
          products: catalog.availableProducts,
          scrollController: scrollController,
          onBack: () => Navigator.pop(ctx),
          onAddSelected: (selected) async {
            Navigator.pop(ctx);
            await _addExistingProducts(selected);
          },
        ),
      ),
    );
  }

  Future<void> _addExistingProducts(List<Product> selected) async {
    if (selected.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final catalog = context.read<GrocerCatalogProvider>();
    int added = 0;
    for (final product in selected) {
      final ok = product.isRetiredMine
          ? await catalog.restoreProductToCatalogue(auth.token, product.id, prix: product.prix)
          : await catalog.copyProductToCatalogue(auth.token, product.id, prix: product.prix);
      if (ok) added++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == selected.length
              ? '$added produit(s) ajouté(s) au catalogue'
              : '$added / ${selected.length} produit(s) ajouté(s)',
        ),
      ),
    );
    _load();
  }

  Future<void> _addExistingProduct(Product product) async {
    final prixController = TextEditingController(text: product.prix.toStringAsFixed(2));
    final isRestore = product.isRetiredMine;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRestore ? 'Réintégrer « ${product.nom} »' : 'Ajouter « ${product.nom} »'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRestore
                  ? 'Ce produit sera à nouveau visible dans votre catalogue. Vous pouvez modifier le prix (DH) si besoin :'
                  : 'Ce produit sera ajouté à votre catalogue. Vous pouvez modifier le prix (DH) si besoin :',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prixController,
              decoration: const InputDecoration(
                labelText: 'Prix (DH)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: GrocerTheme.primary),
            child: Text(isRestore ? 'Réintégrer au catalogue' : 'Ajouter au catalogue'),
          ),
        ],
      ),
    );
    final prixStr = prixController.text.replaceAll(',', '.');
    prixController.dispose();
    if (confirm != true || !mounted) return;
    final prix = double.tryParse(prixStr);
    final auth = context.read<AuthProvider>();
    final catalog = context.read<GrocerCatalogProvider>();
    final ok = isRestore
        ? await catalog.restoreProductToCatalogue(auth.token, product.id, prix: prix ?? product.prix)
        : await catalog.copyProductToCatalogue(auth.token, product.id, prix: prix ?? product.prix);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRestore ? 'Produit réintégré au catalogue' : 'Produit ajouté au catalogue'),
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(catalog.error ?? 'Erreur')),
      );
    }
  }

  void _openNewProductForm() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GrocerProductFormScreen(
          token: auth.token!,
          product: null,
          initialCategoryId: widget.category.id,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  void _openForm([Product? product]) async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GrocerProductFormScreen(
          token: auth.token!,
          product: product,
          initialCategoryId: widget.category.id,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  void _showProductOptions(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: GrocerTheme.primary),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(ctx);
                _openForm(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: GrocerTheme.trendNegative),
              title: const Text('Retirer du catalogue'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemoveFromCatalogue(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleProductSelection(int productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  Future<void> _confirmBulkRemoveProducts() async {
    final n = _selectedProductIds.length;
    if (n == 0) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer du catalogue'),
        content: Text(
          'Retirer $n produit(s) de votre catalogue ?\n\n'
          'Les produits ne seront plus visibles dans votre catalogue mais resteront en base de données. '
          'Vous pourrez les réintégrer plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: GrocerTheme.trendNegative),
            child: const Text('Supprimer du catalogue'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final catalog = context.read<GrocerCatalogProvider>();
    int removed = 0;
    for (final id in _selectedProductIds) {
      final ok = await catalog.deleteProduct(auth.token, id);
      if (ok) removed++;
    }
    setState(() {
      _selectionModeProducts = false;
      _selectedProductIds.clear();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$removed produit(s) retiré(s) du catalogue')),
    );
    _load();
  }

  Future<void> _confirmRemoveFromCatalogue(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer du catalogue'),
        content: Text(
          'Retirer « ${product.nom} » de votre catalogue ?\n\n'
          'Le produit ne sera plus visible dans votre catalogue mais restera en base de données et pourra être réutilisé plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: GrocerTheme.trendNegative),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final catalog = context.read<GrocerCatalogProvider>();
    final ok = await catalog.deleteProduct(auth.token, product.id);
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit retiré du catalogue')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(catalog.error ?? 'Erreur')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrocerTheme.background,
      appBar: AppBar(
        backgroundColor: GrocerTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.category.nom),
        actions: [
          if (!_selectionModeProducts)
            TextButton(
              onPressed: () => setState(() => _selectionModeProducts = true),
              child: const Text('Sélectionner', style: TextStyle(color: Colors.white)),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() {
                _selectionModeProducts = false;
                _selectedProductIds.clear();
              }),
              child: const Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: _selectedProductIds.isEmpty ? null : _confirmBulkRemoveProducts,
              child: Text(
                'Supprimer (${_selectedProductIds.length})',
                style: TextStyle(
                  color: _selectedProductIds.isEmpty ? Colors.white54 : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      body: Consumer2<GrocerCatalogProvider, AuthProvider>(
        builder: (context, catalog, auth, _) {
          if (catalog.isLoading && catalog.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: GrocerTheme.primary),
            );
          }
          if (catalog.error != null && catalog.products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      catalog.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: GrocerTheme.trendNegative),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        catalog.clearError();
                        _load();
                      },
                      style: FilledButton.styleFrom(backgroundColor: GrocerTheme.primary),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (catalog.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: GrocerTheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun produit dans "${widget.category.nom}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: GrocerTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _showAddProductChoice,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un produit'),
                    style: FilledButton.styleFrom(backgroundColor: GrocerTheme.primary),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _load,
            color: GrocerTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: catalog.products.length,
              itemBuilder: (context, index) {
                final p = catalog.products[index];
                final isSelected = _selectedProductIds.contains(p.id);
                return _ProductCard(
                  product: p,
                  onTap: _selectionModeProducts
                      ? () => _toggleProductSelection(p.id)
                      : () => _showProductOptions(p),
                  selectionMode: _selectionModeProducts,
                  isSelected: isSelected,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _selectionModeProducts
          ? null
          : FloatingActionButton(
              onPressed: _showAddProductChoice,
              backgroundColor: GrocerTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool isSelected;

  const _ProductCard({
    required this.product,
    required this.onTap,
    this.selectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imagePrincipale != null
        ? ApiConstants.formatImageUrl(product.imagePrincipale)
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: GrocerTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selectionMode && isSelected ? GrocerTheme.primary : GrocerTheme.border,
          width: selectionMode && isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    activeColor: GrocerTheme.primary,
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: GrocerTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.prix.toStringAsFixed(2)} DH',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: GrocerTheme.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              if (!selectionMode)
                const Icon(Icons.chevron_right, color: GrocerTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: GrocerTheme.border.withValues(alpha: 0.3),
      child: const Icon(Icons.image_not_supported_outlined, color: GrocerTheme.textMuted),
    );
  }
}

/// Feuille de sélection multiple pour « Choisir un produit existant ».
class _ExistingProductsMultiSelectSheet extends StatefulWidget {
  final List<Product> products;
  final ScrollController scrollController;
  final VoidCallback onBack;
  final void Function(List<Product> selected) onAddSelected;

  const _ExistingProductsMultiSelectSheet({
    required this.products,
    required this.scrollController,
    required this.onBack,
    required this.onAddSelected,
  });

  @override
  State<_ExistingProductsMultiSelectSheet> createState() => _ExistingProductsMultiSelectSheetState();
}

class _ExistingProductsMultiSelectSheetState extends State<_ExistingProductsMultiSelectSheet> {
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.products.map((p) => p.id));
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(bool value) {
    setState(() {
      if (value) {
        _selectedIds.addAll(widget.products.map((p) => p.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIds.length;
    final allSelected = selectedCount == widget.products.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                color: GrocerTheme.primary,
                tooltip: 'Retour',
              ),
              Expanded(
                child: Text(
                  'Choisir un produit existant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: GrocerTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: allSelected,
                tristate: true,
                onChanged: (v) => _selectAll(v ?? false),
                activeColor: GrocerTheme.primary,
              ),
              TextButton(
                onPressed: () => _selectAll(true),
                child: const Text('Tout sélectionner'),
              ),
              TextButton(
                onPressed: () => _selectAll(false),
                child: const Text('Tout désélectionner'),
              ),
              const Spacer(),
              Text(
                '$selectedCount / ${widget.products.length}',
                style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              final product = widget.products[index];
              final selected = _selectedIds.contains(product.id);
              return CheckboxListTile(
                value: selected,
                onChanged: (_) => _toggle(product.id),
                title: Text(product.nom),
                subtitle: Text(
                  product.isRetiredMine
                      ? '${product.prix.toStringAsFixed(2)} DH — Retiré précédemment (réintégrer)'
                      : '${product.prix.toStringAsFixed(2)} DH',
                  style: TextStyle(fontSize: 13, color: GrocerTheme.textMuted),
                ),
                secondary: Icon(
                  product.isRetiredMine ? Icons.restore : Icons.inventory_2_outlined,
                  color: GrocerTheme.primary,
                ),
                activeColor: GrocerTheme.primary,
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: selectedCount == 0
                  ? null
                  : () {
                      final selected = widget.products.where((p) => _selectedIds.contains(p.id)).toList();
                      widget.onAddSelected(selected);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: GrocerTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                selectedCount == 0
                    ? 'Sélectionnez au moins un produit'
                    : 'Ajouter $selectedCount produit(s) au catalogue',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
