import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/category.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';
import 'admin_category_products_screen.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  final Category? category;

  const AdminCategoryFormScreen({super.key, this.category});

  @override
  State<AdminCategoryFormScreen> createState() => _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _orderController;
  
  bool _isActive = true;
  String? _imageUrl;
  Uint8List? _imageBytes;
  XFile? _pickedFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.nom);
    _descriptionController = TextEditingController(text: widget.category?.description);
    _orderController = TextEditingController(text: widget.category?.displayOrder.toString() ?? '0');
    _isActive = widget.category?.isActive ?? true;
    _imageUrl = widget.category?.imageUrl;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Non authentifié');

      String? finalImageUrl = _imageUrl;

      // Upload icon if picked
      if (_imageBytes != null) {
        finalImageUrl = await _apiService.uploadCategoryIconAdmin(
          token: token,
          bytes: _imageBytes!,
          filename: _pickedFile?.name ?? 'category_${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }

      final data = {
        'nom': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': finalImageUrl,
        'display_order': int.tryParse(_orderController.text) ?? 0,
        'is_active': _isActive,
      };

      if (widget.category == null) {
        await _apiService.post('/admin/categories', data, token: token);
      } else {
        await _apiService.put('/admin/categories/${widget.category!.id}', data, token: token);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteCategory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: const Text('Voulez-vous vraiment supprimer cette catégorie ? Tous les produits associés seront désactivés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Supprimer', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      try {
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        await _apiService.delete('/admin/categories/${widget.category!.id}', token: token);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2D5016);
    const bgColor = Color(0xFFFDF6F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(primaryColor),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildIconPicker(),
                      const SizedBox(height: 25),
                      _buildTextField('Nom de la catégorie *', _nameController, isRequired: true),
                      const SizedBox(height: 15),
                      _buildTextField('Description', _descriptionController, maxLines: 3),
                      const SizedBox(height: 15),
                      _buildTextField('Ordre d\'affichage', _orderController, keyboardType: TextInputType.number),
                      const SizedBox(height: 25),
                      if (widget.category != null) _buildStatsSection(),
                      const SizedBox(height: 20),
                      _buildVisibilityToggle(),
                      const SizedBox(height: 30),
                      _buildActionButtons(primaryColor),
                      if (widget.category != null) ...[
                        const SizedBox(height: 20),
                        _buildDeleteButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                widget.category == null ? 'Nouvelle catégorie' : 'Modifier catégorie',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF26444),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPicker() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE6D5),
            borderRadius: BorderRadius.circular(30),
            image: _imageBytes != null
              ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
              : _imageUrl != null
                ? DecorationImage(image: NetworkImage('${ApiConstants.baseUrl}$_imageUrl'), fit: BoxFit.cover)
                : null,
          ),
          child: (_imageBytes == null && _imageUrl == null)
            ? const Icon(Icons.category_outlined, size: 50, color: Color(0xFF2D5016))
            : null,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _pickImage,
          child: const Text('Changer l\'icône', style: TextStyle(color: Color(0xFFB99D6B), fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF2D1A0E), fontSize: 16),
          validator: isRequired ? (v) => v!.isEmpty ? 'Ce champ est requis' : null : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEFE6D5))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEFE6D5))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D5016))),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return InkWell(
      onTap: () {
        if (widget.category != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminCategoryProductsScreen(
                categoryId: widget.category!.id,
                categoryName: widget.category!.nom,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EDDA).withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/images/shop_icon.png', width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.bar_chart, size: 20)),
                const SizedBox(width: 8),
                const Text('Statistiques', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(widget.category?.productCount.toString() ?? '0', 'Produits'),
                _buildStatItem(widget.category?.storeCount.toString() ?? '0', 'Épiceries'),
                _buildStatItem(widget.category?.ruptureCount.toString() ?? '0', 'Ruptures'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB99D6B))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Catégorie visible', style: TextStyle(fontSize: 16, color: Color(0xFF2D1A0E))),
        Switch(
          value: _isActive,
          activeColor: const Color(0xFF2D5016),
          onChanged: (v) => setState(() => _isActive = v),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Color primary) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFEFE6D5)),
              backgroundColor: const Color(0xFFEFE6D5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF2D5016), fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC86432),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('✓ Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return TextButton.icon(
      onPressed: _isSubmitting ? null : _deleteCategory,
      icon: const Icon(Icons.delete_outline, color: Color(0xFFE57373)),
      label: const Text('Supprimer cette catégorie', style: TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
