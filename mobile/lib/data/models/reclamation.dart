class Reclamation {
  final int id;
  final int? commandeId;
  final String motif;
  final String description;
  final String? photo;
  final String statut;
  final String? reponseEpicier;
  final DateTime dateCreation;

  Reclamation({
    required this.id,
    this.commandeId,
    required this.motif,
    required this.description,
    this.photo,
    required this.statut,
    this.reponseEpicier,
    required this.dateCreation,
  });

  factory Reclamation.fromJson(Map<String, dynamic> json) {
    return Reclamation(
      id: json['id'],
      commandeId: json['commande_id'],
      motif: json['motif'] ?? '',
      description: json['description'] ?? '',
      photo: json['photo'],
      statut: json['statut'] ?? 'Ouverte',
      reponseEpicier: json['reponse_epicier'],
      dateCreation: json['date_creation'] != null 
          ? DateTime.parse(json['date_creation']) 
          : DateTime.now(),
    );
  }
}
