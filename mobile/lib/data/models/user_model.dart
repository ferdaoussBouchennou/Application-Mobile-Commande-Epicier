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
    final epicier = json['epicier'] as Map<String, dynamic>?;
    final statut = json['role'] == 'EPICIER' && epicier != null
        ? (epicier['statut_inscription'] as String? ?? 'EN_ATTENTE')
        : (json['statut_inscription'] as String? ?? 'ACCEPTE');
    return UserModel(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      role: json['role'],
      docVerf: json['doc_verf'],
      statutInscription: statut,
      isActive: json['is_active'] ?? true,
      store: epicier,
    );
  }

  String get fullName => '$prenom $nom';

  // Getters for Epicier stats
  int get produitsCount => store?['produits_count'] ?? 0;
  int get commandesCount => store?['commandes_count'] ?? 0;
  int get ruptureCount => store?['rupture_count'] ?? 0;
  double get rating => double.tryParse(store?['rating']?.toString() ?? '0.0') ?? 0.0;
}
