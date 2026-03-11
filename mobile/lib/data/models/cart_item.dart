class CartItem {
  final int produitId;
  final String nom;
  final double prix;
  final String? imagePrincipale;
  final int? epicierId;
  int quantite;

  CartItem({
    required this.produitId,
    required this.nom,
    required this.prix,
    this.imagePrincipale,
    this.epicierId,
    required this.quantite,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      produitId: json['produit_id'],
      nom: json['nom'] ?? '',
      prix: double.tryParse(json['prix'].toString()) ?? 0.0,
      imagePrincipale: json['image_principale'],
      epicierId: json['epicier_id'],
      quantite: json['quantite'] ?? 1,
    );
  }

  double get lineTotal => prix * quantite;
}
