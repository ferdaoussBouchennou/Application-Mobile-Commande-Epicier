import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../store_list_screen.dart';
import '../cart_screen.dart';
import '../client_orders_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../screens/auth/welcome_screen.dart';

class MapScreen extends StatefulWidget {
  static const String routeName = '/client';
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'MyHanut',
    '', // StoreListScreen manages its own AppBar
    'Mon Panier',
    'Mes Commandes',
    'Notifications',
  ];

  List<Widget> _buildPages() {
    return [
      // Page 0 : Accueil
      const _HomeTab(),
      // Page 1 : Épiciers (gère son propre AppBar)
      const StoreListScreen(),
      // Page 2 : Panier
      CartScreen(onOrderConfirmed: () => setState(() => _currentIndex = 3)),
      // Page 3 : Commandes
      const ClientOrdersScreen(),
      // Page 4 : Notifications
      const NotificationsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final pending = cartProvider.pendingTabIndex;
    if (pending != null && pending >= 0 && pending < 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        cartProvider.clearPendingTabIndex();
        setState(() => _currentIndex = pending);
        if (pending == 2) {
          final token = context.read<AuthProvider>().token;
          cartProvider.fetchCart(token);
        }
      });
    }

    final pages = _buildPages();

    // Pages that manage their own AppBar (index 1 = StoreListScreen)
    final bool hideAppBar = _currentIndex == 1;

    // Check if the user is logged in
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: hideAppBar
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false, // Prevent default back button
              leading: isLoggedIn 
                  ? null // No back button for logged-in users
                  : IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Retour',
                    ),
              title: Text(
                _titles[_currentIndex],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 2) {
            final token = context.read<AuthProvider>().token;
            context.read<CartProvider>().fetchCart(token);
          }
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

// ─── Home tab placeholder ────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Color(0xFF7A5C44)),
          SizedBox(height: 20),
          Text(
            'Carte & Épiciers autour de vous',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
          ),
        ],
      ),
    );
  }
}
