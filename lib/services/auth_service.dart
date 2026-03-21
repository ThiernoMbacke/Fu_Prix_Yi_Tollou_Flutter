// lib/services/auth_service.dart
// Auth via backend API (JWT), plus Supabase pour les données en lecture.
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/user_profile.dart';
import 'api_service.dart';
import 'token_storage.dart';

class AuthService {
  late final TokenStorage _tokenStorage;
  late final ApiService _apiService;

  AuthService({TokenStorage? tokenStorage, ApiService? apiService}) {
    _tokenStorage = tokenStorage ?? TokenStorage();
    _apiService = apiService ?? ApiService(tokenStorage: _tokenStorage);
  }

  /// True si un access token est présent (sans vérifier la validité côté serveur).
  Future<bool> get isAuthenticated => _apiService.hasToken();

  static String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Impossible de joindre le serveur à ${ApiConfig.baseUrl}. '
          'Sur le téléphone : écran connexion → « Configurer l\'URL du serveur » → '
          'http://VOTRE_IP:8080 (IPv4 du PC : ipconfig). Même Wi‑Fi, backend lancé, pare-feu (port 8080).';
    }
    return e.message ?? e.toString();
  }

  /// Envoyer le code OTP au numéro (backend → SMS Infobip/Orange).
  Future<Map<String, dynamic>> signInWithPhone(String phoneNumber) async {
    try {
      await _apiService.sendOtp(phoneNumber);
      return {'success': true, 'message': 'Code envoyé avec succès'};
    } on DioException catch (e) {
      throw Exception(_dioMessage(e));
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du code: $e');
    }
  }

  /// Vérifier le code OTP et stocker les tokens JWT.
  Future<void> verifyOTP({
    required String phone,
    required String token,
  }) async {
    try {
      final tokens = await _apiService.verifyOtp(phone, token);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } on DioException catch (e) {
      throw Exception(_dioMessage(e));
    } catch (e) {
      throw Exception('Code incorrect ou expiré: $e');
    }
  }

  /// Récupérer le profil utilisateur (backend GET /api/users/me).
  Future<UserProfile?> getUserProfile() async {
    return _apiService.getMe();
  }

  /// Mettre à jour le profil (nom).
  Future<void> updateProfile({String? nom}) async {
    await _apiService.updateMe(nom: nom);
  }

  /// Incrémentation faite côté backend lors de l'ajout d'un prix (POST /api/prix).
  Future<void> incrementContributions() async {
    // No-op côté client; le backend incrémente quand on appelle addPrix.
  }

  /// Connexion démo sans code (test1 ou test2). Pour démo uniquement.
  Future<void> signInWithDemo(String demoUser) async {
    final tokens = await _apiService.demoLogin(demoUser);
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  /// Déconnexion (révoque le refresh token et vide le stockage).
  Future<void> signOut() async {
    await _apiService.logout();
  }
}
