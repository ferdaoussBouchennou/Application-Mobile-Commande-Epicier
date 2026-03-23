class Category {
  final int id;
  final String nom;
  final String? description;
  final int productCount;
  final int deactivatedProductCount;
  final int storeCount;
  final int ruptureCount;

  Category({
    required this.id,
    required this.nom,
    this.description,
    this.productCount = 0,
    this.deactivatedProductCount = 0,
    this.storeCount = 0,
    this.ruptureCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final pc = json['productCount'] ?? 0;
    final rc = json['retiredCount'] ?? json['deactivatedProductCount'] ?? 0;
    return Category(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      productCount: pc is int ? pc : int.tryParse(pc.toString()) ?? 0,
      deactivatedProductCount: rc is int ? rc : int.tryParse(rc.toString()) ?? 0,
      storeCount: json['storeCount'] ?? 0,
      ruptureCount: json['ruptureCount'] ?? 0,
    );
  }

  /// Catégorie « retirée » du catalogue épicier : plus de produits actifs mais des produits encore inactifs (liés).
  bool get isRetired =>
      productCount == 0 && deactivatedProductCount > 0;

  int get retiredCount => deactivatedProductCount;
}
