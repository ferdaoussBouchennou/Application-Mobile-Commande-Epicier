class Category {
  final int id;
  final String nom;
  final String? description;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;
  final int productCount;
  final int deactivatedProductCount;
  final int storeCount;
  final int ruptureCount;

  Category({
    required this.id,
    required this.nom,
    this.description,
    this.imageUrl,
    this.displayOrder = 0,
    this.isActive = true,
    this.productCount = 0,
    this.deactivatedProductCount = 0,
    this.storeCount = 0,
    this.ruptureCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      imageUrl: json['image_url'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      productCount: json['productCount'] ?? 0,
      deactivatedProductCount: json['deactivatedProductCount'] ?? 0,
      storeCount: json['storeCount'] ?? 0,
      ruptureCount: json['ruptureCount'] ?? 0,
    );
  }
  bool get isRetired => !isActive;
  int get retiredCount => deactivatedProductCount;
}
