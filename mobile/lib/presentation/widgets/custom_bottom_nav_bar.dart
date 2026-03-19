import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().itemCount;
    final unreadNotifCount = context.watch<NotificationProvider>().unreadCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2D5016), // Vert sombre
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Épiciers',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$cartItemCount'),
              isLabelVisible: cartItemCount > 0,
              backgroundColor: const Color(0xFF2D5016),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              label: Text('$cartItemCount'),
              isLabelVisible: cartItemCount > 0,
              backgroundColor: const Color(0xFF2D5016),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Panier',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$unreadNotifCount'),
              isLabelVisible: unreadNotifCount > 0,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.notifications_none_outlined),
            ),
            activeIcon: Badge(
              label: Text('$unreadNotifCount'),
              isLabelVisible: unreadNotifCount > 0,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifs',
          ),
        ],
      ),
    );
  }
}
