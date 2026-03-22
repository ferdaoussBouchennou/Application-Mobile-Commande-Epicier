import 'package:flutter/material.dart';
import '../../screens/admin/admin_validation_screen.dart';
import '../../screens/admin/admin_orders_screen.dart';
import '../../screens/admin/admin_categories_screen.dart';
import '../../screens/admin/admin_disputes_screen.dart';
import '../../screens/admin/platform_stats/platform_stats_screen.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF2D5016),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == currentIndex) return;

        Widget nextScreen;
        switch (index) {
          case 0:
            nextScreen = const PlatformStatsScreen();
            break;
          case 1:
            nextScreen = const AdminValidationScreen();
            break;
          case 2:
            nextScreen = const AdminOrdersScreen();
            break;
          case 3:
            nextScreen = const AdminCategoriesScreen();
            break;
          case 4:
            nextScreen = const AdminDisputesScreen();
            break;
          default:
            return;
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => nextScreen,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Utilisateurs'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Commandes'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Catégories'),
        BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: 'Litiges'),
      ],
    );
  }
}
