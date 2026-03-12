import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';

class AddEpicierScreen extends StatefulWidget {
  const AddEpicierScreen({super.key});

  @override
  State<AddEpicierScreen> createState() => _AddEpicierScreenState();
}

class _AddEpicierScreenState extends State<AddEpicierScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _mdpController = TextEditingController();
  final _nomBoutiqueController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _mdpController.dispose();
    _nomBoutiqueController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.post('/admin/register-epicier', {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'mdp': _mdpController.text,
        'nom_boutique': _nomBoutiqueController.text,
        'adresse': _adresseController.text,
        'telephone': _telephoneController.text,
        'description_boutique': _descriptionController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Épicier créé avec succès !')),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: const Text('Créer un compte Épicier'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations du gérant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5016)),
              ),
              const SizedBox(height: 16),
              _buildTextField('Nom', _nomController, Icons.person),
              const SizedBox(height: 12),
              _buildTextField('Prénom', _prenomController, Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField('Email', _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField('Mot de passe', _mdpController, Icons.lock, obscureText: true),
              
              const SizedBox(height: 32),
              const Text(
                'Informations de la boutique',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5016)),
              ),
              const SizedBox(height: 16),
              _buildTextField('Nom de la boutique', _nomBoutiqueController, Icons.storefront),
              const SizedBox(height: 12),
              _buildTextField('Adresse', _adresseController, Icons.location_on),
              const SizedBox(height: 12),
              _buildTextField('Téléphone', _telephoneController, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField('Description', _descriptionController, Icons.description, maxLines: 3),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enregistrer l\'Épicier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, 
      {bool obscureText = false, TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2D5016)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (val) => val == null || val.isEmpty ? 'Ce champ est requis' : null,
    );
  }
}
