import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedFilter = 'Tous';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildFilterChips(),
                    const SizedBox(height: 20),
                    _buildDisputeCards(),
                    const SizedBox(height: 30),
                    _buildRecentOrdersHeader(),
                    const SizedBox(height: 12),
                    _buildRecentOrdersTable(),
                    const SizedBox(height: 40),
                  ],
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
                  const Icon(Icons.search, color: Colors.white, size: 28),
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
        _buildStatCard('328', 'Total/jour', const Color(0xFF2D5016)),
        _buildStatCard('42', 'En cours', const Color(0xFFF2A93B)),
        _buildStatCard('7', 'Litiges', const Color(0xFFF26444)),
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
      {'label': 'Litiges (7)', 'icon': Icons.warning_amber_rounded},
      {'label': 'En cours', 'icon': null},
      {'label': 'Livrées', 'icon': null},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['label'];
          final isLitige = filter['label'].toString().contains('Litiges');
          
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
              selectedColor: isLitige ? const Color(0xFF2D5016) : const Color(0xFF2D5016),
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

  Widget _buildDisputeCards() {
    return Column(
      children: [
        _buildDisputeCard(
          id: '#CMD-4821',
          title: 'Commande non reçue',
          client: 'Karim B.',
          shop: 'Al Baraka',
          amount: '120 DH',
          time: 'Signalé il y a 2h',
          status: 'Litige ouvert',
          statusColor: const Color(0xFFF2A93B),
          showThreeButtons: true,
        ),
        const SizedBox(height: 16),
        _buildDisputeCard(
          id: '#CMD-4799',
          title: 'Produit manquant',
          client: 'Salma M.',
          shop: 'Au Coin Frais',
          amount: '85 DH',
          time: 'Signalé il y a 5h',
          status: 'En médiation',
          statusColor: const Color(0xFFF2A93B),
          showThreeButtons: false,
        ),
      ],
    );
  }

  Widget _buildDisputeCard({
    required String id,
    required String title,
    required String client,
    required String shop,
    required String amount,
    required String time,
    required String status,
    required Color statusColor,
    required bool showThreeButtons,
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
              Text(
                '$client → ',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Icon(Icons.store, size: 16, color: Color(0xFFF26444)),
              const SizedBox(width: 4),
              Text(
                '$shop • $amount',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
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
          const SizedBox(height: 16),
          if (showThreeButtons)
            Row(
              children: [
                _buildActionBtn('Résoudre', const Color(0xFF2D5016), Icons.check),
                const SizedBox(width: 8),
                _buildActionBtn('Médiation', const Color(0xFFF5EDDA), Icons.chat_bubble_outline, textColor: const Color(0xFF2D5016)),
                const SizedBox(width: 8),
                _buildActionBtn('Rembourser', const Color(0xFFFFEBEE), Icons.history, textColor: Colors.red),
              ],
            )
          else
            Row(
              children: [
                _buildActionBtn('Résoudre', const Color(0xFF2D5016), Icons.check, flex: 1),
                const SizedBox(width: 8),
                _buildActionBtn('Détails', const Color(0xFFF5EDDA), Icons.remove_red_eye_outlined, textColor: const Color(0xFF2D5016), flex: 1),
                const Spacer(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, Color bg, IconData icon, {Color? textColor, int flex = 1}) {
    return Expanded(
      flex: flex,
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
            fontFamily: 'Georgia',
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
                Icon(Icons.inventory_2, color: Color(0xFFF2A93B), size: 18),
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
                _buildTableRow('#4830', 'Youssef K.', '67 DH', 'Livré', const Color(0xFF4CBB5E)),
                _buildTableRow('#4829', 'Fatima Z.', '134 DH', 'En cours', const Color(0xFFF2A93B)),
                _buildTableRow('#4828', 'Omar H.', '45 DH', 'Livré', const Color(0xFF4CBB5E)),
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
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Épiciers'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Commandes'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Réglages'),
      ],
    );
  }
}
