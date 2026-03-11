import 'package:flutter/material.dart';
import '../grocer_theme.dart';

/// Placeholder pour l'écran Commandes Épicier — design aligné sur l'app.
class GrocerOrdersPlaceholderScreen extends StatelessWidget {
  const GrocerOrdersPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrocerTheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: GrocerTheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              const Text(
                'Commandes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: GrocerTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Commandes temps réel — à venir',
                style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
