class Category {
  final int id;
  final String nom;
  final int? productCount;

  Category({
    required this.id,
    required this.nom,
    this.productCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nom: json['nom'],
      productCount: json['productCount'] != null 
          ? int.tryParse(json['productCount'].toString()) 
          : 0,
    );
  }
}
