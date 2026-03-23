
import 'package:flutter/material.dart';

class Store {
  final int id;
  final int utilisateurId;
  final String nomBoutique;
  final String adresse;
  final String? telephone;
  final String? description;
  final String? imageUrl;
  final double rating;
  final double? latitude;
  final double? longitude;
  final String statutInscription;
  final bool isActive;
  final List<Availability>? disponibilites;
  final String? ownerName;
  final List<String> tags;
  final double? distanceKm;

  Store({
    required this.id,
    required this.utilisateurId,
    required this.nomBoutique,
    required this.adresse,
    this.telephone,
    this.description,
    this.imageUrl,
    this.rating = 0.0,
    this.latitude,
    this.longitude,
    this.statutInscription = 'EN_ATTENTE',
    this.isActive = true,
    this.disponibilites,
    this.ownerName,
    this.tags = const [],
    this.distanceKm,
  });

  String? get formattedDistance {
    if (distanceKm == null) return null;
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  bool get isOpen {
    if (disponibilites == null || disponibilites!.isEmpty) return false;

    final now = DateTime.now();
    final joursMap = {
      1: 'lundi',
      2: 'mardi',
      3: 'mercredi',
      4: 'jeudi',
      5: 'vendredi',
      6: 'samedi',
      7: 'dimanche',
    };

    final jourActuel = joursMap[now.weekday];
    
    // Trouver la disponibilité pour aujourd'hui
    final disposAujourdhui = disponibilites!.where((d) => d.jour.toLowerCase() == jourActuel).toList();
    
    if (disposAujourdhui.isEmpty) return false;

    for (var dispo in disposAujourdhui) {
      try {
        final nowTime = TimeOfDay.fromDateTime(now);
        final startParts = dispo.heureDebut.split(':');
        final endParts = dispo.heureFin.split(':');
        
        final startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
        final endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

        double toDouble(TimeOfDay myTime) => myTime.hour + myTime.minute / 60.0;
        
        if (toDouble(nowTime) >= toDouble(startTime) && toDouble(nowTime) <= toDouble(endTime)) {
          return true;
        }
      } catch (e) {
        print("Erreur parsing heure: $e");
      }
    }

    return false;
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  /// Vitrine épicerie (`epiciers.image_url`) — chaîne vide traitée comme absent.
  static String? _optionalImagePath(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

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
      imageUrl: _optionalImagePath(json['image_url']),
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      statutInscription: json['statut_inscription'] ?? 'EN_ATTENTE',
      isActive: _parseBool(json['is_active'], true),
      disponibilites: dispos,
      ownerName: owner,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : ['Épices', 'Légumes', 'Fruits'],
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
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
