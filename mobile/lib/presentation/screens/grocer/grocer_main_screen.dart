import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/auth/welcome_screen.dart';
import 'grocer_theme.dart';
import 'dashboard/grocer_dashboard_screen.dart';
import 'catalogue/grocer_catalogue_screen.dart';
import 'orders/grocer_orders_screen.dart';
import 'notifications/grocer_notifications_screen.dart';
import 'reclamations/grocer_reclamations_list_screen.dart';

/// Écran principal de l'espace Épicier — même design que MapScreen (parcourir sans compte).
class GrocerMainScreen extends StatefulWidget {
  const GrocerMainScreen({super.key});

  @override
  State<GrocerMainScreen> createState() => _GrocerMainScreenState();
}

class _GrocerMainScreenState extends State<GrocerMainScreen> {
  int _currentIndex = 0;
  int _newOrdersCount = 0;
  int _unreadNotificationsCount = 0;
  int? _orderIdToOpen;
  VoidCallback? _catalogueRefresh;
  VoidCallback? _notificationsRefresh;
  VoidCallback? _ordersRefresh;
  final GlobalKey<NavigatorState> _catalogueNavKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  List<Widget> _buildScreens() {
    return [
      const GrocerDashboardScreen(),
      Builder(
        builder: (context) => Navigator(
          key: _catalogueNavKey,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => GrocerCatalogueScreen(
              onRegisterRefresh: (fn) => _catalogueRefresh = fn,
            ),
          ),
        ),
      ),
      GrocerOrdersScreen(
        onNewOrdersCount: (count) => setState(() => _newOrdersCount = count),
        orderIdToOpen: _orderIdToOpen,
        onOpenOrderHandled: () => setState(() => _orderIdToOpen = null),
        onRegisterRefresh: (fn) => _ordersRefresh = fn,
      ),
      const GrocerReclamationsListScreen(),
      GrocerNotificationsScreen(
        onNavigateToOrders: () => setState(() => _currentIndex = 2),
        onNavigateToOrder: (orderId) {
          setState(() {
            _currentIndex = 2;
            _orderIdToOpen = orderId;
          });
        },
        onUnreadCount: (count) =>
            setState(() => _unreadNotificationsCount = count),
        onRegisterRefresh: (fn) => _notificationsRefresh = fn,
      ),
    ];
  }

  Future<void> _fetchUnreadCount() async {
    // Appelé après build pour avoir context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || !mounted) return;
      try {
        final data = await ApiService().get(
          '/epicier/notifications/unread-count',
          token: token,
        );
        final count = (data as Map<String, dynamic>?)?['count'] as int? ?? 0;
        if (mounted) setState(() => _unreadNotificationsCount = count);
      } catch (_) {}
    });
  }

  List<_NavItem> get _navItems => [
    const _NavItem(Icons.home_outlined, Icons.home, 'Accueil', null),
    const _NavItem(
      Icons.inventory_2_outlined,
      Icons.inventory_2,
      'Catalogue',
      null,
    ),
    _NavItem(
      Icons.receipt_long_outlined,
      Icons.receipt_long,
      'Commandes',
      _newOrdersCount,
    ),
    const _NavItem(
      Icons.report_problem_outlined,
      Icons.report_problem,
      'Réclamations',
      null,
    ),
    _NavItem(
      Icons.notifications_outlined,
      Icons.notifications,
      'Notifications',
      _unreadNotificationsCount > 0 ? _unreadNotificationsCount : null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrocerTheme.background,
      appBar: AppBar(
        backgroundColor: GrocerTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MyHanut',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: TextButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _buildScreens()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            _catalogueNavKey.currentState?.popUntil((route) => route.isFirst);
            _catalogueRefresh?.call();
          }
          if (index == 4) {
            _notificationsRefresh?.call();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: GrocerTheme.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: _navItems.map((item) {
          return BottomNavigationBarItem(
            icon: item.badgeCount != null && item.badgeCount! > 0
                ? Badge(
                    label: Text(
                      '${item.badgeCount! > 99 ? '99+' : item.badgeCount}',
                    ),
                    child: Icon(item.icon),
                  )
                : Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Déconnexion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GrocerTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthProvider>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
  const _NavItem(this.icon, this.activeIcon, this.label, this.badgeCount);
}
