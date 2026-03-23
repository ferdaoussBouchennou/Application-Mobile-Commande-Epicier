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
import '../../widgets/admin/admin_header.dart';

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
  int _currentPage = 0;
  static const int _ordersPerPage = 7;

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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)))
                  : _buildBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return const AdminHeader(
      title: 'Commandes',
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
    return const SizedBox.shrink();
  }
  Widget _buildRecentOrdersTable() {
    if (_recentOrders.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Aucune commande récente'),
      ));
    }

    final int totalPages = (_recentOrders.length / _ordersPerPage).ceil();
    final int start = _currentPage * _ordersPerPage;
    final int end = (start + _ordersPerPage < _recentOrders.length) 
        ? start + _ordersPerPage 
        : _recentOrders.length;
    final List<dynamic> paginatedOrders = _recentOrders.sublist(start, end);

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
                0: FlexColumnWidth(2.0),
                1: FlexColumnWidth(1.8),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(padding: EdgeInsets.only(bottom: 12), child: Text('CLIENT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.only(bottom: 12), child: Text('BOUTIQUE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.only(bottom: 12), child: Text('MONTANT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.only(bottom: 12), child: Text('STATUT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
                ...paginatedOrders.map((o) {
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
                    (o['epicier'] ?? o['store'])?['nom_boutique'] ?? 'N/A',
                    '${o['montant_total'] ?? '0'} DH',
                    statusLabel,
                    statusColor,
                  );
                }).toList(),
              ],
            ),
          ),
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 16, color: _currentPage > 0 ? const Color(0xFF2D5016) : Colors.grey),
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  ),
                  Text(
                    'Page ${_currentPage + 1} sur $totalPages',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 16, color: _currentPage < totalPages - 1 ? const Color(0xFF2D5016) : Colors.grey),
                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String name, String store, String amount, String status, Color color) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(store, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade700))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

}
