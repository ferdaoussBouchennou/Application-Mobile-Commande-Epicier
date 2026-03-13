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
      produitId: _parseInt(json['produit_id']),
      nom: json['nom']?.toString() ?? '',
      prix: double.tryParse(json['prix'].toString()) ?? 0.0,
      imagePrincipale: json['image_principale']?.toString(),
      epicierId: json['epicier_id'] != null ? _parseInt(json['epicier_id']) : null,
      quantite: _parseInt(json['quantite']) ?? 1,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  double get lineTotal => prix * quantite;
}
