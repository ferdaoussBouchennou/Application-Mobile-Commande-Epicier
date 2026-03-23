import 'package:flutter/material.dart';

/// Couleurs alignées sur le reste de l'app (welcome, MapScreen, CustomBottomNavBar).
class GrocerTheme {
  GrocerTheme._();

  // Même palette que l'app MyHanut
  static const Color background = Color(0xFFFDF6F0);   // Beige (welcome, map)
  static const Color primary = Color(0xFF2D5016);      // Vert (boutons, app bar, nav actif)
  static const Color textDark = Color(0xFF2D1A0E);      // Texte principal
  static const Color textMuted = Color(0xFF7A5C44);    // Sous-titre, secondaire
  static const Color border = Color(0xFFBFA98A);      // Bordures (outlined button)
  static const Color cardBackground = Colors.white;
  static const Color trendPositive = Color(0xFF2D5016); // Vert comme primary
  static const Color trendNegative = Color(0xFFC0392B); // Rouge annulations

  /// Surfaces dashboard (style apps e-commerce)
  static const Color surfaceMuted = Color(0xFFF3EDE6);
  static const Color primarySoft = Color(0xFFE4EDE0);
  static const Color accentBlue = Color(0xFF1565C0);
  static const Color accentAmber = Color(0xFFE65100);
  static const Color accentPurple = Color(0xFF6A1B9A);
}
