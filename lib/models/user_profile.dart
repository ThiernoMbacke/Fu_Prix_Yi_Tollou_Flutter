class UserProfile {
  final String id;
  final String? phone;
  final String? nom;
  final int contributionsCount;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    this.phone,
    this.nom,
    this.contributionsCount = 0,
    this.createdAt,
  });

  /// Backend API (camelCase)
  factory UserProfile.fromApiJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      phone: json['phone'] as String?,
      nom: json['nom'] as String?,
      contributionsCount: json['contributionsCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Supabase JSON (snake_case)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      nom: json['nom'] as String?,
      contributionsCount: json['contributions_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  // Convert object → JSON (utile pour mise à jour)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nom': nom,
      'contributions_count': contributionsCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
