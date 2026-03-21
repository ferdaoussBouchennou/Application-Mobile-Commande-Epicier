import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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

  XFile? _imageFile;
  PlatformFile? _docFile;
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
      setState(() => _imageFile = pickedFile);
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      withData: true, // Important for Web
    );
    if (result != null) {
      setState(() => _docFile = result.files.single);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      
      final Map<String, dynamic> fields = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'mdp': _mdpController.text,
        'nom_boutique': _nomBoutiqueController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'description_boutique': _descriptionController.text.trim(),
      };

      final Map<String, List<int>> files = {};
      final Map<String, String> filenames = {};

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        files['image_boutique'] = bytes;
        filenames['image_boutique'] = _imageFile!.name;
      }

      if (_docFile != null) {
        final bytes = _docFile!.bytes;
        if (bytes != null) {
          files['document_verification'] = bytes;
          filenames['document_verification'] = _docFile!.name;
        }
      }

      await _apiService.postMultipart(
        '/admin/register-epicier',
        fields,
        token: token,
        files: files,
        filenames: filenames,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Épicier créé avec succès !')),
        );
        Navigator.pop(context, true);
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

  Widget _buildFilePicker({required String label, required dynamic file, required VoidCallback onTap, required IconData icon}) {
    String? fileName;
    if (file is XFile) fileName = file.name;
    if (file is PlatformFile) fileName = file.name;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF6F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: fileName != null ? const Color(0xFF2D5016) : Colors.grey.shade300, width: 1, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (fileName != null ? const Color(0xFF2D5016) : const Color(0xFFF26444)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: fileName != null ? const Color(0xFF2D5016) : const Color(0xFFF26444), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    fileName ?? 'Aucun fichier sélectionné',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (fileName != null) const Icon(Icons.check_circle, color: Color(0xFF2D5016), size: 20),
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
