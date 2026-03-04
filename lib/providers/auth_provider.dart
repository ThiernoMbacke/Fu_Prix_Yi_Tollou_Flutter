// lib/providers/auth_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService {
    _init();
  }
  final AuthService _authService;

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Synchrone : vrai si le profil est déjà chargé (utiliser dans l'UI).
  bool get isAuthenticatedSync => _userProfile != null;

  Future<bool> get isAuthenticated => _authService.isAuthenticated;

  static String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      final msg = e.response?.data;
      if (msg is Map && msg['message'] != null) return msg['message'].toString();
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return 'Impossible de joindre le serveur. Vérifiez que le backend tourne (port 8080) et l\'URL dans api_config.dart (localhost ou 10.0.2.2 pour l\'émulateur).';
      }
    }
    return e.toString();
  }

  void _init() async {
    final authenticated = await _authService.isAuthenticated;
    if (authenticated) {
      await loadUserProfile();
    } else {
      _userProfile = null;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile() async {
    try {
      _userProfile = await _authService.getUserProfile();
      notifyListeners();
    } catch (e) {
      print('Erreur chargement profil: $e');
      _userProfile = null;
      notifyListeners();
    }
  }

  /// Envoyer le code OTP (téléphone) via le backend.
  Future<void> signInWithPhone(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithPhone(phoneNumber);
      if (result['success'] != true) {
        _error = result['message'] ?? 'Erreur lors de l\'envoi du code';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Vérifier le code OTP (téléphone) et récupérer le profil.
  Future<void> verifyOTP({
    required String phone,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyOTP(phone: phone, token: token);
      await loadUserProfile();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Envoyer OTP par email (désactivé si vous n'utilisez que le backend téléphone).
  Future<void> sendOtpToEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _error = 'Connexion par email non disponible. Utilisez le numéro de téléphone.';
    _isLoading = false;
    notifyListeners();
  }

  /// Vérifier OTP email (désactivé).
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    _error = 'Connexion par email non disponible.';
    notifyListeners();
  }

  /// Connexion démo sans code (test1 ou test2). Pour démo.
  Future<bool> signInWithDemo(String demoUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithDemo(demoUser);
      await loadUserProfile();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? nom}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateProfile(nom: nom);
      await loadUserProfile();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userProfile = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
