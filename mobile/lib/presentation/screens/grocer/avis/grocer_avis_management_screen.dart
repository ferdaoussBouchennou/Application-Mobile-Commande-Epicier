import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';

class GrocerAvisManagementScreen extends StatefulWidget {
  const GrocerAvisManagementScreen({super.key});

  @override
  State<GrocerAvisManagementScreen> createState() =>
      _GrocerAvisManagementScreenState();
}

class _GrocerAvisManagementScreenState extends State<GrocerAvisManagementScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _avis = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final res = await _api.get('/epicier/avis', token: token);
      final map = res is Map<String, dynamic> ? res : <String, dynamic>{};
      final list = (map['avis'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _avis = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.amber.shade700;
      case 'En examen':
        return Colors.blue.shade700;
      case 'Acceptée':
        return Colors.green.shade700;
      case 'Refusée':
        return Colors.red.shade700;
      case 'Clôturée':
        return Colors.grey.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openContestSheet(Map<String, dynamic> avis) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ContestAvisSheet(
        avisId: (avis['id'] as num?)?.toInt() ?? 0,
        api: _api,
      ),
    );
    if (result == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contestation envoyée')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrocerTheme.background,
      appBar: AppBar(
        backgroundColor: GrocerTheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Gestion des avis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: GrocerTheme.primary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: GrocerTheme.textDark),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GrocerTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _avis.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun avis client pour le moment.',
                        style: TextStyle(color: GrocerTheme.textMuted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: GrocerTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _avis.length,
                        itemBuilder: (context, index) {
                          final a = _avis[index];
                          final note = (a['note'] as num?)?.toInt() ?? 0;
                          final commentaire = a['commentaire']?.toString() ?? '';
                          final clientNom = a['client_nom']?.toString() ?? 'Client';
                          final dateAvis = a['date_avis']?.toString();
                          final recs = (a['contestations'] as List?) ?? [];
                          final latest = recs.isNotEmpty && recs.first is Map
                              ? Map<String, dynamic>.from(recs.first as Map)
                              : null;
                          final latestStatus = latest?['statut']?.toString();
                          final hasActive = latestStatus == 'En attente' || latestStatus == 'En examen';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: GrocerTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: GrocerTheme.primarySoft,
                                      child: Text(
                                        (clientNom.isNotEmpty ? clientNom[0] : '?').toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: GrocerTheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clientNom,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: GrocerTheme.textDark,
                                            ),
                                          ),
                                          if (dateAvis != null && dateAvis.isNotEmpty)
                                            Text(
                                              DateFormat('dd/MM/yyyy').format(DateTime.parse(dateAvis).toLocal()),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: GrocerTheme.textMuted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < note ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: const Color(0xFFE8B923),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (commentaire.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    commentaire,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: GrocerTheme.textDark,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                if (latestStatus != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _statusColor(latestStatus).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Dernier signalement: $latestStatus',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(latestStatus),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: hasActive ? null : () => _openContestSheet(a),
                                    icon: const Icon(Icons.flag_outlined, size: 18),
                                    label: Text(
                                      hasActive
                                          ? 'Signalement en cours'
                                          : 'Signaler',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: GrocerTheme.primary,
                                      side: const BorderSide(color: GrocerTheme.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ContestAvisSheet extends StatefulWidget {
  const _ContestAvisSheet({required this.avisId, required this.api});

  final int avisId;
  final ApiService api;

  @override
  State<_ContestAvisSheet> createState() => _ContestAvisSheetState();
}

class _ContestAvisSheetState extends State<_ContestAvisSheet> {
  final _descCtrl = TextEditingController();
  bool _saving = false;
  String _motif = 'Contenu faux ou mensonger';
  final List<String> _motifs = const [
    'Contenu faux ou mensonger',
    'Langage offensant',
    'Avis hors sujet',
    'Client non identifiable',
    'Autre',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descCtrl.text.trim();
    setState(() => _saving = true);
    try {
      final token = context.read<AuthProvider>().token;
      await widget.api.post(
        '/epicier/avis/${widget.avisId}/reclamations',
        {
          'motif': _motif,
          'description': desc.isEmpty ? null : desc,
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Signaler cet avis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Motif'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _motif,
              items: _motifs
                  .map((m) => DropdownMenuItem<String>(value: m, child: Text(m)))
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
                hintText: 'Décrivez pourquoi cet avis est signalé...',
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
