import 'package:flutter/material.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';

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
  // 2 : Commandes
  // 3 : Panier
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
    
    // Page 1 : Épiciers (Lise)
    const Center(
      child: Text(
        'Liste des Épiciers\n(Bientôt disponible)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
      ),
    ),

    // Page 2 : Commandes
    const Center(
      child: Text(
        'Historique des Commandes\n(Bientôt disponible)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
      ),
    ),

    // Page 3 : Panier
    const Center(
      child: Text(
        'Votre Panier\n(Bientôt disponible)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
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
