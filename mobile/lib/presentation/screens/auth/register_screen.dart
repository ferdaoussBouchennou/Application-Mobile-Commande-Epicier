import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../client/map_screen/map_screen.dart';
import '../grocer/grocer_main_screen.dart';
import '../grocer/setup/grocer_setup_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Bascule entre Inscription Client (false) et Epicier (true)
  bool _isEpicier = false;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Champs spécifiques Epicier
  final _phoneController = TextEditingController();
  PlatformFile? _docFile;
  
  bool _obscureText = true;

  void _navigateEpicierAfterOAuth(AuthProvider auth) {
    if (!mounted) return;
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
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _docFile = result.files.single;
      });
    }
  }

  Future<void> _register() async {
    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final mdp = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (nom.isEmpty || prenom.isEmpty || email.isEmpty || mdp.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le numéro de téléphone doit contenir exactement 10 chiffres (ex: 0612345678)')),
      );
      return;
    }

    if (_isEpicier) {
      if (_docFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez joindre un document de vérification')),
        );
        return;
      }
    }

    // Validation du mot de passe (au moins 8 caractères, 1 majuscule, 1 chiffre)
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(mdp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe doit contenir au moins 8 caractères, une majuscule et un chiffre')),
      );
      return;
    }

    try {
      bool success = false;
      final provider = context.read<AuthProvider>();

      if (_isEpicier) {
        success = await provider.registerEpicier({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'mdp': mdp,
          'adresse': 'Adresse à configurer', // Placeholder pour l'instant
          'telephone': phone,
        }, docBytes: _docFile?.bytes, docFilename: _docFile?.name);
      } else {
        success = await provider.registerClient({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'mdp': mdp,
          'telephone': phone,
        });
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé ! Vérifiez votre email pour continuer.'),
            backgroundColor: Color(0xFF2D5016),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(email: _emailController.text.trim()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('EMAIL_EXISTS')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cet email est déjà utilisé. Veuillez vous connecter.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        } else if (errorMsg.contains('en attente de validation')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inscription envoyée ! En attente de validation par l\'administrateur.'), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg.replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0), // Beige clair
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header vert foncé
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
                            'assets/images/logo.png',
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                children: [
                  Text(
                    _isEpicier ? 'Inscription Epicier' : 'Inscription Client',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D1A0E),
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEpicier 
                      ? 'Rejoignez-nous et développez votre épicerie !'
                      : 'Créez votre compte pour commencer !',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Toggle Switch (Client vs Epicier)
                  Container(
                    height: 50,
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
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isEpicier = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !_isEpicier ? const Color(0xFFD9B99F) : Colors.transparent, // Mint color for selection
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Client',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !_isEpicier ? const Color(0xFF2D1A0E) : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isEpicier = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isEpicier ? const Color(0xFFD9B99F) : Colors.transparent, // Mint color for selection
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Epicier',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isEpicier ? const Color(0xFF2D1A0E) : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Champs de base commun (Nom, Prenom, Email, Password)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          hintText: 'Prénom',
                          controller: _prenomController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          hintText: 'Nom',
                          controller: _nomController,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  const SizedBox(height: 12),
                  
                  _buildTextField(
                    hintText: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 12),

                  _buildTextField(
                    hintText: 'Téléphone (10 chiffres)',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),

                  // Si l'utilisateur a sélectionné "Epicier", afficher les champs supplémentaires
                  if (_isEpicier) ...[
                    const SizedBox(height: 16),
                    
                    // Bouton pour uploader un document
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE0DA).withOpacity(0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file, color: Color(0xFF6B8E7D)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Document de vérification', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E))),
                                Text(_docFile?.name ?? 'Kbis, Registre de commerce...', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _pickDocument,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFFDF6F0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Joindre', style: TextStyle(color: Color(0xFF6B8E7D), fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
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
                  
                  const SizedBox(height: 20),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016), // Mint
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'S\'inscrire',
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

                  // Ligne séparatrice
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ou s\'inscrire avec',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Boutons Réseaux Sociaux
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          iconData: FontAwesomeIcons.google,
                          iconColor: const Color(0xFFDB4437),
                          label: 'Google',
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            
                            Map<String, dynamic>? epicierData;
                            if (_isEpicier) {
                              if (_docFile == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Veuillez joindre un document de vérification avant de continuer avec Google')),
                                );
                                return;
                              }
                              
                              epicierData = {
                                'role': 'EPICIER',
                                'telephone': _phoneController.text.trim(),
                              };
                            }

                            try {
                              final success = await authProvider.loginWithGoogle(
                                epicierData: epicierData,
                                docBytes: _docFile?.bytes,
                                docFilename: _docFile?.name,
                              );
                              if (success && mounted) {
                                final role = authProvider.user?['role'] as String?;
                                if (role == 'EPICIER') {
                                  _navigateEpicierAfterOAuth(authProvider);
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => MapScreen()),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                if (e.toString().contains('en attente de validation') && _isEpicier) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Inscription envoyée ! En attente de validation par l\'administrateur.'), backgroundColor: Colors.orange),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                  );
                                } else if (e.toString().contains('EMAIL_EXISTS')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cet email est déjà associé à un compte Client. Veuillez vous connecter.'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
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
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            
                            Map<String, dynamic>? epicierData;
                            if (_isEpicier) {
                              if (_docFile == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Veuillez joindre un document de vérification avant de continuer avec Facebook')),
                                );
                                return;
                              }
                              epicierData = {
                                'role': 'EPICIER',
                                'telephone': _phoneController.text.trim(),
                              };
                            }

                            try {
                              final success = await authProvider.loginWithFacebook(
                                epicierData: epicierData,
                                docBytes: _docFile?.bytes,
                                docFilename: _docFile?.name,
                              );
                              if (success && mounted) {
                                final role = authProvider.user?['role'] as String?;
                                if (role == 'ADMIN') {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())); // Redirect to login for admin validation
                                } else if (role == 'EPICIER') {
                                  _navigateEpicierAfterOAuth(authProvider);
                                } else {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MapScreen()));
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                final errorMsg = e.toString();
                                if (errorMsg.contains('en attente de validation') && _isEpicier) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Inscription envoyée ! En attente de validation par l\'administrateur.'), backgroundColor: Colors.orange),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                  );
                                } else if (errorMsg.contains('EMAIL_EXISTS')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cet email est déjà associé à un compte Client. Veuillez vous connecter.'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMsg.replaceAll('Exception: ', '')), backgroundColor: Colors.red),
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
                          iconData: FontAwesomeIcons.instagram,
                          iconColor: const Color(0xFFE4405F),
                          label: 'Instagram',
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            
                            Map<String, dynamic>? epicierData;
                            if (_isEpicier) {
                              if (_docFile == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Veuillez joindre un document de vérification avant de continuer avec Instagram')),
                                );
                                return;
                              }
                              epicierData = {
                                'role': 'EPICIER',
                                'telephone': _phoneController.text.trim(),
                              };
                            }

                            try {
                              final success = await authProvider.loginWithInstagram(
                                epicierData: epicierData,
                                docBytes: _docFile?.bytes,
                                docFilename: _docFile?.name,
                              );
                              if (success && mounted) {
                                final role = authProvider.user?['role'] as String?;
                                if (role == 'ADMIN') {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                                } else if (role == 'EPICIER') {
                                  _navigateEpicierAfterOAuth(authProvider);
                                } else {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MapScreen()));
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                final errorMsg = e.toString();
                                if (errorMsg.contains('en attente de validation') && _isEpicier) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Inscription envoyée ! En attente de validation par l\'administrateur.'), backgroundColor: Colors.orange),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                  );
                                } else if (errorMsg.contains('EMAIL_EXISTS')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cet email est déjà associé à un compte Client. Veuillez vous connecter.'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMsg.replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  // Lien Connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Vous avez déjà un compte ? ",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Connexion",
                          style: TextStyle(
                            color: Color(0xFF2D5016), // Mint ou vert
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
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
