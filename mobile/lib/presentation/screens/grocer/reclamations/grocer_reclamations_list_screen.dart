import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/reclamation.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';
import 'grocer_reclamation_detail_screen.dart';

class GrocerReclamationsListScreen extends StatefulWidget {
  const GrocerReclamationsListScreen({super.key});

  @override
  State<GrocerReclamationsListScreen> createState() =>
      _GrocerReclamationsListScreenState();
}

class _GrocerReclamationsListScreenState
    extends State<GrocerReclamationsListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Reclamation> _reclamations = [];
  List<Map<String, dynamic>> _reclamationsWithMeta = [];
  String _selectedStatus = 'Tous';
  List<String> _statusOptions = const ['Tous'];

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
      final res = await _api.get('/reclamations/store', token: token);
      if (!mounted) return;
      final List<dynamic> rawList = res is List
          ? res
          : (res as Map?)?['items'] as List? ?? [];
      final List<Reclamation> list = [];
      final List<Map<String, dynamic>> withMeta = [];
      for (final r in rawList) {
        final map = r is Map<String, dynamic>
            ? r
            : Map<String, dynamic>.from(r as Map);
        list.add(Reclamation.fromJson(map));
        withMeta.add(map);
      }
      setState(() {
        _reclamations = list;
        _reclamationsWithMeta = withMeta;
        _statusOptions = _buildStatusOptions(list);
        if (!_statusOptions.contains(_selectedStatus)) {
          _selectedStatus = 'Tous';
        }
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

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'Résolu':
      case 'Résolue':
      case 'Remboursé':
        return Colors.green.shade700;
      case 'En cours':
      case 'En médiation':
        return Colors.blue.shade700;
      case 'Ouverte':
      case 'Litige ouvert':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  List<String> _buildStatusOptions(List<Reclamation> items) {
    final seen = <String>{};
    final options = <String>['Tous'];
    for (final rec in items) {
      final statut = rec.statut.trim();
      if (statut.isNotEmpty && !seen.contains(statut)) {
        seen.add(statut);
        options.add(statut);
      }
    }
    return options;
  }

  String _getClientName(Map<String, dynamic>? client) {
    if (client == null) return '';
    final p = client['prenom']?.toString() ?? '';
    final n = client['nom']?.toString() ?? '';
    return '$p $n'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final filteredIndexes = <int>[];
    for (var i = 0; i < _reclamations.length; i += 1) {
      final rec = _reclamations[i];
      if (_selectedStatus == 'Tous' || rec.statut == _selectedStatus) {
        filteredIndexes.add(i);
      }
    }

    return Scaffold(
      backgroundColor: GrocerTheme.background,
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
          : _reclamations.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune réclamation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: GrocerTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les réclamations de vos clients apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: GrocerTheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_statusOptions.length > 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusOptions.map((status) {
                          final selected = status == _selectedStatus;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedStatus = status),
                              selectedColor: GrocerTheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              labelStyle: TextStyle(
                                color: selected
                                    ? GrocerTheme.primary
                                    : GrocerTheme.textDark,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? GrocerTheme.primary
                                    : GrocerTheme.border,
                              ),
                              backgroundColor: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (_statusOptions.length > 1) const SizedBox(height: 12),
                  if (filteredIndexes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt_off,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune réclamation pour ce statut',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredIndexes.map((index) {
                      final rec = _reclamations[index];
                      final meta = index < _reclamationsWithMeta.length
                          ? _reclamationsWithMeta[index]
                          : null;
                      final clientName = meta != null && meta['client'] != null
                          ? _getClientName(
                              meta['client'] is Map
                                  ? meta['client'] as Map<String, dynamic>
                                  : null,
                            )
                          : '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GrocerReclamationDetailScreen(
                                  reclamationId: rec.id,
                                ),
                              ),
                            ).then((_) => _load());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rec.motif,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: GrocerTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          rec.statut,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        rec.statut,
                                        style: TextStyle(
                                          color: _getStatusColor(rec.statut),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (rec.commandeId != null) ...[
                                      Icon(
                                        Icons.receipt_long,
                                        size: 16,
                                        color: GrocerTheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Commande #${rec.commandeId}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: GrocerTheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(rec.dateCreation.toLocal()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (clientName.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        clientName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  rec.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
