import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/category.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  final Category? category;

  const AdminCategoryFormScreen({super.key, this.category});

  @override
  State<AdminCategoryFormScreen> createState() => _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.nom);
    _descriptionController = TextEditingController(text: widget.category?.description);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Non authentifié');

      final data = {
        'nom': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
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
                      const SizedBox(height: 10),
                      _buildTextField('Nom de la catégorie *', _nameController, isRequired: true),
                      const SizedBox(height: 15),
                      _buildTextField('Description', _descriptionController, maxLines: 3),
                      const SizedBox(height: 30),
                      _buildActionButtons(primaryColor),
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

}
