import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
          'Créer un compte',
          style: TextStyle(color: Color(0xFF2D1A0E), fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'Page d\'inscription\n(à implémenter)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF7A5C44)),
        ),
      ),
    );
  }
}
