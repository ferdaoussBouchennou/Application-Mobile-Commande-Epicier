/// Commande telle que renvoyée par GET /epicier/commandes
class GrocerOrder {
  final int id;
  final String clientNom;
  final String clientPrenom;
  final String? dateCommande;
  final String? dateRecuperation;
  final String creneau;
  final double montantTotal;
  final String statut; // 'reçue' | 'prête' | 'refusee' | 'livrée'
  final String? messageRefus;
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
    this.messageRefus,
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
      messageRefus: json['message_refus']?.toString(),
      articleCount: int.tryParse(json['article_count']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Détail d'une ligne de commande (ticket articles)
class GrocerOrderDetailLine {
  final int id;
  final int produitId;
  final String nom;
  final String? imagePrincipale;
  final int quantite;
  final double prixUnitaire;
  final double totalLigne;
  final bool rupture;

  GrocerOrderDetailLine({
    required this.id,
    required this.produitId,
    required this.nom,
    this.imagePrincipale,
    required this.quantite,
    required this.prixUnitaire,
    required this.totalLigne,
    this.rupture = false,
  });

  static GrocerOrderDetailLine fromJson(Map<String, dynamic> json) {
    return GrocerOrderDetailLine(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      produitId: int.tryParse(json['produit_id']?.toString() ?? '0') ?? 0,
      nom: json['nom']?.toString() ?? '',
      imagePrincipale: json['image_principale']?.toString(),
      quantite: int.tryParse(json['quantite']?.toString() ?? '0') ?? 0,
      prixUnitaire: double.tryParse(json['prix_unitaire']?.toString() ?? '0') ?? 0,
      totalLigne: double.tryParse(json['total_ligne']?.toString() ?? '0') ?? 0,
      rupture: json['rupture'] == true,
    );
  }
}

/// Détail complet d'une commande (ticket articles/quantités/notes)
class GrocerOrderDetail {
  final int id;
  final String clientNom;
  final String clientPrenom;
  final String? clientEmail;
  final String? dateCommande;
  final String? dateRecuperation;
  final String creneau;
  final double montantTotal;
  final String statut;
  final String? messageRefus;
  final String? notes;
  final List<GrocerOrderDetailLine> details;

  GrocerOrderDetail({
    required this.id,
    required this.clientNom,
    required this.clientPrenom,
    this.clientEmail,
    this.dateCommande,
    this.dateRecuperation,
    required this.creneau,
    required this.montantTotal,
    required this.statut,
    this.messageRefus,
    this.notes,
    required this.details,
  });

  static GrocerOrderDetail fromJson(Map<String, dynamic> json) {
    final detailsList = json['details'] as List<dynamic>? ?? [];
    return GrocerOrderDetail(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      clientNom: json['client_nom']?.toString() ?? '',
      clientPrenom: json['client_prenom']?.toString() ?? '',
      clientEmail: json['client_email']?.toString(),
      dateCommande: json['date_commande']?.toString(),
      dateRecuperation: json['date_recuperation']?.toString(),
      creneau: json['creneau']?.toString() ?? '',
      montantTotal: double.tryParse(json['montant_total']?.toString() ?? '0') ?? 0,
      statut: json['statut']?.toString() ?? 'reçue',
      messageRefus: json['message_refus']?.toString(),
      notes: json['notes']?.toString(),
      details: detailsList
          .map((e) => GrocerOrderDetailLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
