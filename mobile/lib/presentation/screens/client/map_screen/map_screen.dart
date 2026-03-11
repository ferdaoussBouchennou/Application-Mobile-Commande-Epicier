import 'package:flutter/material.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../store_list_screen.dart';
import '../cart_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _currentIndex = 0;

  // Placeholder pour les différentes pages :
  // 0 : Accueil (Carte)
  // 1 : Épiciers
  // 2 : Panier
  // 3 : Commandes
  final List<Widget> _pages = [
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
    
    // Page 1 : Épiciers (Liste)
    const StoreListScreen(),

    // Page 2 : Panier
    const CartScreen(),

    // Page 3 : Commandes
    const Center(
      child: Text(
        'Historique des Commandes\n(Bientôt disponible)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
