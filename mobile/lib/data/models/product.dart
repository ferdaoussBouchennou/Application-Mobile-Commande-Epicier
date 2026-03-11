class Product {
  final int id;
  final String nom;
  final double prix;
  final String? description;
  final int epicierId;
  final int categoryId;
  final String? imagePrincipale;

  Product({
    required this.id,
    required this.nom,
    required this.prix,
    this.description,
    required this.epicierId,
    required this.categoryId,
    this.imagePrincipale,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nom: json['nom'],
      prix: double.tryParse(json['prix'].toString()) ?? 0.0,
      description: json['description'],
      epicierId: json['epicier_id'],
      categoryId: json['categorie_id'],
      imagePrincipale: json['image_principale'],
    );
  }
}
