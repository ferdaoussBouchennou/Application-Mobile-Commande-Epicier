import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: Color(0xFF7A5C44)),
            SizedBox(height: 20),
            Text(
              'Carte & Épiciers\n(à implémenter)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
            ),
          ],
        ),
      ),
    );
  }
}
