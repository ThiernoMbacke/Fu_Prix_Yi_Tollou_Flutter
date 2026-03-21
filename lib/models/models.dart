// Export des modèles
export 'user_profile.dart';

// models/ville.dart
class Ville {
  final String id;
  final String nom;
  final DateTime? createdAt;

  Ville({
    required this.id,
    required this.nom,
    this.createdAt,
  });

  factory Ville.fromJson(Map<String, dynamic> json) {
    return Ville(
      id: json['id'] as String,
      nom: json['nom'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

// models/marche.dart
class Marche {
  final String id;
  final String nom;
  final String villeId;
  final double? latitude;
  final double? longitude;
  final String? adresse;
  final String? createdBy;
  final DateTime? createdAt;
  
  // Relations
  Ville? ville;

  Marche({
    required this.id,
    required this.nom,
    required this.villeId,
    this.latitude,
    this.longitude,
    this.adresse,
    this.createdBy,
    this.createdAt,
    this.ville,
  });

  factory Marche.fromJson(Map<String, dynamic> json) {
    return Marche(
      id: json['id'] as String,
      nom: json['nom'] as String,
      villeId: json['ville_id'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      adresse: json['adresse'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      ville: json['villes'] != null 
          ? Ville.fromJson(json['villes'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'ville_id': villeId,
      'latitude': latitude,
      'longitude': longitude,
      if (adresse != null) 'adresse': adresse,
      'created_by': createdBy,
    };
  }
}

// models/produit.dart
class Produit {
  final String id;
  final String nom;
  final String categorie;
  final String? createdBy;
  final DateTime? createdAt;

  Produit({
    required this.id,
    required this.nom,
    required this.categorie,
    this.createdBy,
    this.createdAt,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'] as String,
      nom: json['nom'] as String,
      categorie: json['categorie'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'categorie': categorie,
      'created_by': createdBy,
    };
  }
}

// models/prix.dart
class Prix {
  final String id;
  final String produitId;
  final String marcheId;
  final double prix;
  final DateTime date;
  final String? createdBy;
  final DateTime? createdAt;
  /// Option premium : contact de l'annonceur
  final String? contactPhone;
  final String? contactLocation;
  final double? contactLat;
  final double? contactLng;
  final bool isPremium;

  // Relations
  Produit? produit;
  Marche? marche;

  Prix({
    required this.id,
    required this.produitId,
    required this.marcheId,
    required this.prix,
    required this.date,
    this.createdBy,
    this.createdAt,
    this.contactPhone,
    this.contactLocation,
    this.contactLat,
    this.contactLng,
    this.isPremium = false,
    this.produit,
    this.marche,
  });

  factory Prix.fromJson(Map<String, dynamic> json) {
    return Prix(
      id: json['id'] as String,
      produitId: json['produit_id'] as String,
      marcheId: json['marche_id'] as String,
      prix: double.parse(json['prix'].toString()),
      date: DateTime.parse(json['date'] as String),
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      contactPhone: json['contact_phone'] as String?,
      contactLocation: json['contact_location'] as String?,
      contactLat: (json['contact_lat'] as num?)?.toDouble(),
      contactLng: (json['contact_lng'] as num?)?.toDouble(),
      isPremium: json['is_premium'] as bool? ?? false,
      produit: json['produits'] != null
          ? Produit.fromJson(json['produits'] as Map<String, dynamic>)
          : null,
      marche: json['marches'] != null
          ? Marche.fromJson(json['marches'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produit_id': produitId,
      'marche_id': marcheId,
      'prix': prix,
      'date': date.toIso8601String().split('T')[0],
      'created_by': createdBy,
    };
  }
}