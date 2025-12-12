// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authService.isAuthenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Écouter les changements d'authentification
    _authService.authStateChanges.listen((AuthState state) {
      final session = state.session;

      if (session != null) {
        loadUserProfile();
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
    
    // Charger le profil si l'utilisateur est déjà connecté
    if (_authService.isAuthenticated) {
      loadUserProfile();
    }
  }

  Future<void> loadUserProfile() async {
    try {
      _userProfile = await _authService.getUserProfile();
      notifyListeners();
    } catch (e) {
      print('Erreur chargement profil: $e');
    }
  }

  // ========================================
  // AUTHENTIFICATION PAR TÉLÉPHONE (TWILIO)
  // ========================================

  /// Envoyer le code OTP via Twilio
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

  /// Vérifier le code OTP (téléphone) avec Twilio
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
    }

    _isLoading = false;
    notifyListeners();
  }

  // ========================================
  // AUTHENTIFICATION PAR EMAIL (SUPABASE)
  // ========================================

  /// Envoyer le code OTP par email
  Future<void> sendOtpToEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmail(email);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Vérifier le code OTP pour l'email
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyEmailOtp(
        email: email,
        token: token,
      );
      
      await loadUserProfile();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // GESTION DU PROFIL
  // ========================================

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