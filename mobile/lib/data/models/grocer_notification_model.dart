import 'package:flutter/material.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  final normalized = str.contains(' ') && !str.contains('T')
      ? str.replaceFirst(' ', 'T')
      : str;
  return DateTime.tryParse(normalized);
}

class GrocerNotificationModel {
  final int id;
  final int utilisateurId;
  final String message;
  final DateTime dateEnvoi;
  bool lue;

  GrocerNotificationModel({
    required this.id,
    required this.utilisateurId,
    required this.message,
    required this.dateEnvoi,
    required this.lue,
  });

  factory GrocerNotificationModel.fromJson(Map<String, dynamic> json) {
    return GrocerNotificationModel(
      id: json['id'],
      utilisateurId: json['utilisateur_id'] ?? json['epicier_id'] ?? 0,
      message: json['message'] ?? '',
      dateEnvoi:
          _parseDateTime(json['date_envoi']) ??
          _parseDateTime(json['created_at']) ??
          DateTime.now(),
      lue: json['lue'] == 1 || json['lue'] == true,
    );
  }

  String get shortTitle {
    final msg = message.toLowerCase();
    if (msg.contains('nouvelle commande') ||
        (msg.contains('commande #') && msg.contains('reçue')))
      return 'Nouvelle commande';
    if (msg.contains('refusé d\'ajouter') ||
        (msg.contains('refusé') && msg.contains('produit')))
      return 'Produit refusé';
    if (msg.contains('commande refusée') ||
        (msg.contains('refusé') && msg.contains('commande #')))
      return 'Commande refusée';
    if (msg.contains('a annulé la commande')) return 'Commande annulée';
    if (msg.contains('accepté les modifications') ||
        msg.contains('modifications (ruptures)'))
      return 'Commande modifiée';
    if (msg.contains('nouvel avis') || msg.contains('avis reçu'))
      return 'Nouvel avis';
    if (msg.contains('statut réclamation') ||
        msg.contains('statut reclamation'))
      return 'Statut réclamation';
    if (msg.contains('réclamation') || msg.contains('reclamation'))
      return 'Nouvelle réclamation';
    if (msg.contains('accepté d\'ajouter') ||
        (msg.contains('accepté') && msg.contains('produit')))
      return 'Produit accepté';
    return 'Notification';
  }

  /// Extrait l'ID de commande du message (ex: "commande #123" ou "#123")
  int? get commandeId {
    final match = RegExp(r'commande\s*#(\d+)').firstMatch(message);
    if (match != null) return int.tryParse(match.group(1) ?? '');
    return null;
  }

  /// Extrait l'ID de réclamation du message.
  /// Ex: "réclamation #123" ou admin: "Statut réclamation (commande) #123 : …"
  int? get reclamationId {
    final statut = RegExp(
      r'Statut\s+r[eé]clamation[^#]*#(\d+)',
      caseSensitive: false,
    ).firstMatch(message);
    if (statut != null) {
      return int.tryParse(statut.group(1) ?? '');
    }
    final match = RegExp(
      r'r[eé]clamation\s*#(\d+)',
    ).firstMatch(message.toLowerCase());
    if (match != null) return int.tryParse(match.group(1) ?? '');
    return null;
  }

  /// Admin : « Statut réclamation (avis) #12 : … » — litige sur un avis, pas une commande.
  bool get isStatutReclamationAvis => RegExp(
        r'Statut\s+r[eé]clamation\s*\(\s*avis\s*\)',
        caseSensitive: false,
      ).hasMatch(message);

  bool get isReclamationRelated =>
      message.toLowerCase().contains('réclamation') ||
      message.toLowerCase().contains('reclamation');

  IconData get icon {
    final msg = message.toLowerCase();
    if (msg.contains('nouvelle commande') || msg.contains('commande #'))
      return Icons.shopping_cart_outlined;
    if (msg.contains('nouvel avis') || msg.contains('avis reçu'))
      return Icons.star_outline;
    if (msg.contains('réclamation') || msg.contains('reclamation'))
      return Icons.report_problem_outlined;
    if (msg.contains('accepté') || msg.contains('accepte'))
      return Icons.check_circle_outline;
    if (msg.contains('refusé') ||
        msg.contains('refuse') ||
        msg.contains('annulé'))
      return Icons.cancel_outlined;
    return Icons.notifications_outlined;
  }

  Color get iconBgColor {
    final msg = message.toLowerCase();
    if (msg.contains('nouvelle commande') || msg.contains('commande #'))
      return const Color(0xFFE8F5E9);
    if (msg.contains('nouvel avis') || msg.contains('avis reçu'))
      return const Color(0xFFFFF3E0);
    if (msg.contains('réclamation') || msg.contains('reclamation'))
      return const Color(0xFFFFEBEE);
    if (msg.contains('accepté') || msg.contains('accepte'))
      return const Color(0xFFE3F2FD);
    if (msg.contains('refusé') || msg.contains('refuse'))
      return const Color(0xFFFFF8E1);
    return const Color(0xFFF3E5F5);
  }

  Color get iconColor {
    final msg = message.toLowerCase();
    if (msg.contains('nouvelle commande') || msg.contains('commande #'))
      return const Color(0xFF2E7D32);
    if (msg.contains('nouvel avis') || msg.contains('avis reçu'))
      return const Color(0xFFE65100);
    if (msg.contains('réclamation') || msg.contains('reclamation'))
      return const Color(0xFFC62828);
    if (msg.contains('accepté') || msg.contains('accepte'))
      return const Color(0xFF1565C0);
    if (msg.contains('refusé') || msg.contains('refuse'))
      return const Color(0xFFF9A825);
    return const Color(0xFF6A1B9A);
  }

  bool get isOrderRelated =>
      message.toLowerCase().contains('commande') ||
      message.toLowerCase().contains('produit');
}
