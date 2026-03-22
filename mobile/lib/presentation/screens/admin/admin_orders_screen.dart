import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/admin/admin_bottom_nav.dart';
import '../../../screens/auth/welcome_screen.dart';
import 'admin_validation_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_categories_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  Map<String, dynamic> _stats = {'totalToday': 0, 'ongoing': 0};
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
      final recentData = await _apiService.get('/admin/orders/recent', token: token);

      setState(() {
        _stats = statsData;
        _recentOrders = recentData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5016),
        elevation: 0,
        title: const Text('Gestion Commandes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)))
          : _buildBody(),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF2D5016),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(),
            const SizedBox(height: 30),
            _buildRecentOrdersHeader(),
            const SizedBox(height: 12),
            _buildRecentOrdersTable(),
            const SizedBox(height: 40),
          ],
        ),
      ),
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
                        'Suivi des Commandes',
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
                        MaterialPageRoute(builder: (_) => WelcomeScreen()),
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
      ],
    );
  }

  Widget _buildStatCard(String count, String label, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2, // 2 cards now
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
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.8),
              },
              children: [
                const TableRow(
                  children: [
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

  TableRow _buildTableRow(String name, String amount, String status, Color color) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
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

}
