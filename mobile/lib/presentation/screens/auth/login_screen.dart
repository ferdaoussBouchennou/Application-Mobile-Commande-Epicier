import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D1A0E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Connexion',
          style: TextStyle(color: Color(0xFF2D1A0E), fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'Page de connexion\n(à implémenter)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
        ),
      ),
    );
  }
}
