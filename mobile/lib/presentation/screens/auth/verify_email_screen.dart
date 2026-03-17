import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  bool _resendCooldown = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le code à 6 chiffres.')),
      );
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.verifyEmail(widget.email, otp);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email vérifié ! Vous pouvez vous connecter.'),
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

  Future<void> _resend() async {
    if (_resendCooldown) return;
    try {
      final auth = context.read<AuthProvider>();
      await auth.resendOTP(widget.email);
      setState(() => _resendCooldown = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code renvoyé ! Vérifiez votre email.'), backgroundColor: Color(0xFF2D5016)),
        );
      }
      // Re-enable after 30 seconds
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) setState(() => _resendCooldown = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: Column(
        children: [
          // Header vert
          Container(
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
                          errorBuilder: (_, __, ___) => const Icon(Icons.shopping_basket, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'MyHanut',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5016).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined, size: 40, color: Color(0xFF2D5016)),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Vérification Email',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2D1A0E), fontFamily: 'Georgia'),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Un code à 6 chiffres a été envoyé à\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 36),

                  // OTP input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12),
                      decoration: InputDecoration(
                        hintText: '------',
                        hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 12),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bouton vérifier
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5016),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Vérifier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Renvoyer
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => TextButton(
                      onPressed: (auth.isLoading || _resendCooldown) ? null : _resend,
                      child: Text(
                        _resendCooldown ? 'Code renvoyé ✓' : 'Renvoyer le code',
                        style: TextStyle(
                          color: _resendCooldown ? Colors.grey : const Color(0xFF6B8E7D),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
