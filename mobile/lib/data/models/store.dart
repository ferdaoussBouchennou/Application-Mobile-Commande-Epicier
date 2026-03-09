class Store {
  final int id;
  final int utilisateurId;
  final String nomBoutique;
  final String adresse;
  final String? telephone;
  final String? description;
  final String? imageUrl;
  final double rating;
  final bool isActive;
  final List<Availability>? disponibilites;
  final String? ownerName;
  final List<String> tags;
  final String? distance;

  Store({
    required this.id,
    required this.utilisateurId,
    required this.nomBoutique,
    required this.adresse,
    this.telephone,
    this.description,
    this.imageUrl,
    this.rating = 0.0,
    this.isActive = true,
    this.disponibilites,
    this.ownerName,
    this.tags = const [],
    this.distance,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    var rawDispos = json['disponibilites'] as List?;
    List<Availability>? dispos = rawDispos != null 
      ? rawDispos.map((i) => Availability.fromJson(i)).toList() 
      : null;

    String? owner;
    if (json['utilisateur'] != null) {
      owner = "${json['utilisateur']['prenom']} ${json['utilisateur']['nom']}";
    }

    return Store(
      id: json['id'],
      utilisateurId: json['utilisateur_id'],
      nomBoutique: json['nom_boutique'],
      adresse: json['adresse'],
      telephone: json['telephone'],
      description: json['description'],
      imageUrl: json['image_url'],
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      isActive: json['is_active'] ?? true,
      disponibilites: dispos,
      ownerName: owner,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : ['Épices', 'Légumes', 'Fruits'], // Default tags for UI
      distance: json['distance'] ?? "350 m", // Placeholder distance for UI mockup
    );
  }
}

class Availability {
  final int id;
  final String jour;
  final String heureDebut;
  final String heureFin;

  Availability({
    required this.id,
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['id'],
      jour: json['jour'],
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
    );
  }
}
