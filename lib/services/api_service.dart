import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import 'token_storage.dart';

/// Réponses auth
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserProfile user;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      user: UserProfile.fromApiJson(userJson),
    );
  }
}

/// Service HTTP pour le backend (auth, me, prix).
class ApiService {
  ApiService({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
        _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Toujours lire ApiConfig : après « Configurer l'URL », l'instance Dio gardait l'ancienne base.
        final base = ApiConfig.baseUrl;
        _dio.options.baseUrl = base;
        options.baseUrl = base;
        final token = await _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshAndRetry(error.requestOptions);
          if (refreshed != null) return handler.resolve(refreshed);
        }
        return handler.next(error);
      },
    ));
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;

  /// À appeler avant chaque requête : garantit que [Dio] utilise la dernière URL ([ApiConfig]).
  void _syncBaseUrl() {
    final b = ApiConfig.baseUrl;
    _dio.options.baseUrl = b;
  }

  Future<Response<dynamic>?> _refreshAndRetry(RequestOptions requestOptions) async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      _syncBaseUrl();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.refreshTokenPath,
        data: {'refreshToken': refresh},
      );
      final data = response.data;
      if (data != null && data['accessToken'] != null) {
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        requestOptions.headers['Authorization'] = 'Bearer ${data['accessToken']}';
        return await _dio.fetch(requestOptions);
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/auth/send-otp
  Future<void> sendOtp(String phoneNumber) async {
    _syncBaseUrl();
    final response = await _dio.post(
      ApiConfig.sendOtpPath,
      data: {'phoneNumber': phoneNumber.trim().replaceAll(' ', '')},
    );
    if (response.statusCode != 200) {
      throw Exception(response.data is Map ? (response.data as Map)['message'] : 'Erreur envoi OTP');
    }
  }

  /// POST /api/auth/demo → connexion sans code (test1 ou test2)
  Future<AuthTokens> demoLogin(String demoUser) async {
    _syncBaseUrl();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConfig.demoLoginPath,
      data: {'demoUser': demoUser},
    );
    final data = response.data;
    if (data == null) throw Exception('Réponse vide');
    return AuthTokens.fromJson(data);
  }

  /// POST /api/auth/verify-otp → tokens + user
  Future<AuthTokens> verifyOtp(String phoneNumber, String code) async {
    _syncBaseUrl();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConfig.verifyOtpPath,
      data: {
        'phoneNumber': phoneNumber.trim().replaceAll(' ', ''),
        'code': code.trim(),
      },
    );
    final data = response.data;
    if (data == null) throw Exception('Réponse vide');
    return AuthTokens.fromJson(data);
  }

  /// POST /api/auth/logout
  Future<void> logout() async {
    final refresh = await _tokenStorage.getRefreshToken();
    try {
      _syncBaseUrl();
      await _dio.post(ApiConfig.logoutPath, data: refresh != null ? {'refreshToken': refresh} : null);
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// GET /api/users/me
  Future<UserProfile?> getMe() async {
    try {
      _syncBaseUrl();
      final response = await _dio.get<Map<String, dynamic>>(ApiConfig.mePath);
      final data = response.data;
      if (data == null) return null;
      return UserProfile.fromApiJson(data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  /// PUT /api/users/me
  Future<void> updateMe({String? nom}) async {
    _syncBaseUrl();
    await _dio.put(ApiConfig.mePath, data: {'nom': nom});
  }

  /// POST /api/prix (ajout prix, JWT requis)
  /// Si [isPremium] est vrai, [contactPhone], [contactLocation] ou [contactLat]/[contactLng],
  /// [paymentMethod] et [paymentReference] doivent être renseignés.
  Future<void> addPrix({
    required String produitId,
    required String marcheId,
    required double prix,
    bool isPremium = false,
    String? contactPhone,
    String? contactLocation,
    double? contactLat,
    double? contactLng,
    String? paymentMethod,
    String? paymentReference,
  }) async {
    final data = <String, dynamic>{
      'produitId': produitId,
      'marcheId': marcheId,
      'prix': prix,
      'isPremium': isPremium,
    };
    if (isPremium) {
      data['contactPhone'] = contactPhone;
      data['contactLocation'] = contactLocation;
      if (contactLat != null) data['contactLat'] = contactLat;
      if (contactLng != null) data['contactLng'] = contactLng;
      data['paymentMethod'] = paymentMethod;
      data['paymentReference'] = paymentReference;
    }
    _syncBaseUrl();
    await _dio.post(ApiConfig.prixPath, data: data);
  }

  /// POST /api/marches — crée un marché (JWT requis).
  /// Retourne l’id du marché créé.
  Future<String> addMarche({
    required String nom,
    required String villeId,
    double? latitude,
    double? longitude,
    String? adresse,
  }) async {
    final payload = <String, dynamic>{
      'nom': nom.trim(),
      'villeId': villeId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (adresse != null && adresse.trim().isNotEmpty) 'adresse': adresse.trim(),
    };
    _syncBaseUrl();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConfig.marchesPath,
      data: payload,
    );
    final data = response.data;
    final id = data?['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Réponse serveur invalide (marché)');
    }
    return id;
  }

  /// POST /api/produits — crée un produit (JWT requis).
  Future<Produit> addProduit({
    required String nom,
    required String categorie,
  }) async {
    _syncBaseUrl();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConfig.produitsPath,
      data: {
        'nom': nom.trim(),
        'categorie': categorie.trim(),
      },
    );
    final data = response.data;
    final id = data?['id']?.toString();
    final nomOut = data?['nom']?.toString();
    final catOut = data?['categorie']?.toString();
    if (id == null || id.isEmpty || nomOut == null || catOut == null) {
      throw Exception('Réponse serveur invalide (produit)');
    }
    return Produit(id: id, nom: nomOut, categorie: catOut);
  }

  /// Vérifie si on a un token (sans appeler le serveur).
  Future<bool> hasToken() async {
    final t = await _tokenStorage.getAccessToken();
    return t != null && t.isNotEmpty;
  }
}
