import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';
import 'widgets/avis_signal_sheet.dart';

class GrocerAvisDetailsScreen extends StatefulWidget {
  final int avisId;
  const GrocerAvisDetailsScreen({super.key, required this.avisId});

  @override
  State<GrocerAvisDetailsScreen> createState() =>
      _GrocerAvisDetailsScreenState();
}

class _GrocerAvisDetailsScreenState extends State<GrocerAvisDetailsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Non connecté';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/epicier/avis/${widget.avisId}', token: token);
      if (!mounted) return;
      setState(() {
        _data = res is Map<String, dynamic> ? res : <String, dynamic>{};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _signal() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AvisSignalSheet(avisId: widget.avisId),
    );
    if (ok == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signalement envoyé')),
        );
      }
    }
  }

  Widget _buildStars(int note) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < note ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFE8B923),
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      backgroundColor: GrocerTheme.background,
      appBar: AppBar(
        backgroundColor: GrocerTheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Détails avis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: GrocerTheme.primary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
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
              : data == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: GrocerTheme.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (data['avis'] != null)
                            _buildAvisCard(
                              (data['avis'] as Map).cast<String, dynamic>(),
                            ),
                          const SizedBox(height: 16),
                          if (data['client'] != null &&
                              (data['client'] as Map).isNotEmpty)
                            _buildClientCard(
                              (data['client'] as Map).cast<String, dynamic>(),
                            ),
                          Text(
                            'Commandes liées au client',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: GrocerTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCommandesSection(
                            (data['commandes'] as List?) ?? const [],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _signal,
                              icon: const Icon(Icons.flag_rounded),
                              label: const Text('Signaler cet avis'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GrocerTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avis) {
    final note = (avis['note'] as num?)?.toInt() ?? 0;
    final commentaire = avis['commentaire']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrocerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avis #${avis['id']}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildStars(note),
          const SizedBox(height: 8),
          Text(
            commentaire.isNotEmpty ? commentaire : '(commentaire vide)',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (avis['date_avis'] != null)
            Text(
              'Date: ${avis['date_avis']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final prenom = client['prenom']?.toString() ?? '';
    final nom = client['nom']?.toString() ?? '';
    final fullName = '$prenom $nom'.trim();
    final hasTelephone = client['telephone'] != null;
    final hasEmail = client['email'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: GrocerTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GrocerTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName.isEmpty ? 'Client' : fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              if (hasTelephone)
                Text(
                  'Téléphone: ${client['telephone']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
              if (hasEmail)
                Text(
                  'Email: ${client['email']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCommandesSection(List<dynamic> commandes) {
    if (commandes.isEmpty) {
      return Text(
        'Aucune commande trouvée.',
        style: TextStyle(color: Colors.grey.shade700),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          GrocerTheme.primary.withValues(alpha: 0.08),
        ),
        columnSpacing: 18,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          color: GrocerTheme.textDark,
        ),
        dataTextStyle: TextStyle(color: GrocerTheme.textDark),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Total')),
        ],
        rows: commandes.map((c) {
          final map = (c as Map).cast<String, dynamic>();
          final id = map['id'];
          final statut = map['statut']?.toString() ?? '';
          final dateRaw = map['date_commande']?.toString() ?? '';
          final total = map['montant_total']?.toString() ?? '';

          final date = (() {
            final dt = DateTime.tryParse(dateRaw);
            if (dt == null) return dateRaw;
            final dd = dt.day.toString().padLeft(2, '0');
            final mm = dt.month.toString().padLeft(2, '0');
            final yyyy = dt.year.toString();
            final hh = dt.hour.toString().padLeft(2, '0');
            final min = dt.minute.toString().padLeft(2, '0');
            return '$dd/$mm/$yyyy $hh:$min';
          })();

          return DataRow(
            cells: [
              DataCell(Text(id?.toString() ?? '-')),
              DataCell(Text(statut)),
              DataCell(Text(date)),
              DataCell(Text('$total MAD')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

