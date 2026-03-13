import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../store_list_screen.dart';
import '../cart_screen.dart';
import '../client_orders_screen.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';

class MapScreen extends StatefulWidget {
  /// Route name used so nested screens (e.g. product list) can pop back here instead of to WelcomeScreen.
  static const String routeName = '/client';

  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _currentIndex = 0;

  List<Widget> _buildPages() {
    return [
      // Page 0 : Accueil (Carte & Recherche)
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: Color(0xFF7A5C44)),
            SizedBox(height: 20),
            Text(
              'Carte & Épiciers autour de vous\n(Accueil)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
            ),
          ],
        ),
      ),
      const StoreListScreen(),
      CartScreen(onOrderConfirmed: () => setState(() => _currentIndex = 3)),
      const ClientOrdersScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.read<CartProvider>();
    final pending = cartProvider.pendingTabIndex;
    if (pending != null && pending >= 0 && pending < 4) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: _currentIndex == 1 ? null : AppBar(
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MyHanut',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: pages[_currentIndex],
        bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refetch cart when user opens Panier tab so it's always up to date
          if (index == 2) {
            final token = context.read<AuthProvider>().token;
            context.read<CartProvider>().fetchCart(token);
          }
        },
      ),
    );
  }
}
