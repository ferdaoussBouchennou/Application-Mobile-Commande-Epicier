import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../client/map_screen/map_screen.dart';
import '../admin/admin_validation_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../grocer/grocer_main_screen.dart';
import '../grocer/setup/grocer_setup_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final mdp = _passwordController.text.trim();

    if (email.isEmpty || mdp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.login(email, mdp);
      if (success && mounted) {
        final user = context.read<AuthProvider>().user;
        final role = user?['role'];

        if (role == 'ADMIN') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminValidationScreen()),
          );
        } else if (role == 'EPICIER') {
          final auth2 = context.read<AuthProvider>();
          if (auth2.needsSetup) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GrocerSetupScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GrocerMainScreen()),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: MapScreen.routeName),
              builder: (_) => MapScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header vert
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2D5016),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo.png', // Logo de l'appli
                            height: 36,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_basket, color: Colors.white, size: 36),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'MyHanut',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                children: [
                  const Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D1A0E),
                      fontFamily: 'Georgia', // ou un font serif similaire
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connectez-vous à votre compte !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Champ Email
                  _buildTextField(
                    hintText: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Champ Mot de passe
                  _buildTextField(
                    hintText: 'Mot de passe',
                    controller: _passwordController,
                    obscureText: _obscureText,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton Se connecter
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016), // Vert grisé de l'image
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    }
                  ),

                  const SizedBox(height: 16),

                  // Mot de passe oublié
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Lien Inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Vous n'avez pas encore de compte ? ",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Inscription",
                          style: TextStyle(
                            color: Color(0xFF6B8E7D),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Séparateur
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ou se connecter avec',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Boutons Réseaux Sociaux
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          iconData: FontAwesomeIcons.google,
                          iconColor: const Color(0xFFDB4437),
                          label: 'Google',
                          onPressed: () async {
                            try {
                              final auth = context.read<AuthProvider>();
                              final success = await auth.loginWithGoogle();
                              if (success && mounted) {
                                final role = auth.user?['role'] as String?;
                                if (role == 'ADMIN') {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => AdminValidationScreen()),
                                  );
                                } else if (role == 'EPICIER') {
                                  if (auth.needsSetup) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const GrocerSetupScreen()),
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const GrocerMainScreen()),
                                    );
                                  }
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      settings: const RouteSettings(name: MapScreen.routeName),
                                      builder: (_) => MapScreen(),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                if (e.toString().contains('en attente de validation')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Votre compte Epicier est en attente de validation par l\'administrateur.'), backgroundColor: Colors.orange), // Orange contextually better for pending
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur Google: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          iconData: FontAwesomeIcons.facebook,
                          iconColor: const Color(0xFF1877F2),
                          label: 'Facebook',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          iconData: FontAwesomeIcons.instagram,
                          iconColor: const Color(0xFFE4405F),
                          label: 'Instagram',
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    String? iconPath,
    IconData? iconData,
    Color? iconColor,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null)
            Image.asset(iconPath, height: 24, width: 24)
          else if (iconData != null)
            FaIcon(iconData, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
