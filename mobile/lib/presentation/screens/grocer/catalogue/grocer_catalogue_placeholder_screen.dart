import 'package:flutter/material.dart';
import '../grocer_theme.dart';

/// Placeholder pour l'écran Catalogue Épicier — design aligné sur l'app.
class GrocerCataloguePlaceholderScreen extends StatelessWidget {
  const GrocerCataloguePlaceholderScreen({super.key});

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
                Icons.inventory_2_outlined,
                size: 64,
                color: GrocerTheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              const Text(
                'Catalogue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: GrocerTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestion des produits — à venir',
                style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
