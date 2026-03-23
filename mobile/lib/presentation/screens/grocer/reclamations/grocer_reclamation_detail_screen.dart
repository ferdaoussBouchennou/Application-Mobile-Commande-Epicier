import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';

class GrocerReclamationDetailScreen extends StatefulWidget {
  final int reclamationId;

  const GrocerReclamationDetailScreen({super.key, required this.reclamationId});

  @override
  State<GrocerReclamationDetailScreen> createState() =>
      _GrocerReclamationDetailScreenState();
}

class _GrocerReclamationDetailScreenState
    extends State<GrocerReclamationDetailScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;
  final _reponseController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reponseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final res =
          await _api.get(
                '/epicier/reclamations/${widget.reclamationId}',
                token: token,
              )
              as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _data = res;
        _isLoading = false;
        if (res?['reponse_epicier'] != null &&
            res!['reponse_epicier'].toString().isNotEmpty) {
          _reponseController.text = res['reponse_epicier'].toString();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveReponse() async {
    if (_isClosedStatus(_data?['statut']?.toString())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Réclamation déjà résolue')));
      return;
    }
    final reponse = _reponseController.text.trim();
    if (reponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une réponse')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.patch(
        '/reclamations/${widget.reclamationId}',
        {'reponse_epicier': reponse},
        token: context.read<AuthProvider>().token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Réponse enregistrée')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _getStatusColor(String? statut) {
    switch (statut) {
      case 'En attente':
        return Colors.amber.shade700;
      case 'En médiation':
        return Colors.blue.shade700;
      case 'Litige ouvert':
        return Colors.orange.shade700;
      case 'Résolu':
      case 'Remboursé':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  bool _isClosedStatus(String? statut) {
    if (statut == null) return false;
    return statut == 'Résolu' || statut == 'Remboursé';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrocerTheme.background,
      appBar: AppBar(
        backgroundColor: GrocerTheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Détail réclamation',
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
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: GrocerTheme.textDark),
                    ),
                    const SizedBox(height: 16),
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
          : _data == null
          ? const Center(child: Text('Réclamation introuvable'))
          : RefreshIndicator(
              onRefresh: _load,
              color: GrocerTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Réclamation #${_data!['id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: GrocerTheme.textDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    _data!['statut']?.toString(),
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _data!['statut']?.toString() ?? 'Ouverte',
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      _data!['statut']?.toString(),
                                    ),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_data!['commande_id'] != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 18,
                                  color: GrocerTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Commande #${_data!['commande_id']}',
                                  style: const TextStyle(
                                    color: GrocerTheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_data!['client_nom'] != null &&
                              (_data!['client_nom'] as String).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _data!['client_nom'].toString(),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _data!['date_creation'] != null
                                    ? DateFormat('dd/MM/yyyy à HH:mm').format(
                                        DateTime.parse(
                                          _data!['date_creation'].toString(),
                                        ).toLocal(),
                                      )
                                    : '-',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Motif',
                      child: Text(
                        _data!['motif']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          color: GrocerTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Description',
                      child: Text(
                        _data!['description']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: GrocerTheme.textDark,
                        ),
                      ),
                    ),
                    if (_data!['photo'] != null &&
                        (_data!['photo'] as String).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildCard(
                        title: 'Photo jointe',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ApiConstants.formatImageUrl(_data!['photo']),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_data!['reponse_epicier'] != null &&
                        (_data!['reponse_epicier'] as String).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildCard(
                        title: 'Votre réponse',
                        child: Text(
                          _data!['reponse_epicier'].toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: GrocerTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_isClosedStatus(_data!['statut']?.toString()))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GrocerTheme.border),
                        ),
                        child: const Text(
                          'Réclamation résolue. La réponse n\'est plus modifiable.',
                          style: TextStyle(color: GrocerTheme.textDark),
                        ),
                      )
                    else ...[
                      const Text(
                        'Répondre au client',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: GrocerTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reponseController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Saisissez votre réponse...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveReponse,
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
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer la réponse',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrocerTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: GrocerTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}
