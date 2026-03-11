import 'package:flutter/material.dart';
import '../grocer_theme.dart';

/// Placeholder pour l'onglet Stats — design aligné sur l'app.
class GrocerStatsPlaceholderScreen extends StatelessWidget {
  const GrocerStatsPlaceholderScreen({super.key});

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
                Icons.bar_chart_outlined,
                size: 64,
                color: GrocerTheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: GrocerTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Statistiques & rapports — voir Accueil',
                style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
