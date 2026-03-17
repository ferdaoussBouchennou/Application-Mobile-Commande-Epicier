import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire'),
        backgroundColor: const Color(0xFF2D5016),
      ),
      body: const Center(
        child: Text('Gestion de l\'inventaire (À implémenter)'),
      ),
    );
  }
}
