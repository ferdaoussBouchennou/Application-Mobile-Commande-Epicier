import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../auth/login_screen.dart';

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

  File? _imageFile;
  File? _docFile;
  final _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() => _docFile = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final uri = Uri.parse('${ApiConstants.baseUrl}/admin/register-epicier');
      var request = http.MultipartRequest('POST', uri);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['nom'] = _nomController.text;
      request.fields['prenom'] = _prenomController.text;
      request.fields['email'] = _emailController.text;
      request.fields['mdp'] = _mdpController.text;
      request.fields['nom_boutique'] = _nomBoutiqueController.text;
      request.fields['adresse'] = _adresseController.text;
      request.fields['telephone'] = _telephoneController.text;
      request.fields['description_boutique'] = _descriptionController.text;

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image_boutique', _imageFile!.path));
      }
      if (_docFile != null) {
        request.files.add(await http.MultipartFile.fromPath('document_verification', _docFile!.path));
      }

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Épicier créé avec succès !')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(responseData.body);
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
        title: const Text('Nouvel Épicier', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: 'Profil Personnel',
                      icon: Icons.person_add_rounded,
                      children: [
                        _buildTextField('Nom', _nomController, Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField('Prénom', _prenomController, Icons.person_pin_rounded),
                        const SizedBox(height: 16),
                        _buildTextField('Email professionnel', _emailController, Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _buildTextField('Mot de passe par défaut', _mdpController, Icons.lock_outline_rounded, obscureText: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Ma Boutique',
                      icon: Icons.storefront_rounded,
                      children: [
                        _buildTextField('Nom de l\'enseigne', _nomBoutiqueController, Icons.branding_watermark_outlined),
                        const SizedBox(height: 16),
                        _buildTextField('Adresse complète', _adresseController, Icons.map_outlined),
                        const SizedBox(height: 16),
                        _buildTextField('Téléphone direct', _telephoneController, Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                        _buildTextField('Description public', _descriptionController, Icons.notes_rounded, maxLines: 3),
                        const SizedBox(height: 20),
                        _buildFilePicker(
                          label: 'Image de la boutique',
                          file: _imageFile,
                          onTap: _pickImage,
                          icon: Icons.add_a_photo_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildFilePicker(
                          label: 'Document de vérification (PDF/Docs)',
                          file: _docFile,
                          onTap: _pickDocument,
                          icon: Icons.file_present_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildSubmitBtn(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20, top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF2D5016),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFFB5D39D),
            child: Icon(Icons.person_add_rounded, size: 40, color: Color(0xFF2D5016)),
          ),
          SizedBox(height: 16),
          Text(
            'Enregistrement Manuel',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Ajoutez un épicier de confiance à la plateforme',
            style: TextStyle(color: Color(0xFFB5D39D), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF26444), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
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
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2D5016), size: 20),
        filled: true,
        fillColor: const Color(0xFFFDF6F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2D5016), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Ce champ est requis' : null,
    );
  }

  Widget _buildFilePicker({required String label, required File? file, required VoidCallback onTap, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF6F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: file != null ? const Color(0xFF2D5016) : Colors.grey.shade300, width: 1, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (file != null ? const Color(0xFF2D5016) : const Color(0xFFF26444)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: file != null ? const Color(0xFF2D5016) : const Color(0xFFF26444), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    file != null ? file.path.split('/').last : 'Aucun fichier sélectionné',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (file != null) const Icon(Icons.check_circle, color: Color(0xFF2D5016), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBtn() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5016).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5016),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('ENREGISTRER L\'ÉPICIER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }
}
