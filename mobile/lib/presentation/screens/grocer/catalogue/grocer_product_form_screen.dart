import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/product.dart';
import '../../../../providers/grocer_catalog_provider.dart';
import '../grocer_theme.dart';

/// Formulaire d'ajout ou d'édition d'un produit (catalogue épicier).
/// [initialCategoryId] pré-sélectionne la catégorie (ex. quand on ouvre depuis une catégorie).
class GrocerProductFormScreen extends StatefulWidget {
  final String token;
  final Product? product;
  final int? initialCategoryId;

  const GrocerProductFormScreen({
    super.key,
    required this.token,
    this.product,
    this.initialCategoryId,
  });

  @override
  State<GrocerProductFormScreen> createState() => _GrocerProductFormScreenState();
}

class _GrocerProductFormScreenState extends State<GrocerProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prixController;
  late TextEditingController _descriptionController;
  int? _selectedCategoryId;
  /// Chemin serveur (image_principale) : initial ou après upload.
  String? _imagePath;
  bool _saving = false;
  bool _uploadingImage = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.product?.nom ?? '');
    _prixController = TextEditingController(
      text: widget.product != null ? widget.product!.prix.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _imagePath = widget.product?.imagePrincipale;
    _selectedCategoryId = widget.product?.categoryId ?? widget.initialCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GrocerCatalogProvider>().fetchAllCategories();
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final catId = _selectedCategoryId;
    if (catId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord choisir une catégorie')),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    final name = file.name;
    if (bytes == null || name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lire le fichier')),
        );
      }
      return;
    }
    setState(() => _uploadingImage = true);
    final catalog = context.read<GrocerCatalogProvider>();
    final productName = _nomController.text.trim();
    final path = await catalog.uploadProductImage(widget.token, catId, bytes, name, productName: productName.isEmpty ? null : productName);
    setState(() {
      _uploadingImage = false;
      if (path != null) _imagePath = path;
    });
    if (!mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image enregistrée')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(catalog.error ?? 'Erreur lors de l\'upload')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final catId = _selectedCategoryId;
    if (catId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une catégorie')),
      );
      return;
    }
    setState(() => _saving = true);
    final catalog = context.read<GrocerCatalogProvider>();
    final data = {
      'nom': _nomController.text.trim(),
      'prix': double.tryParse(_prixController.text.replaceAll(',', '.')) ?? 0,
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'categorie_id': catId,
      'image_principale': _imagePath?.trim().isEmpty ?? true ? null : _imagePath?.trim(),
    };
    bool ok;
    if (isEdit) {
      ok = await catalog.updateProduct(widget.token, widget.product!.id, data);
    } else {
      ok = await catalog.createProduct(widget.token, data);
    }
    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Produit mis à jour' : 'Produit ajouté')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(catalog.error ?? 'Erreur')),
      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Retour',
        ),
        title: Text(isEdit ? 'Modifier le produit' : 'Ajouter un produit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du produit *',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer<GrocerCatalogProvider>(
              builder: (context, catalog, _) {
                final categories = catalog.allCategories;
                return DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) => v == null ? 'Choisissez une catégorie' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prixController,
              decoration: const InputDecoration(
                labelText: 'Prix (DH) *',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Prix invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Image du produit (optionnel)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            if (_imagePath != null && _imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiConstants.formatImageUrl(_imagePath),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _uploadingImage ? null : () => setState(() => _imagePath = null),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Retirer l\'image'),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _uploadingImage ? null : _pickAndUploadImage,
                icon: _uploadingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_uploadingImage ? 'Upload en cours...' : 'Upload / Choisir une image'),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: GrocerTheme.primary,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEdit ? 'Enregistrer' : 'Ajouter au catalogue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
