import 'package:flutter/material.dart';

class NotificationModel {
  final int id;
  final String message;
  final DateTime dateEnvoi;
  final int clientId;
  bool lue;

  NotificationModel({
    required this.id,
    required this.message,
    required this.dateEnvoi,
    required this.clientId,
    required this.lue,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      message: json['message'] ?? '',
      dateEnvoi: DateTime.tryParse(json['date_envoi'] ?? '') ?? DateTime.now(),
      clientId: json['client_id'],
      lue: json['lue'] == 1 || json['lue'] == true,
    );
  }

  String get shortTitle {
    final msg = message.toLowerCase();
    if (msg.contains('prête') || msg.contains('prete')) return 'Commande prête !';
    if (msg.contains('préparation') || msg.contains('preparation')) return 'Commande en préparation';
    if (msg.contains('livrée') || msg.contains('livree')) return 'Commande livrée';
    if (msg.contains('confirmée') || msg.contains('acceptée')) return 'Commande confirmée';
    return 'Mise à jour commande';
  }

  bool get isOrderReady =>
      message.toLowerCase().contains('prête') || message.toLowerCase().contains('prete');

  IconData get icon {
    final msg = message.toLowerCase();
    if (msg.contains('prête') || msg.contains('prete')) return Icons.check_circle_outline;
    if (msg.contains('préparation') || msg.contains('preparation')) return Icons.settings_outlined;
    if (msg.contains('livrée') || msg.contains('livree')) return Icons.local_shipping_outlined;
    if (msg.contains('confirmée') || msg.contains('acceptée')) return Icons.celebration_outlined;
    return Icons.notifications_outlined;
  }

  Color get iconBgColor {
    final msg = message.toLowerCase();
    if (msg.contains('prête') || msg.contains('prete')) return const Color(0xFFE8F5E9);
    if (msg.contains('préparation') || msg.contains('preparation')) return const Color(0xFFFFF3E0);
    if (msg.contains('livrée') || msg.contains('livree')) return const Color(0xFFE3F2FD);
    if (msg.contains('confirmée') || msg.contains('acceptée')) return const Color(0xFFFCE4EC);
    return const Color(0xFFF3E5F5);
  }

  Color get iconColor {
    final msg = message.toLowerCase();
    if (msg.contains('prête') || msg.contains('prete')) return const Color(0xFF2E7D32);
    if (msg.contains('préparation') || msg.contains('preparation')) return const Color(0xFFE65100);
    if (msg.contains('livrée') || msg.contains('livree')) return const Color(0xFF1565C0);
    if (msg.contains('confirmée') || msg.contains('acceptée')) return const Color(0xFFC62828);
    return const Color(0xFF6A1B9A);
  }
}
