class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String? docVerf;
  final String statutInscription;
  final bool isActive;
  final Map<String, dynamic>? store;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.docVerf,
    required this.statutInscription,
    required this.isActive,
    this.store,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      role: json['role'],
      docVerf: json['doc_verf'],
      statutInscription: json['statut_inscription'] ?? 'ACCEPTE',
      isActive: json['is_active'] ?? true,
      store: json['epicier'],
    );
  }

  String get fullName => '$prenom $nom';
}
