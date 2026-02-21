// lib/services/auth_service.dart
// Auth via backend API (JWT), plus Supabase pour les données en lecture.
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

  /// Envoyer le code OTP au numéro (backend → SMS Infobip/Orange).
  Future<Map<String, dynamic>> signInWithPhone(String phoneNumber) async {
    try {
      await _apiService.sendOtp(phoneNumber);
      return {'success': true, 'message': 'Code envoyé avec succès'};
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

  /// Déconnexion (révoque le refresh token et vide le stockage).
  Future<void> signOut() async {
    await _apiService.logout();
  }
}
