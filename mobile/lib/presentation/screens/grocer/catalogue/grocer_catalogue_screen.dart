import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/product.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/grocer_catalog_provider.dart';
import '../grocer_theme.dart';
import 'grocer_category_products_screen.dart';

/// Page Catalogue : affiche uniquement les catégories où l'épicier a déjà des produits.
/// Bouton "Ajouter une catégorie" : choix "catégorie existante" ou "nouvelle catégorie".
/// [onRegisterRefresh] : appelé avec la fonction de rafraîchissement (ex. au clic sur l'onglet Catalogue).
class GrocerCatalogueScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRegisterRefresh;

  const GrocerCatalogueScreen({super.key, this.onRegisterRefresh});

  @override
  State<GrocerCatalogueScreen> createState() => _GrocerCatalogueScreenState();
}

class _GrocerCatalogueScreenState extends State<GrocerCatalogueScreen> {
  bool _selectionModeCategories = false;
  final Set<int> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      widget.onRegisterRefresh?.call(_load);
    });
  }

  void _toggleCategorySelection(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  Future<void> _confirmBulkRemoveCategories() async {
    final n = _selectedCategoryIds.length;
    if (n == 0) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer du catalogue'),
        content: Text(
          'Retirer $n catégorie(s) de votre catalogue ?\n\n'
          'Les produits de ces catégories seront retirés du catalogue mais resteront en base de données. '
          'Vous pourrez les restaurer plus tard.',
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
    for (final id in _selectedCategoryIds) {
      final ok = await catalog.removeCategoryFromCatalogue(auth.token, id);
      if (ok) removed++;
    }
    setState(() {
      _selectionModeCategories = false;
      _selectedCategoryIds.clear();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$removed catégorie(s) retirée(s) du catalogue')),
    );
    _load();
  }

  int? _storeId() {
    final id = context.read<AuthProvider>().store?['id'];
    if (id == null) return null;
    if (id is int) return id;
    if (id is num) return id.toInt();
    return null;
  }

  Future<void> _load() async {
    await context.read<GrocerCatalogProvider>().fetchCategoriesByStore(_storeId());
  }

  void _openCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GrocerCategoryProductsScreen(category: category),
      ),
    ).then((_) => _load());
  }

  Future<void> _openRestoreCategory(Category category) async {
    final auth = context.read<AuthProvider>();
    final catalog = context.read<GrocerCatalogProvider>();
    await catalog.fetchInactiveProductsForCategory(auth.token, category.id);
    if (!mounted) return;
    if (catalog.inactiveProductsForRestore.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun produit à restaurer dans cette catégorie')),
      );
      return;
    }
    final result = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => _RestoreCategoryScreen(
          category: category,
          products: catalog.inactiveProductsForRestore,
          token: auth.token ?? '',
        ),
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final ok = await catalog.restoreCategoryWithProducts(auth.token, category.id, result.toList());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.length} produit(s) restauré(s)')),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(catalog.error ?? 'Erreur')),
      );
    }
  }

  Future<void> _confirmRemoveCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer du catalogue'),
        content: Text(
          'Retirer « ${category.nom} » de votre catalogue ?\n\n'
          'Tous les produits de cette catégorie seront retirés de votre catalogue (données conservées en base). '
          'La catégorie restera disponible dans le système et vous pourrez la réajouter plus tard.',
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
    final ok = await catalog.removeCategoryFromCatalogue(auth.token, category.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catégorie retirée du catalogue')),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(catalog.error ?? 'Erreur')),
      );
    }
  }

  void _showAddCategoryChoice() {
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
                'Ajouter des produits à une catégorie déjà existante ou créer une nouvelle catégorie.',
                style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openExistingCategoryList();
                },
                icon: const Icon(Icons.folder_outlined),
                label: const Text('Choisir une catégorie existante'),
                style: FilledButton.styleFrom(
                  backgroundColor: GrocerTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openNewCategoryForm();
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Créer une nouvelle catégorie'),
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

  void _openExistingCategoryList() async {
    final catalog = context.read<GrocerCatalogProvider>();
    await catalog.fetchAllCategories();
    if (!mounted) return;
    if (catalog.allCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune catégorie disponible')),
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
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Consumer<GrocerCatalogProvider>(
          builder: (context, catalog, _) {
            // N'afficher que les catégories que l'épicier n'a pas encore admises (éviter les doublons)
            final myIds = catalog.myCategories.map((c) => c.id).toSet();
            final categoriesToShow = catalog.allCategories
                .where((c) => !myIds.contains(c.id))
                .toList();
            void goBackToChoice() {
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showAddCategoryChoice();
              });
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: goBackToChoice,
                        color: GrocerTheme.primary,
                        tooltip: 'Retour',
                      ),
                      Expanded(
                        child: Text(
                          'Choisir une catégorie existante',
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
                Expanded(
                  child: categoriesToShow.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Vous avez déjà ajouté toutes les catégories disponibles. Créez une nouvelle catégorie si besoin.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
                                ),
                                const SizedBox(height: 24),
                                OutlinedButton.icon(
                                  onPressed: goBackToChoice,
                                  icon: const Icon(Icons.arrow_back, size: 20),
                                  label: const Text('Retour au choix'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: GrocerTheme.primary,
                                    side: const BorderSide(color: GrocerTheme.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: categoriesToShow.length,
                          itemBuilder: (context, index) {
                            final category = categoriesToShow[index];
                            return ListTile(
                              leading: const Icon(Icons.folder_outlined, color: GrocerTheme.primary),
                              title: Text(category.nom),
                              onTap: () {
                                Navigator.pop(ctx);
                                _openCategory(category);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openNewCategoryForm() async {
    final nomController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: nomController,
          decoration: const InputDecoration(
            labelText: 'Nom de la catégorie',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (nomController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: GrocerTheme.primary),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    final nom = nomController.text.trim();
    nomController.dispose();
    if (result != true || nom.isEmpty || !mounted) return;
    final auth = context.read<AuthProvider>();
    final catalog = context.read<GrocerCatalogProvider>();
    final created = await catalog.createCategory(auth.token, nom);
    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catégorie créée')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GrocerCategoryProductsScreen(category: created),
        ),
      ).then((_) => _load());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(catalog.error ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GrocerCatalogProvider, AuthProvider>(
      builder: (context, catalog, auth, _) {
        return Scaffold(
          backgroundColor: GrocerTheme.background,
          body: catalog.isLoading && catalog.myCategories.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: GrocerTheme.primary),
                )
              : catalog.myCategories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: GrocerTheme.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Vous n\'avez pas encore de catégories avec des produits.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: GrocerTheme.textMuted),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ajoutez une catégorie pour commencer à enregistrer vos produits.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _showAddCategoryChoice,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter une catégorie'),
                              style: FilledButton.styleFrom(backgroundColor: GrocerTheme.primary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildCategoryList(catalog),
        );
      },
    );
  }

  Widget _buildSelectionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (!_selectionModeCategories)
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectionModeCategories = true),
              icon: const Icon(Icons.checklist_rtl, size: 20),
              label: const Text('Sélectionner'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GrocerTheme.primary,
                side: const BorderSide(color: GrocerTheme.primary),
              ),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() {
                _selectionModeCategories = false;
                _selectedCategoryIds.clear();
              }),
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _selectedCategoryIds.isEmpty ? null : () => _confirmBulkRemoveCategories(),
              style: TextButton.styleFrom(foregroundColor: GrocerTheme.trendNegative),
              child: Text('Supprimer (${_selectedCategoryIds.length})'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryList(GrocerCatalogProvider catalog) {
    final retiredCount = catalog.retiredCategories.length;
    final totalItems = catalog.myCategories.length + 1 + (retiredCount > 0 ? 1 + retiredCount : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSelectionBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: GrocerTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: totalItems,
        itemBuilder: (context, index) {
          if (index < catalog.myCategories.length) {
            final category = catalog.myCategories[index];
            final isSelected = _selectedCategoryIds.contains(category.id);
            return _CategoryCard(
              category: category,
              onTap: _selectionModeCategories
                  ? () => _toggleCategorySelection(category.id)
                  : () => _openCategory(category),
              onRemove: () => _confirmRemoveCategory(category),
              selectionMode: _selectionModeCategories,
              isSelected: isSelected,
            );
          }
          if (index == catalog.myCategories.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _showAddCategoryChoice,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Ajouter une catégorie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GrocerTheme.primary,
                  side: const BorderSide(color: GrocerTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            );
          }
          if (retiredCount > 0 && index == catalog.myCategories.length + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Text(
                'Catégories retirées',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: GrocerTheme.textMuted,
                ),
              ),
            );
          }
          if (retiredCount > 0 && index > catalog.myCategories.length + 1) {
            final category = catalog.retiredCategories[index - catalog.myCategories.length - 2];
            return _RetiredCategoryCard(
              category: category,
              onRestore: () => _openRestoreCategory(category),
            );
          }
          return const SizedBox.shrink();
        },
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool selectionMode;
  final bool isSelected;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.onRemove,
    this.selectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GrocerTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: GrocerTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: GrocerTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.productCount ?? 0} produit(s)',
                      style: TextStyle(
                        fontSize: 13,
                        color: GrocerTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!selectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: GrocerTheme.textMuted,
                  tooltip: 'Retirer du catalogue',
                  onPressed: onRemove,
                ),
                const Icon(Icons.chevron_right, color: GrocerTheme.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RetiredCategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onRestore;

  const _RetiredCategoryCard({
    required this.category,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: GrocerTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GrocerTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: GrocerTheme.textMuted.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_off_outlined,
                color: GrocerTheme.textMuted,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.nom,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: GrocerTheme.textDark.withValues(alpha: 0.8),
                    ),
                  ),
                  if ((category.retiredCount ?? 0) > 0)
                    Text(
                      '${category.retiredCount} produit(s) retiré(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: GrocerTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore, size: 20),
              label: const Text('Restaurer'),
              style: FilledButton.styleFrom(
                backgroundColor: GrocerTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran de restauration d'une catégorie : sélection multiple des produits à réactiver.
class _RestoreCategoryScreen extends StatefulWidget {
  final Category category;
  final List<Product> products;
  final String token;

  const _RestoreCategoryScreen({
    required this.category,
    required this.products,
    required this.token,
  });

  @override
  State<_RestoreCategoryScreen> createState() => _RestoreCategoryScreenState();
}

class _RestoreCategoryScreenState extends State<_RestoreCategoryScreen> {
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
    final allSelected = _selectedIds.length == widget.products.length;

    return Scaffold(
      backgroundColor: GrocerTheme.background,
      appBar: AppBar(
        backgroundColor: GrocerTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Restaurer « ${widget.category.nom} »'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                  '${_selectedIds.length} / ${widget.products.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: GrocerTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                final selected = _selectedIds.contains(product.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: selected,
                    onChanged: (_) => _toggle(product.id),
                    title: Text(product.nom),
                    subtitle: Text(
                      '${product.prix.toStringAsFixed(2)} DH',
                      style: TextStyle(
                        fontSize: 13,
                        color: GrocerTheme.textMuted,
                      ),
                    ),
                    secondary: product.imagePrincipale != null && product.imagePrincipale!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ApiConstants.formatImageUrl(product.imagePrincipale),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                            ),
                          )
                        : const Icon(Icons.inventory_2_outlined),
                    activeColor: GrocerTheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => Navigator.pop(context, _selectedIds),
            style: FilledButton.styleFrom(
              backgroundColor: GrocerTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _selectedIds.isEmpty
                  ? 'Sélectionnez au moins un produit'
                  : 'Restaurer la catégorie avec ${_selectedIds.length} produit(s)',
            ),
          ),
        ),
      ),
    );
  }
}
