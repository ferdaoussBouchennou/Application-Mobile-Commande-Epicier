class Product {
  final int id;
  final String nom;
  final double prix;
  final String? description;
  final int epicierId;
  final int categoryId;
  final String? imagePrincipale;
  /// Nom de la catégorie (renvoyé par l'API épicier)
  final String? categoryName;
  /// true si c'est un produit que j'avais retiré du catalogue (réintégration possible)
  final bool isRetiredMine;

  Product({
    required this.id,
    required this.nom,
    required this.prix,
    this.description,
    required this.epicierId,
    required this.categoryId,
    this.imagePrincipale,
    this.categoryName,
    this.isRetiredMine = false,
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
      categoryName: json['categorie_nom'],
      isRetiredMine: json['is_retired_mine'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prix': prix,
        'description': description,
        'categorie_id': categoryId,
        if (imagePrincipale != null) 'image_principale': imagePrincipale,
      };
}
