// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ========================================
  // AUTHENTIFICATION PAR TÉLÉPHONE (TWILIO)
  // ========================================

  /// Envoyer le code OTP au numéro de téléphone via Twilio
  Future<Map<String, dynamic>> signInWithPhone(String phoneNumber) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-phone-otp',
        body: {'phoneNumber': phoneNumber},
      );

      if (response.data == null) {
        throw Exception('Aucune réponse du serveur');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return {
          'success': true,
          'message': 'Code envoyé avec succès',
        };
      } else {
        throw Exception(data['error'] ?? 'Erreur lors de l\'envoi du code');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du code: $e');
    }
  }

  /// Vérifier le code OTP (téléphone) avec Twilio
  Future<void> verifyOTP({
    required String phone,
    required String token,
  }) async {
    try {
      // Vérifier le code avec Twilio via Edge Function
      final response = await _supabase.functions.invoke(
        'verify-phone-otp',
        body: {
          'phoneNumber': phone,
          'code': token,
        },
      );

      if (response.data == null) {
        throw Exception('Aucune réponse du serveur');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Code incorrect ou expiré');
      }

      // Le code est valide, créer le profil si nécessaire
      // L'utilisateur a été créé côté serveur
      await Future.delayed(const Duration(milliseconds: 500));

      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _createUserProfileIfNeeded(user, phone);
      }
    } catch (e) {
      throw Exception('Code incorrect ou expiré: $e');
    }
  }

  // ========================================
  // AUTHENTIFICATION PAR EMAIL (SUPABASE OTP)
  // ========================================

  /// Connexion par email avec code OTP (Supabase natif)
  Future<void> signInWithEmail(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du code: $e');
    }
  }

  /// Vérifier le code OTP (email) - Supabase natif
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      
      if (response.session == null) {
        throw Exception('Code invalide ou expiré');
      }

      // Créer le profil utilisateur s'il n'existe pas
      if (response.user != null) {
        await _createUserProfileIfNeeded(response.user!, email);
      }
    } catch (e) {
      throw Exception('Erreur lors de la vérification: $e');
    }
  }

  // ========================================
  // GESTION DU PROFIL UTILISATEUR
  // ========================================

  /// Créer le profil utilisateur si nécessaire
  Future<void> _createUserProfileIfNeeded(User user, String contact) async {
    try {
      final existingProfile = await _supabase
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        final isEmail = contact.contains('@');
        await _supabase.from(SupabaseConfig.userProfilesTable).insert({
          'id': user.id,
          if (isEmail) 'email': contact else 'phone': contact,
          'contributions_count': 0,
        });
      }
    } catch (e) {
      print('Erreur lors de la création du profil: $e');
    }
  }

  /// Récupérer le profil utilisateur
  Future<UserProfile?> getUserProfile() async {
    if (currentUser == null) return null;

    try {
      final data = await _supabase
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  /// Mettre à jour le profil
  Future<void> updateProfile({String? nom}) async {
    if (currentUser == null) throw Exception('Non authentifié');

    try {
      await _supabase
          .from(SupabaseConfig.userProfilesTable)
          .update({'nom': nom})
          .eq('id', currentUser!.id);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Incrémenter le compteur de contributions via RPC
  Future<void> incrementContributions() async {
    if (currentUser == null) return;

    try {
      await _supabase.rpc('increment_contributions', params: {
        'user_id': currentUser!.id,
      });
    } catch (e) {
      print('Erreur incrémentation: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

/* 
📝 FONCTION SQL À AJOUTER DANS SUPABASE (SQL Editor) :

CREATE OR REPLACE FUNCTION increment_contributions(user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_profiles 
  SET contributions_count = contributions_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
*/