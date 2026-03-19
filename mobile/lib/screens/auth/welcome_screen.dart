import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../presentation/screens/admin/admin_validation_screen.dart';
import '../../../presentation/screens/grocer/grocer_main_screen.dart';
import '../../../presentation/screens/grocer/setup/grocer_setup_screen.dart';
import '../../../presentation/screens/auth/login_screen.dart';
import '../../../presentation/screens/auth/register_screen.dart';
import '../../../presentation/screens/client/map_screen/map_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Show splash/loading while AuthProvider is initializing (session restoration)
    if (!auth.initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF6F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)))
      );
    }

    // After initialization, if logged in, redirect
    if (auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final role = auth.user?['role'];
        if (role == 'ADMIN') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminValidationScreen()));
        } else if (role == 'EPICIER') {
          if (auth.needsSetup) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GrocerSetupScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GrocerMainScreen()));
          }
        } else {
          Navigator.pushNamedAndRemoveUntil(context, MapScreen.routeName, (r) => false);
        }
      });
      return const Scaffold(
        backgroundColor: Color(0xFFFDF6F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)))
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
  
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
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_basket, color: Color(0xFF2D5016), size: 120),
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
  
                const SizedBox(height: 40),
  
                // Bouton Se connecter
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _goTo(context, const LoginScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5016),
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
                    onPressed: () => _goTo(context, const RegisterScreen()),
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
  
                const SizedBox(height: 20),
  
                // Lien "Parcourir sans compte"
                GestureDetector(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(context, MapScreen.routeName, (route) => false),
                  child: const Text(
                    'Parcourir sans compte',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A5C44),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF7A5C44),
                    ),
                  ),
                ),
  
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
