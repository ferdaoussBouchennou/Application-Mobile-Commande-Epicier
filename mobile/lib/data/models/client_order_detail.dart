/// Détail d'une commande client (GET /commandes/:id) avec lignes produits.
class ClientOrderDetail {
  final int id;
  final int epicierId;
  final String nomBoutique;
  final String? telephoneEpicier;
  final String? adresseEpicier;
  final String? dateCommande;
  final String? dateRecuperation;
  final String creneau;
  final double montantTotal;
  final String statut;
  final int articleCount;
  final List<ClientOrderLine> lignes;

  ClientOrderDetail({
    required this.id,
    required this.epicierId,
    required this.nomBoutique,
    this.telephoneEpicier,
    this.adresseEpicier,
    this.dateCommande,
    this.dateRecuperation,
    required this.creneau,
    required this.montantTotal,
    required this.statut,
    required this.articleCount,
    required this.lignes,
  });

  static ClientOrderDetail fromJson(Map<String, dynamic> json) {
    final lignesList = json['lignes'] as List<dynamic>? ?? [];
    return ClientOrderDetail(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      epicierId: int.tryParse(json['epicier_id']?.toString() ?? '0') ?? 0,
      nomBoutique: json['nom_boutique']?.toString() ?? '',
      telephoneEpicier: json['telephone_epicier']?.toString(),
      adresseEpicier: json['adresse_epicier']?.toString(),
      dateCommande: json['date_commande']?.toString(),
      dateRecuperation: json['date_recuperation']?.toString(),
      creneau: json['creneau']?.toString() ?? '',
      montantTotal: double.tryParse(json['montant_total']?.toString() ?? '0') ?? 0,
      statut: json['statut']?.toString() ?? 'reçue',
      articleCount: int.tryParse(json['article_count']?.toString() ?? '0') ?? 0,
      lignes: lignesList
          .map((e) => ClientOrderLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class ClientOrderLine {
  final int produitId;
  final String nom;
  final int quantite;
  final double prixUnitaire;
  final double totalLigne;

  ClientOrderLine({
    required this.produitId,
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
    required this.totalLigne,
  });

  static ClientOrderLine fromJson(Map<String, dynamic> json) {
    return ClientOrderLine(
      produitId: int.tryParse(json['produit_id']?.toString() ?? '0') ?? 0,
      nom: json['nom']?.toString() ?? '',
      quantite: int.tryParse(json['quantite']?.toString() ?? '0') ?? 0,
      prixUnitaire: double.tryParse(json['prix_unitaire']?.toString() ?? '0') ?? 0,
      totalLigne: double.tryParse(json['total_ligne']?.toString() ?? '0') ?? 0,
    );
  }
}
