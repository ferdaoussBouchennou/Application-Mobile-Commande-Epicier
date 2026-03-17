import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/grocer_order.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';

/// Écran Mes Commandes — onglets Reçue (défaut), Prête, Livrée ou Récupérée.
class GrocerOrdersScreen extends StatefulWidget {
  const GrocerOrdersScreen({super.key});

  @override
  State<GrocerOrdersScreen> createState() => _GrocerOrdersScreenState();
}

class _GrocerOrdersScreenState extends State<GrocerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  static const List<String> _tabLabels = [
    'Reçue',
    'Prête',
    'Livrée ou Récupérée',
  ];
  static const List<String> _statuts = ['reçue', 'prête', 'livrée'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, initialIndex: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<GrocerOrder>> _fetchOrders(String? token, String statut) async {
    if (token == null) return [];
    final list = await _api.get(
      '/epicier/commandes?statut=$statut',
      token: token,
    ) as List<dynamic>?;
    return list
        ?.map((e) => GrocerOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList() ?? [];
  }

  Future<void> _updateStatut(String? token, int orderId, String statut) async {
    if (token == null) return;
    await _api.patch(
      '/epicier/commandes/$orderId/statut',
      {'statut': statut},
      token: token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;
    return Scaffold(
      backgroundColor: GrocerTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6914),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Mes Commandes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuts.map((statut) => _OrdersList(
          token: token,
          statut: statut,
          fetchOrders: () => _fetchOrders(token, statut),
          updateStatut: (id, newStatut) => _updateStatut(token, id, newStatut),
        )).toList(),
      ),
    );
  }
}

class _OrdersList extends StatefulWidget {
  final String? token;
  final String statut;
  final Future<List<GrocerOrder>> Function() fetchOrders;
  final Future<void> Function(int orderId, String newStatut) updateStatut;

  const _OrdersList({
    required this.token,
    required this.statut,
    required this.fetchOrders,
    required this.updateStatut,
  });

  @override
  State<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<_OrdersList> {
  List<GrocerOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.fetchOrders();
      if (mounted) {
        setState(() {
          _orders = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null) {
      return const Center(
        child: Text('Connectez-vous pour voir vos commandes.'),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: GrocerTheme.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: GrocerTheme.trendNegative)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: GrocerTheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Aucune commande',
              style: TextStyle(fontSize: 16, color: GrocerTheme.textMuted),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: GrocerTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _OrderCard(
          order: _orders[index],
          onStatutUpdated: _load,
          updateStatut: widget.updateStatut,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final GrocerOrder order;
  final VoidCallback onStatutUpdated;
  final Future<void> Function(int orderId, String newStatut) updateStatut;

  const _OrderCard({
    required this.order,
    required this.onStatutUpdated,
    required this.updateStatut,
  });

  static String _formatPrice(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final isRecue = order.statut == 'reçue';
    final isPrete = order.statut == 'prête';
    final isLivree = order.statut == 'livrée';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black12,
      color: const Color(0xFFF8F4EE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#CMD-${order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: GrocerTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: GrocerTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Client : ${order.clientDisplay}',
                            style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.articleCount} article${order.articleCount > 1 ? 's' : ''} · ${_formatPrice(order.montantTotal)} MAD · Créneau ${order.creneau}',
                        style: TextStyle(fontSize: 13, color: GrocerTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                _StatusChip(statut: order.statut),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isRecue)
                  _ActionButton(
                    label: 'Préparer',
                    icon: Icons.restaurant,
                    primary: true,
                    onPressed: () async {
                      try {
                        await updateStatut(order.id, 'prête');
                        onStatutUpdated();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Commande marquée prête')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      }
                    },
                  ),
                if (isPrete) ...[
                  _ActionButton(
                    label: 'Marquer Livrée/Récupérée',
                    icon: Icons.check_circle_outline,
                    primary: true,
                    onPressed: () async {
                      try {
                        await updateStatut(order.id, 'livrée');
                        onStatutUpdated();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Commande marquée livrée')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      }
                    },
                  ),
                  _ActionButton(
                    label: 'Détails',
                    icon: Icons.info_outline,
                    primary: false,
                    onPressed: () {
                      _showDetails(context, order);
                    },
                  ),
                ],
                if (isLivree)
                  _ActionButton(
                    label: 'Voir détails',
                    icon: Icons.visibility_outlined,
                    primary: false,
                    onPressed: () => _showDetails(context, order),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, GrocerOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: GrocerTheme.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#CMD-${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Client : ${order.clientPrenom} ${order.clientNom}'),
            Text('${order.articleCount} articles · ${_formatPrice(order.montantTotal)} MAD'),
            Text('Créneau : ${order.creneau}'),
            Text('Statut : ${order.statut}'),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String statut;

  const _StatusChip({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (statut) {
      case 'reçue':
        bg = const Color(0xFFFFE4D4);
        fg = const Color(0xFFB85C38);
        break;
      case 'prête':
        bg = const Color(0xFFD4EDDA);
        fg = const Color(0xFF1A7F6E);
        break;
      case 'livrée':
        bg = const Color(0xFFE8F4E8);
        fg = GrocerTheme.primary;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut == 'livrée' ? 'Livrée' : statut == 'prête' ? 'Prête' : 'Reçue',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? GrocerTheme.primary : const Color(0xFFF0EDE8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: primary ? Colors.white : GrocerTheme.textDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : GrocerTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
