import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/services/api_service.dart';
import '../../../../../providers/auth_provider.dart';
import '../../grocer_theme.dart';

class AvisSignalSheet extends StatefulWidget {
  final int avisId;
  const AvisSignalSheet({super.key, required this.avisId});

  @override
  State<AvisSignalSheet> createState() => _AvisSignalSheetState();
}

class _AvisSignalSheetState extends State<AvisSignalSheet> {
  final ApiService _api = ApiService();
  final TextEditingController _descCtrl = TextEditingController();

  String _motif = 'Contenu faux ou mensonger';
  final List<String> _motifs = const [
    'Contenu faux ou mensonger',
    'Langage offensant',
    'Avis hors sujet',
    'Client non identifiable',
    'Autre',
  ];

  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.post(
        '/epicier/avis/${widget.avisId}/reclamations',
        {
          'motif': _motif,
          'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        },
        token: token,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Signaler cet avis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Motif (obligatoire)'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _motif,
              items: _motifs
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _motif = v ?? _motif),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Description (optionnelle)'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Expliquez pourquoi cet avis est faux / inapproprié',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GrocerTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Envoyer le signalement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

