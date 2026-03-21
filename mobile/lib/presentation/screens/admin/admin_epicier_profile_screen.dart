import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class AdminEpicierProfileScreen extends StatefulWidget {
  final UserModel user;

  const AdminEpicierProfileScreen({super.key, required this.user});

  @override
  State<AdminEpicierProfileScreen> createState() => _AdminEpicierProfileScreenState();
}

class _AdminEpicierProfileScreenState extends State<AdminEpicierProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  bool _isSaving = false;
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _storeNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  XFile? _newDocFile;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.prenom);
    _lastNameController = TextEditingController(text: widget.user.nom);
    _emailController = TextEditingController(text: widget.user.email);
    _storeNameController = TextEditingController(text: widget.user.store?['nom_boutique']);
    _phoneController = TextEditingController(text: widget.user.store?['telephone']);
    _addressController = TextEditingController(text: widget.user.store?['adresse']);
    _descriptionController = TextEditingController(text: widget.user.store?['description']);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _storeNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _newDocFile = file);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      
      // 1. Update User (prenom, nom, email, doc_verf if changed)
      final userFields = {
        'prenom': _firstNameController.text.trim(),
        'nom': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (_newDocFile != null) {
        final bytes = await _newDocFile!.readAsBytes();
        await _apiService.putMultipart(
          '/admin/users/${widget.user.id}/details', 
          userFields,
          token: token,
          files: {'document_verification': bytes},
          filenames: {'document_verification': _newDocFile!.name},
        );
      } else {
        await _apiService.put('/admin/users/${widget.user.id}/details', userFields, token: token);
      }

      // 2. Update Store (nom_boutique, telephone, adresse, description)
      if (widget.user.store != null) {
        await _apiService.put('/admin/stores/${widget.user.store!['id']}/details', {
          'nom_boutique': _storeNameController.text.trim(),
          'telephone': _phoneController.text.trim(),
          'adresse': _addressController.text.trim(),
          'description': _descriptionController.text.trim(),
        }, token: token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour avec succès')));
        setState(() {
          _isEditing = false;
          _newDocFile = null;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String storeName = _isEditing ? _storeNameController.text : (widget.user.store?['nom_boutique'] ?? widget.user.fullName);
    final String? imageUrl = widget.user.store?['image_url'];
    final String? docUrl = widget.user.docVerf;
    final String address = _isEditing ? _addressController.text : (widget.user.store?['adresse'] ?? 'Non renseignée');
    final String phone = _isEditing ? _phoneController.text : (widget.user.store?['telephone'] ?? 'N/A');
    final String description = _isEditing ? _descriptionController.text : (widget.user.store?['description'] ?? 'Aucune description fournie.');

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              if (!_isSaving)
                IconButton(
                  icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                ),
              if (_isEditing)
                IconButton(
                  icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
                  onPressed: _isSaving ? null : _saveChanges,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   imageUrl != null 
                    ? Image.network(
                        ApiConstants.formatImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF2D5016),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isEditing)
                              _buildTextField(_storeNameController, "Nom de la boutique", Icons.store)
                            else
                              Text(
                                storeName,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                              ),
                            const SizedBox(height: 4),
                            if (_isEditing)
                              Row(
                                children: [
                                  Expanded(child: _buildTextField(_firstNameController, "Prénom", Icons.person)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildTextField(_lastNameController, "Nom", Icons.person)),
                                ],
                              )
                            else
                              Text(
                                "Gérant: ${widget.user.fullName}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                          ],
                        ),
                      ),
                      if (!_isEditing)
                        _buildChip(
                          widget.user.isActive ? 'ACTIF' : 'SUSPENDU',
                          widget.user.isActive ? const Color(0xFF2D5016) : Colors.red,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard([
                    if (_isEditing) ...[
                      _buildTextField(_emailController, "Email", Icons.email_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, "Téléphone", Icons.phone_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_addressController, "Adresse", Icons.location_on_outlined),
                    ] else ...[
                      _buildInfoRow(Icons.email_outlined, "Email", widget.user.email),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.phone_outlined, "Téléphone", phone),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.location_on_outlined, "Adresse", address),
                    ]
                  ]),
                  const SizedBox(height: 24),
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    _buildTextField(_descriptionController, "Description", Icons.description, maxLines: 3)
                  else
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.5),
                    ),
                  const SizedBox(height: 32),
                  const Text(
                    "Documents de vérification",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                  ),
                  const SizedBox(height: 12),
                  _buildDocCard(docUrl),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFFF26444), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFB5D39D),
      child: const Icon(Icons.store, size: 80, color: Color(0xFF2D5016)),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF26444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF26444), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocCard(String? docUrl) {
    final bool hasNewDoc = _newDocFile != null;
    final bool hasDoc = hasNewDoc || (docUrl != null && docUrl.isNotEmpty);
    final String fileName = hasNewDoc ? _newDocFile!.name : (docUrl?.split('/').last ?? "Aucun document");

    return InkWell(
      onTap: (!hasDoc || _isEditing) ? () async {
        if (!_isEditing) {
          setState(() => _isEditing = true);
        }
        _pickDocument();
      } : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDoc ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasDoc ? const Color(0xFF2D5016).withOpacity(0.2) : Colors.orange.withOpacity(0.5), width: hasDoc ? 1 : 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  hasDoc ? Icons.description_rounded : Icons.warning_amber_rounded,
                  color: hasDoc ? const Color(0xFF2D5016) : Colors.orange,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDoc ? "Justificatif d'activité" : "Document manquant",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        hasNewDoc ? "Nouveau: $fileName" : (hasDoc ? "Cliquer pour visualiser" : "Cliquez ici pour ajouter un document justificatif"),
                        style: TextStyle(color: hasDoc ? Colors.grey.shade600 : Colors.red.shade700, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_isEditing)
                  const Icon(Icons.upload_file_rounded, color: Color(0xFFF26444), size: 28)
                else if (hasDoc && !hasNewDoc)
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFFF26444)),
                    onPressed: () async {
                      final formattedUrl = ApiConstants.formatImageUrl(docUrl);
                      debugPrint('Opening Document URL: $formattedUrl');
                      final url = Uri.parse(formattedUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Impossible d\'ouvrir le document (Lien invalide ou fichier manquant sur le serveur)'))
                          );
                        }
                      }
                    },
                  )
                else if (!hasDoc)
                  const Icon(Icons.add_circle_outline, color: Color(0xFFF26444), size: 28),
              ],
            ),
            if (!hasDoc) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  if (!_isEditing) setState(() => _isEditing = true);
                  _pickDocument();
                },
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('AJOUTER UN DOCUMENT MAINTENANT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF26444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
