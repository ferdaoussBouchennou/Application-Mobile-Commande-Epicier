import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0), // Beige chaud
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Titre
              const Text(
                'Bienvenue\nsur MyHanut',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1A0E),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 36),

              // Logo central
              Image.asset(
                'assets/images/loading.png',
                height: 220,
              ),

              const SizedBox(height: 36),

              // Sous-titre
              const Text(
                'Votre épicerie de quartier\nà portée de main',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7A5C44),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // Bouton Se connecter
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: naviguer vers LoginScreen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016), // Vert foncé
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bouton Créer un compte
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: naviguer vers RegisterScreen
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D1A0E),
                    side: const BorderSide(
                      color: Color(0xFFBFA98A),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
