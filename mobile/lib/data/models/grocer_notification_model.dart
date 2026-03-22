import 'package:flutter/material.dart';

class GrocerNotificationModel {
  final int id;
  final int epicierId;
  final String message;
  final DateTime dateEnvoi;
  bool lue;

  GrocerNotificationModel({
    required this.id,
    required this.epicierId,
    required this.message,
    required this.dateEnvoi,
    required this.lue,
  });

  factory GrocerNotificationModel.fromJson(Map<String, dynamic> json) {
    return GrocerNotificationModel(
      id: json['id'],
      epicierId: json['epicier_id'],
      message: json['message'] ?? '',
      dateEnvoi: DateTime.tryParse(json['date_envoi']?.toString() ?? '') ??
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      lue: json['lue'] == 1 || json['lue'] == true,
    );
  }

  String get shortTitle {
    final msg = message.toLowerCase();
    if (msg.contains('nouvelle commande') || msg.contains('commande #')) return 'Nouvelle commande';
    if (msg.contains('nouvel avis') || msg.contains('avis reçu')) return 'Nouvel avis';
    if (msg.contains('réclamation') || msg.contains('reclamation')) return 'Nouvelle réclamation';
    if (msg.contains('accepté') || msg.contains('accepte')) return 'Produit accepté';
    if (msg.contains('refusé') || msg.contains('refuse')) return 'Produit refusé';
    return 'Notification';
  }

  IconData get icon {
    final msg = message.toLowerCase();
    if (msg.contains('nouvelle commande') || msg.contains('commande #')) return Icons.shopping_cart_outlined;
    if (msg.contains('nouvel avis') || msg.contains('avis reçu')) return Icons.star_outline;
    if (msg.contains('réclamation') || msg.contains('reclamation')) return Icons.report_problem_outlined;
    if (msg.contains('accepté') || msg.contains('accepte')) return Icons.check_circle_outline;
    if (msg.contains('refusé') || msg.contains('refuse')) return Icons.cancel_outlined;
    return Icons.notifications_outlined;
  }

  Color get iconBgColor {
    final msg = message.toLowerCase();
    if (msg.contains('nouvelle commande') || msg.contains('commande #')) return const Color(0xFFE8F5E9);
    if (msg.contains('nouvel avis') || msg.contains('avis reçu')) return const Color(0xFFFFF3E0);
    if (msg.contains('réclamation') || msg.contains('reclamation')) return const Color(0xFFFFEBEE);
    if (msg.contains('accepté') || msg.contains('accepte')) return const Color(0xFFE3F2FD);
    if (msg.contains('refusé') || msg.contains('refuse')) return const Color(0xFFFFF8E1);
    return const Color(0xFFF3E5F5);
  }

  Color get iconColor {
    final msg = message.toLowerCase();
    if (msg.contains('nouvelle commande') || msg.contains('commande #')) return const Color(0xFF2E7D32);
    if (msg.contains('nouvel avis') || msg.contains('avis reçu')) return const Color(0xFFE65100);
    if (msg.contains('réclamation') || msg.contains('reclamation')) return const Color(0xFFC62828);
    if (msg.contains('accepté') || msg.contains('accepte')) return const Color(0xFF1565C0);
    if (msg.contains('refusé') || msg.contains('refuse')) return const Color(0xFFF9A825);
    return const Color(0xFF6A1B9A);
  }

  bool get isOrderRelated =>
      message.toLowerCase().contains('commande') ||
      message.toLowerCase().contains('produit');
}
