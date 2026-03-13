import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/api_service.dart';
import '../auth/login_screen.dart';
import 'admin_categories_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final ApiService _apiService = ApiService();
  String _selectedFilter = 'Tous';
  bool _isLoading = true;
  
  Map<String, dynamic> _stats = {'totalToday': 0, 'ongoing': 0, 'disputes': 0};
  List<dynamic> _disputes = [];
  List<dynamic> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      
      final statsData = await _apiService.get('/admin/orders/stats', token: token);
      final disputesData = await _apiService.get('/admin/disputes', token: token);
      final recentData = await _apiService.get('/admin/orders/recent', token: token);

      setState(() {
        _stats = statsData;
        _disputes = disputesData;
        _recentOrders = recentData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateDisputeStatus(int id, String newStatus) async {
    try {
      final token = context.read<AuthProvider>().token;
      await _apiService.patch('/admin/disputes/$id/status', {'statut': newStatus}, token: token);
      _fetchData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour : $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)))
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
                          const SizedBox(height: 30),
                          _buildRecentOrdersHeader(),
                          const SizedBox(height: 12),
                          _buildRecentOrdersTable(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF2D5016),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Retour',
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MyHanut',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Commandes & Litiges',
                        style: TextStyle(
                          color: Color(0xFFB5D39D),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF26444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                    tooltip: 'Déconnexion',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(_stats['totalToday'].toString(), 'Total/jour', const Color(0xFF2D5016)),
        _buildStatCard(_stats['ongoing'].toString(), 'En cours', const Color(0xFFF2A93B)),
        _buildStatCard(_stats['disputes'].toString(), 'Litiges', const Color(0xFFF26444)),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
      {'label': 'Litige ouvert', 'icon': Icons.warning_amber_rounded},
      {'label': 'En médiation', 'icon': Icons.chat_bubble_outline},
      {'label': 'Remboursé', 'icon': Icons.history},
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
              label: Row(
                children: [
                  if (filter['icon'] != null) ...[
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFFF2A93B),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(filter['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = filter['label'] as String),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2D5016),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                ),
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
        final normalizedStatus = d['statut']?.toString().toLowerCase().trim() ?? '';
        
        switch (_selectedFilter) {
          case 'Litige ouvert':
            return ['litige ouvert', 'non resolut', 'nonresolue'].contains(normalizedStatus);
          case 'En médiation':
            return ['en médiation', 'en mediation', 'en attente'].contains(normalizedStatus);
          case 'Remboursé':
            return ['remboursé', 'rembourse', 'rembourser'].contains(normalizedStatus);
          case 'Résolu':
            return ['résolu', 'résolue', 'resolu', 'resolut'].contains(normalizedStatus);
          default:
            return true;
        }
      }).toList();
    }

    if (filteredDisputes.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Aucun litige à afficher'),
      ));
    }

    return Column(
      children: filteredDisputes.map((d) {
        final id = d['id'];
        final description = d['description'];
        final clientName = '${d['client']?['prenom'] ?? ''} ${d['client']?['nom'] ?? ''}'.trim();
        final shopName = d['commande']?['epicier']?['nom_boutique'] ?? 'Inconnu';
        final amount = '${d['commande']?['montant_total'] ?? '0'} DH';
        final createdAt = d['date_creation'] != null ? DateTime.parse(d['date_creation']) : DateTime.now();
        final timeStr = 'Signalé le ${DateFormat('dd/MM HH:mm').format(createdAt)}';
        
        String statusLabel = 'Inconnu';
        Color statusColor = Colors.grey;
        
        // Normalisation du statut pour la comparaison
        final normalizedStatus = d['statut']?.toString().toLowerCase().trim() ?? '';
        
        switch (normalizedStatus) {
          case 'litige ouvert':
          case 'non resolut':
          case 'nonresolue':
            statusLabel = 'Litige ouvert';
            statusColor = const Color(0xFFF26444);
            break;
          case 'en médiation':
          case 'en mediation':
          case 'en attente':
            statusLabel = 'En médiation';
            statusColor = const Color(0xFFF2A93B);
            break;
          case 'remboursé':
          case 'rembourse':
          case 'rembourser':
            statusLabel = 'Remboursé';
            statusColor = Colors.pink;
            break;
          case 'résolu':
          case 'résolue':
          case 'resolu':
          case 'resolut':
            statusLabel = 'Résolu';
            statusColor = const Color(0xFF2D5016);
            break;
          default:
            statusLabel = 'Inconnu ($normalizedStatus)';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildDisputeCard(
            idNum: id,
            id: '#CMD-${d['commande_id'] ?? '??'}',
            title: description,
            client: clientName,
            shop: shopName,
            amount: amount,
            time: timeStr,
            status: statusLabel,
            statusColor: statusColor,
            showActions: normalizedStatus != 'resolut' && 
                         normalizedStatus != 'résolue' && 
                         normalizedStatus != 'résolu' && 
                         normalizedStatus != 'résolu' && 
                         normalizedStatus != 'resolu' && 
                         normalizedStatus != 'rembourser' && 
                         normalizedStatus != 'remboursé' && 
                         normalizedStatus != 'rembourse',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisputeCard({
    required int idNum,
    required String id,
    required String title,
    required String client,
    required String shop,
    required String amount,
    required String time,
    required String status,
    required Color statusColor,
    required bool showActions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
            left: BorderSide(color: statusColor, width: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
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
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Color(0xFF2D5016)),
              const SizedBox(width: 4),
              Flexible(child: Text('$client → ', style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.store, size: 16, color: Color(0xFFF26444)),
              const SizedBox(width: 4),
              Flexible(child: Text('$shop • $amount', style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionBtn('Résoudre', const Color(0xFF2D5016), Icons.check, onTap: () => _updateDisputeStatus(idNum, 'Résolu')),
                const SizedBox(width: 8),
                _buildActionBtn('Médiation', const Color(0xFFF5EDDA), Icons.chat_bubble_outline, textColor: const Color(0xFF2D5016), onTap: () => _updateDisputeStatus(idNum, 'En médiation')),
                const SizedBox(width: 8),
                _buildActionBtn('Rembourser', const Color(0xFFFFEBEE), Icons.history, textColor: Colors.red, onTap: () => _updateDisputeStatus(idNum, 'Remboursé')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, Color bg, IconData icon, {Color? textColor, VoidCallback? onTap}) {
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
              Icon(icon, size: 16, color: textColor ?? Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Commandes récentes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
        Row(
          children: [
             Text(
              'Tout voir',
              style: TextStyle(color: Color(0xFFF26444), fontWeight: FontWeight.bold),
            ),
            Icon(Icons.arrow_forward, color: Color(0xFFF26444), size: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentOrdersTable() {
    if (_recentOrders.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Aucune commande récente'),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF2D5016),
            child: const Row(
              children: [
                Icon(Icons.flash_on, color: Color(0xFFF2A93B), size: 18),
                SizedBox(width: 8),
                Text(
                  'Temps réel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.8),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(padding: EdgeInsets.only(bottom: 12), child: Text('ID', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.only(bottom: 12), child: Text('CLIENT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.only(bottom: 12), child: Text('MONTANT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.only(bottom: 12), child: Text('STATUT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
                ..._recentOrders.map((o) {
                  Color statusColor = Colors.grey;
                  String statusLabel = o['statut'] ?? 'Inconnu';
                  
                  if (statusLabel == 'livrée') {
                    statusColor = const Color(0xFF4CBB5E);
                  } else if (statusLabel == 'prête') {
                    statusColor = const Color(0xFFF2A93B);
                  } else if (statusLabel == 'reçue') {
                    statusColor = Colors.blue;
                  }

                  return _buildTableRow(
                    '#${o['id']}',
                    '${o['client']?['prenom'] ?? ''} ${o['client']?['nom'] ?? ''}'.trim(),
                    '${o['montant_total'] ?? '0'} DH',
                    statusLabel,
                    statusColor,
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String id, String name, String amount, String status, Color color) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(id, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(name, style: const TextStyle(fontSize: 13))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2,
      selectedItemColor: const Color(0xFF2D5016),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 1) {
          Navigator.pop(context);
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Épiciers'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Commandes'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Catégories'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Réglages'),
      ],
    );
  }
}
