import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../store_list_screen.dart';
import '../cart_screen.dart';
import '../client_orders_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'home_map_tab.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../screens/auth/welcome_screen.dart';

import '../../../../providers/order_provider.dart';
import '../../../../providers/notification_provider.dart';

class MapScreen extends StatefulWidget {
  static const String routeName = '/client';
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    Future.microtask(() {
      if (mounted) {
        final token = context.read<AuthProvider>().token;
        if (token != null && token.isNotEmpty) {
          context.read<NotificationProvider>().fetchNotifications(token);
          context.read<OrderProvider>().startPolling(token);
        }
      }
    });
  }

  static const List<String> _titles = [
    'MyHanut',
    '', // StoreListScreen manages its own AppBar
    'Mon Panier',
    'Mes Commandes',
    'Notifications',
    'Mon Profil',
  ];

  List<Widget> _buildPages() {
    return [
      // Page 0 : Accueil (Carte)
      const HomeMapTab(),
      // Page 1 : Épiciers (gère son propre AppBar)
      const StoreListScreen(),
      // Page 2 : Panier
      CartScreen(onOrderConfirmed: () {
        final token = context.read<AuthProvider>().token;
        context.read<OrderProvider>().fetchOrders(token);
        setState(() => _currentIndex = 3);
      }),
      // Page 3 : Commandes
      const ClientOrdersScreen(),
      // Page 4 : Notifications
      const NotificationsScreen(),
      // Page 5 : Profil
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final pending = cartProvider.pendingTabIndex;
    if (pending != null && pending >= 0 && pending < 6) {
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

    final pages = _pages;

    // Pages that manage their own AppBar (index 0 = HomeMapTab, index 1 = StoreListScreen)
    final bool hideAppBar = _currentIndex == 0 || _currentIndex == 1;

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

}
