import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart' as model;
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';

class AdminProductFormScreen extends StatefulWidget {
  final UserModel storeOwner;
  final Product? product;

  const AdminProductFormScreen({super.key, required this.storeOwner, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;
  late TextEditingController _unitTypeController;
  late TextEditingController _descriptionController;
  
  int? _selectedCategoryId;
  bool _isVisible = true;
  List<model.Category> _categories = [];
  bool _isSubmitting = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.nom);
    _priceController = TextEditingController(text: widget.product?.prix.toString());
    _stockController = TextEditingController(text: '24'); // Example default
    _unitController = TextEditingController(text: '1 Litre'); // Example default
    _unitTypeController = TextEditingController(text: 'Bouteille'); // Example default
    _descriptionController = TextEditingController(text: widget.product?.description);
    _selectedCategoryId = widget.product?.categoryId;
    _isVisible = widget.product?.isRetiredMine == false;
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final List<dynamic> data = await _apiService.get('/admin/categories', token: token);
      if (mounted) {
        setState(() {
          _categories = data.map((json) => model.Category.fromJson(json)).toList();
          if (_selectedCategoryId == null && _categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final data = {
        'nom': _nameController.text,
        'prix': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'categorie_id': _selectedCategoryId,
        'epicier_id': widget.storeOwner.store?['id'],
        'is_active': _isVisible,
      };

      if (token == null) throw Exception('Non authentifié');

      if (widget.product == null) {
        // Upload image first if picked
        if (_imageFile != null) {
          final res = await _apiService.uploadProductImageAdmin(
            token: token,
            categorieId: _selectedCategoryId!,
            bytes: await _imageFile!.readAsBytes(),
            filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
            productName: _nameController.text,
          );
          data['image_principale'] = res;
        }
        await _apiService.post('/admin/products', data, token: token);
      } else {
        // Update product
        if (_imageFile != null) {
          final res = await _apiService.uploadProductImageAdmin(
            token: token,
            categorieId: _selectedCategoryId!,
            bytes: await _imageFile!.readAsBytes(),
            filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
            productName: _nameController.text,
          );
          data['image_principale'] = res;
        }
        await _apiService.put('/admin/products/${widget.product!.id}', data, token: token);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5016),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product == null ? 'Nouveau produit' : 'Modifier le produit',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
            Text(
              widget.storeOwner.store?['nom_boutique'] ?? widget.storeOwner.fullName,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF26444),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(child: Text('ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoSection(),
                const SizedBox(height: 20),
                _buildInfoSection(),
                const SizedBox(height: 30),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.camera_alt, size: 20, color: Color(0xFF2D1A0E)),
              SizedBox(width: 8),
              Text('Photo du produit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E), fontFamily: 'Outfit')),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6F0),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFF5EDDA), style: BorderStyle.solid),
                image: _imageFile != null 
                  ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                  : widget.product?.imagePrincipale != null
                    ? DecorationImage(image: NetworkImage(ApiConstants.formatImageUrl(widget.product!.imagePrincipale)), fit: BoxFit.cover)
                    : null,
              ),
              child: _imageFile == null && widget.product?.imagePrincipale == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_enhance_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Appuyer pour ajouter une photo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )
                : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit, size: 20, color: Color(0xFF2D1A0E)),
              SizedBox(width: 8),
              Text('Informations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E), fontFamily: 'Outfit')),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Nom du produit *', _nameController, 'Ex: Huile d\'olive'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Prix (DH) *', _priceController, '0', keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Stock *', _stockController, '0', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Unité *', _unitController, 'Ex: 1 Litre')),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Type d\'unité', _unitTypeController, 'Ex: Bouteille')),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Catégorie *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF6F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCategoryId,
                isExpanded: true,
                items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom))).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField('Description', _descriptionController, 'Description du produit...', maxLines: 3),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Produit visible pour les clients'),
              Switch(
                value: _isVisible,
                onChanged: (val) => setState(() => _isVisible = val),
                activeColor: const Color(0xFF2D5016),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFFDF6F0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFF5EDDA),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF2D1A0E), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFF26444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: _isSubmitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Enregistrer le produit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
