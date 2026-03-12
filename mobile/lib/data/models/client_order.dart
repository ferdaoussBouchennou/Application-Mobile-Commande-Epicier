/// Commande client (GET /commandes)
class ClientOrder {
  final int id;
  final int epicierId;
  final String nomBoutique;
  final String? dateCommande;
  final String? dateRecuperation;
  final String? dateCommandeFormatted;
  final String creneau;
  final double montantTotal;
  final String statut;
  final int articleCount;

  ClientOrder({
    required this.id,
    required this.epicierId,
    required this.nomBoutique,
    this.dateCommande,
    this.dateRecuperation,
    this.dateCommandeFormatted,
    required this.creneau,
    required this.montantTotal,
    required this.statut,
    required this.articleCount,
  });

  static ClientOrder fromJson(Map<String, dynamic> json) {
    return ClientOrder(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      epicierId: int.tryParse(json['epicier_id']?.toString() ?? '0') ?? 0,
      nomBoutique: json['nom_boutique']?.toString() ?? '',
      dateCommande: json['date_commande']?.toString(),
      dateRecuperation: json['date_recuperation']?.toString(),
      dateCommandeFormatted: json['date_commande_formatted']?.toString(),
      creneau: json['creneau']?.toString() ?? '',
      montantTotal: double.tryParse(json['montant_total']?.toString() ?? '0') ?? 0,
      statut: json['statut']?.toString() ?? 'reçue',
      articleCount: int.tryParse(json['article_count']?.toString() ?? '0') ?? 0,
    );
  }
}
