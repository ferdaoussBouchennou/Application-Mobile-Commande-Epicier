class Category {
  final int id;
  final String nom;
  final int? productCount;
  /// Nombre de produits retirés (inactifs) dans cette catégorie pour l'épicier.
  final int? retiredCount;
  /// Nombre de produits actifs dans cette catégorie (admin).
  final int? activeProductCount;

  Category({
    required this.id,
    required this.nom,
    this.productCount,
    this.retiredCount,
    this.activeProductCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nom: json['nom'],
      productCount: json['productCount'] != null
          ? int.tryParse(json['productCount'].toString())
          : 0,
      retiredCount: json['retiredCount'] != null
          ? int.tryParse(json['retiredCount'].toString())
          : 0,
      activeProductCount: json['activeProductCount'] != null
          ? int.tryParse(json['activeProductCount'].toString())
          : null,
    );
  }

  /// Catégorie active (au moins un produit actif) pour l'admin.
  bool get isActiveAdmin => (activeProductCount ?? 0) > 0;

  /// Catégorie considérée comme "retirée" (plus de produits actifs, mais des produits inactifs).
  bool get isRetired =>
      (retiredCount ?? 0) > 0 && (productCount ?? 0) == 0;
}
