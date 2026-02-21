import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user_profile.dart';
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

  Future<Response<dynamic>?> _refreshAndRetry(RequestOptions requestOptions) async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;
    try {
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
    final response = await _dio.post(
      ApiConfig.sendOtpPath,
      data: {'phoneNumber': phoneNumber.trim().replaceAll(' ', '')},
    );
    if (response.statusCode != 200) {
      throw Exception(response.data is Map ? (response.data as Map)['message'] : 'Erreur envoi OTP');
    }
  }

  /// POST /api/auth/verify-otp → tokens + user
  Future<AuthTokens> verifyOtp(String phoneNumber, String code) async {
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
      await _dio.post(ApiConfig.logoutPath, data: refresh != null ? {'refreshToken': refresh} : null);
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// GET /api/users/me
  Future<UserProfile?> getMe() async {
    try {
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
    await _dio.put(ApiConfig.mePath, data: {'nom': nom});
  }

  /// POST /api/prix (ajout prix, JWT requis)
  Future<void> addPrix({
    required String produitId,
    required String marcheId,
    required double prix,
  }) async {
    await _dio.post(ApiConfig.prixPath, data: {
      'produitId': produitId,
      'marcheId': marcheId,
      'prix': prix,
    });
  }

  /// Vérifie si on a un token (sans appeler le serveur).
  Future<bool> hasToken() async {
    final t = await _tokenStorage.getAccessToken();
    return t != null && t.isNotEmpty;
  }
}
