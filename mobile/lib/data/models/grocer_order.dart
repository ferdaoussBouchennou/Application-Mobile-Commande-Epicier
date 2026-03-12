/// Commande telle que renvoyée par GET /epicier/commandes
class GrocerOrder {
  final int id;
  final String clientNom;
  final String clientPrenom;
  final String? dateCommande;
  final String? dateRecuperation;
  final String creneau;
  final double montantTotal;
  final String statut; // 'reçue' | 'prête' | 'livrée'
  final int articleCount;

  GrocerOrder({
    required this.id,
    required this.clientNom,
    required this.clientPrenom,
    this.dateCommande,
    this.dateRecuperation,
    required this.creneau,
    required this.montantTotal,
    required this.statut,
    required this.articleCount,
  });

  String get clientDisplay => clientNom.isNotEmpty
      ? '$clientPrenom ${clientNom[0].toUpperCase()}.'
      : clientPrenom; // e.g. "Ismail B."

  static GrocerOrder fromJson(Map<String, dynamic> json) {
    return GrocerOrder(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      clientNom: json['client_nom']?.toString() ?? '',
      clientPrenom: json['client_prenom']?.toString() ?? '',
      dateCommande: json['date_commande']?.toString(),
      dateRecuperation: json['date_recuperation']?.toString(),
      creneau: json['creneau']?.toString() ?? '',
      montantTotal: double.tryParse(json['montant_total']?.toString() ?? '0') ?? 0,
      statut: json['statut']?.toString() ?? 'reçue',
      articleCount: int.tryParse(json['article_count']?.toString() ?? '0') ?? 0,
    );
  }
}
