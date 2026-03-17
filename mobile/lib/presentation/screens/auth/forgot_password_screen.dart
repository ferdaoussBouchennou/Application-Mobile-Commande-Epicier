import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _step2 = false; // false = enter email, true = enter OTP + new password
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _emailSentTo = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre email.')),
      );
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      await auth.forgotPassword(email);
      setState(() {
        _emailSentTo = email;
        _step2 = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code envoyé ! Vérifiez votre email.'),
            backgroundColor: Color(0xFF2D5016),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le code à 6 chiffres.')),
      );
      return;
    }
    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe doit contenir au moins 8 caractères.')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas.')),
      );
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.resetPassword(_emailSentTo, otp, newPassword);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe réinitialisé avec succès !'),
            backgroundColor: Color(0xFF2D5016),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 140,
      width: double.infinity,
      color: const Color(0xFF2D5016),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () {
                  if (_step2) {
                    setState(() => _step2 = false);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    errorBuilder: (_, __, ___) => const Icon(Icons.shopping_basket, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 10),
                  const Text('MyHanut', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    Widget? suffixIcon,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textAlign: textAlign,
        style: style ?? const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step2 ? _buildStep2() : _buildStep1(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2D5016).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset, size: 40, color: Color(0xFF2D5016)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Mot de passe oublié ?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2D1A0E), fontFamily: 'Georgia'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Entrez votre email pour recevoir\nun code de réinitialisation.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),
        _buildTextField(
          controller: _emailController,
          hintText: 'Votre adresse email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 28),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: auth.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Envoyer le code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: const Text(
            'Retour à la connexion',
            style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2D5016).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.vpn_key_outlined, size: 40, color: Color(0xFF2D5016)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Nouveau mot de passe',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2D1A0E), fontFamily: 'Georgia'),
        ),
        const SizedBox(height: 12),
        Text(
          'Code envoyé à $_emailSentTo',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 36),

        // Code OTP
        _buildTextField(
          controller: _otpController,
          hintText: '------',
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12),
        ),
        const SizedBox(height: 16),

        // Nouveau mot de passe
        _buildTextField(
          controller: _newPasswordController,
          hintText: 'Nouveau mot de passe',
          obscureText: _obscureNew,
          suffixIcon: IconButton(
            icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 16),

        // Confirmer
        _buildTextField(
          controller: _confirmPasswordController,
          hintText: 'Confirmer le mot de passe',
          obscureText: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 28),

        Consumer<AuthProvider>(
          builder: (context, auth, _) => SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: auth.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Réinitialiser', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}
