import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';

class ClaimSubmissionScreen extends StatefulWidget {
  final int? commandeId;

  const ClaimSubmissionScreen({super.key, this.commandeId});

  @override
  State<ClaimSubmissionScreen> createState() => _ClaimSubmissionScreenState();
}

class _ClaimSubmissionScreenState extends State<ClaimSubmissionScreen> {
  final _api = ApiService();
  final _descriptionController = TextEditingController();
  String? _selectedMotif;
  File? _image;
  Uint8List? _webImage;
  String? _webFilename;
  bool _isLoading = false;

  final List<String> _motifs = [
    'Produit manquant',
    'Produit abîmé',
    'Erreur de commande',
    'Retard important',
    'Autre'
  ];

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _webFilename = pickedFile.name;
          });
        } else {
          setState(() {
            _image = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du choix de l\'image: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedMotif == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      
      final Map<String, List<int>> files = {};
      final Map<String, String> filenames = {};

      if (kIsWeb) {
        if (_webImage != null) {
          files['photo'] = _webImage!;
          filenames['photo'] = _webFilename ?? 'claim.jpg';
        }
      } else {
        if (_image != null) {
          files['photo'] = await _image!.readAsBytes();
          filenames['photo'] = _image!.path.split('/').last;
        }
      }

      await _api.postMultipart(
        '/reclamations',
        {
          'commande_id': widget.commandeId,
          'motif': _selectedMotif,
          'description': _descriptionController.text,
        },
        token: auth.token,
        files: files.isNotEmpty ? files : null,
        filenames: filenames.isNotEmpty ? filenames : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réclamation soumise avec succès')),
        );
        Navigator.pop(context);
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
    const primary = Color(0xFF2D5016);
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: const Text('Nouvelle Réclamation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.commandeId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Réclamation pour la commande #CMD-${widget.commandeId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            
            const Text('Motif de la réclamation', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMotif,
                  isExpanded: true,
                  hint: const Text('Sélectionnez un motif'),
                  items: _motifs.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setState(() => _selectedMotif = val),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Description détaillée', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Expliquez-nous le problème...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Photo (Facultatif)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: (_image != null || (kIsWeb && _webImage != null))
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.memory(_webImage!, fit: BoxFit.cover)
                            : Image.file(_image!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 32),
                          SizedBox(height: 8),
                          Text('Ajouter une photo', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Envoyer la réclamation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
