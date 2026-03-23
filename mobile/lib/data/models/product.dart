class Product {
  final int id;
  final String nom;
  final double prix;
  final String? description;
  final int epicierId;
  final int categoryId;
  final String? imagePrincipale;
  final String? categoryName;
  final bool isRetiredMine;
  final bool ruptureStock;
  final String? unite;
  final String? typeUnite;
  final int stock;

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
    this.ruptureStock = false,
    this.unite,
    this.typeUnite,
    this.stock = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return Product(
      id: asInt(json['id']),
      nom: json['nom'],
      prix: double.tryParse(json['prix'].toString()) ?? 0.0,
      description: json['description'],
      epicierId: asInt(json['epicier_id']),
      categoryId: asInt(json['categorie_id']),
      imagePrincipale: json['image_principale'],
      categoryName: json['categorie_nom'],
      isRetiredMine: json['is_active'] == false, 
      ruptureStock: json['rupture_stock'] == true,
      unite: json['unite'],
      typeUnite: json['type_unite'],
      stock: asInt(json['stock']),
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prix': prix,
        'description': description,
        'categorie_id': categoryId,
        'unite': unite,
        'type_unite': typeUnite,
        'stock': stock,
        if (imagePrincipale != null) 'image_principale': imagePrincipale,
      };
}
