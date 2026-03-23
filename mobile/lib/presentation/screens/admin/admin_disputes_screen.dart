import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../screens/auth/welcome_screen.dart';
import 'admin_validation_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_categories_screen.dart';
import '../../widgets/admin/admin_bottom_nav.dart';
import '../../widgets/admin/admin_header.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  final ApiService _apiService = ApiService();
  String _selectedFilter = 'Tous';
  bool _isLoading = true;

  Map<String, dynamic> _stats = {
    'totalDisputes': 0,
    'ongoing': 0,
    'resolved': 0,
  };
  List<dynamic> _disputes = [];
  int _currentPage = 0;
  static const int _disputesPerPage = 3;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;

      // Fetch only disputes and specific stats for disputes
      final disputesData = await _apiService.get(
        '/admin/disputes',
        token: token,
      );

      // Calculate stats locally from disputes list
      int ongoing = disputesData
          .where(
            (d) => [
              'litige ouvert',
              'en médiation',
              'non resolut',
              'en attente',
            ].contains(d['statut']?.toString().toLowerCase()),
          )
          .length;
      int resolved = disputesData
          .where(
            (d) => [
              'résolu',
              'resolu',
              'remboursé',
              'rembourse',
            ].contains(d['statut']?.toString().toLowerCase()),
          )
          .length;

      setState(() {
        _disputes = disputesData;
        _stats = {
          'totalDisputes': disputesData.length,
          'ongoing': ongoing,
          'resolved': resolved,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _updateDisputeStatus(int id, String newStatus) async {
    try {
      final token = context.read<AuthProvider>().token;
      await _apiService.patch('/admin/disputes/$id/status', {
        'statut': newStatus,
      }, token: token);
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour : $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D5016),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      color: const Color(0xFF2D5016),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsRow(),
                            const SizedBox(height: 20),
                            _buildFilterChips(),
                            const SizedBox(height: 20),
                            _buildDisputeCardsSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 4),
    );
  }

  Widget _buildHeader() {
    return const AdminHeader(
      title: 'Litiges',
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(
          _stats['totalDisputes'].toString(),
          'Total',
          const Color(0xFF2D1A0E),
        ),
        _buildStatCard(
          _stats['ongoing'].toString(),
          'En cours',
          const Color(0xFFF2A93B),
        ),
        _buildStatCard(
          _stats['resolved'].toString(),
          'Résolus',
          const Color(0xFF2D5016),
        ),
      ],
    );
  }

  Widget _buildStatCard(String count, String label, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 3,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Tous', 'icon': null},
      {'label': 'En attente', 'icon': Icons.hourglass_empty_rounded},
      {'label': 'Litige ouvert', 'icon': Icons.warning_amber_rounded},
      {'label': 'En médiation', 'icon': Icons.chat_bubble_outline},
      {'label': 'Résolu', 'icon': Icons.check_circle_outline},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (val) =>
                  setState(() {
                _selectedFilter = filter['label'] as String;
                _currentPage = 0;
              }),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFFFCC33),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2D1A0E) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDisputeCardsSection() {
    List<dynamic> filteredDisputes = _disputes;
    if (_selectedFilter != 'Tous') {
      filteredDisputes = _disputes.where((d) {
        final normalizedStatus =
            d['statut']?.toString().toLowerCase().trim() ?? '';
        switch (_selectedFilter) {
          case 'En attente':
            return ['en attente'].contains(normalizedStatus);
          case 'Litige ouvert':
            return [
              'litige ouvert',
              'non resolut',
              'nonresolue',
            ].contains(normalizedStatus);
          case 'En médiation':
            return ['en médiation', 'en mediation'].contains(normalizedStatus);
          case 'Résolu':
            return [
              'résolu',
              'résolue',
              'resolu',
              'resolut',
              'remboursé',
              'rembourse',
            ].contains(normalizedStatus);
          default:
            return true;
        }
      }).toList();
    }

    if (filteredDisputes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('Aucun litige trouvé'),
        ),
      );
    }

    final int totalPages = (filteredDisputes.length / _disputesPerPage).ceil();
    final int start = _currentPage * _disputesPerPage;
    final int end = (start + _disputesPerPage < filteredDisputes.length)
        ? start + _disputesPerPage
        : filteredDisputes.length;
    final List<dynamic> paginatedDisputes = filteredDisputes.sublist(start, end);

    return Column(
      children: [
        ...paginatedDisputes.map((d) => _buildDisputeCard(d)).toList(),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 18, color: _currentPage > 0 ? const Color(0xFF2D1A0E) : Colors.grey),
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                ),
                Text(
                  'Page ${_currentPage + 1} sur $totalPages',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 18, color: _currentPage < totalPages - 1 ? const Color(0xFF2D1A0E) : Colors.grey),
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDisputeCard(dynamic d) {
    final idNum = d['id'];
    final type = (d['type']?.toString().toUpperCase() ?? 'COMMANDE').trim();
    final isAvis = type == 'AVIS';
    final description = (d['description'] ?? '').toString();
    final clientFromReclamation =
        '${d['client']?['prenom'] ?? ''} ${d['client']?['nom'] ?? ''}'.trim();
    final clientFromAvis =
        '${d['avis']?['client']?['prenom'] ?? ''} ${d['avis']?['client']?['nom'] ?? ''}'.trim();
    final clientName = isAvis
        ? (clientFromAvis.isNotEmpty ? clientFromAvis : clientFromReclamation)
        : clientFromReclamation;
    final shopName = isAvis
        ? (d['avis']?['Store']?['nom_boutique'] ??
            d['avis']?['store']?['nom_boutique'] ??
            'Inconnu')
        : (d['commande']?['epicier']?['nom_boutique'] ?? 'Inconnu');
    final amount = isAvis
        ? ''
        : '${d['commande']?['montant_total'] ?? '0'} DH';
    final avisNote = d['avis']?['note'];
    final avisCommentaire = (d['avis']?['commentaire'] ?? '').toString();
    final motif = (d['motif'] ?? '').toString();
    final createdAt = d['date_creation'] != null
        ? DateTime.parse(d['date_creation'])
        : DateTime.now();
    final timeStr = 'Signalé le ${DateFormat('dd/MM HH:mm').format(createdAt)}';

    String statusLabel = 'Inconnu';
    Color statusColor = Colors.grey;
    final normalizedStatus = d['statut']?.toString().toLowerCase().trim() ?? '';

    switch (normalizedStatus) {
      case 'en attente':
        statusLabel = 'En attente';
        statusColor = const Color(0xFFF2A93B);
        break;
      case 'litige ouvert':
      case 'non resolut':
      case 'nonresolue':
        statusLabel = 'Ouvert';
        statusColor = const Color(0xFFF26444);
        break;
      case 'en médiation':
      case 'en mediation':
        statusLabel = 'Médiation';
        statusColor = const Color(0xFFF2A93B);
        break;
      case 'résolu':
      case 'résolue':
      case 'resolu':
      case 'resolut':
      case 'remboursé':
      case 'rembourse':
        statusLabel = 'Résolu';
        statusColor = const Color(0xFF2D5016);
        break;
    }

    bool showActions = ![
      'résolu',
      'resolu',
      'remboursé',
      'rembourse',
    ].contains(normalizedStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: statusColor, width: 6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAvis ? 'Signalement avis' : description,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          if (isAvis) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE8B923)),
                const SizedBox(width: 4),
                Text(
                  'Note: ${avisNote ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Motif: ${motif.isNotEmpty ? motif : '-'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Description: ${description.isNotEmpty ? description : '-'}',
              style: const TextStyle(fontSize: 13),
            ),
            if (avisCommentaire.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Avis client: $avisCommentaire',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: Color(0xFF2D5016),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  clientName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              const Icon(
                Icons.storefront_outlined,
                size: 16,
                color: Color(0xFFF26444),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  shopName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isAvis)
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                )
              else
                Text(
                  'Type: AVIS',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                timeStr,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionBtn(
                  'Résoudre',
                  const Color(0xFF2D5016),
                  Icons.check,
                  onTap: () => _updateDisputeStatus(idNum, 'Résolu'),
                ),
                const SizedBox(width: 8),
                _buildActionBtn(
                  'Médiation',
                  const Color(0xFFF5EDDA),
                  Icons.chat_bubble_outline,
                  textColor: const Color(0xFF2D5016),
                  onTap: () => _updateDisputeStatus(idNum, 'En médiation'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    Color bg,
    IconData icon, {
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: textColor ?? Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
