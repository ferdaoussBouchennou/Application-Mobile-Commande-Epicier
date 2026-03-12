import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'grocer_theme.dart';
import 'dashboard/grocer_dashboard_screen.dart';
import 'catalogue/grocer_catalogue_screen.dart';
import 'orders/grocer_orders_placeholder_screen.dart';
import 'stats/grocer_stats_placeholder_screen.dart';

/// Écran principal de l'espace Épicier — même design que MapScreen (parcourir sans compte).
class GrocerMainScreen extends StatefulWidget {
  const GrocerMainScreen({super.key});

  @override
  State<GrocerMainScreen> createState() => _GrocerMainScreenState();
}

class _GrocerMainScreenState extends State<GrocerMainScreen> {
  int _currentIndex = 0;
  VoidCallback? _catalogueRefresh;
  final GlobalKey<NavigatorState> _catalogueNavKey = GlobalKey<NavigatorState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
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
      const GrocerOrdersPlaceholderScreen(),
      const GrocerStatsPlaceholderScreen(),
    ];
  }

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_outlined, Icons.home, 'Accueil', 0),
    _NavItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Catalogue', null),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Commandes', 5),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Stats', null),
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
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
                    label: Text('${item.badgeCount! > 99 ? '99+' : item.badgeCount}'),
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
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
  const _NavItem(this.icon, this.activeIcon, this.label, this.badgeCount);
}
