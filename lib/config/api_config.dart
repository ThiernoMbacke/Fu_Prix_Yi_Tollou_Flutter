import 'package:shared_preferences/shared_preferences.dart';

import 'api_config_platform_io.dart' if (dart.library.html) 'api_config_platform_web.dart' as _platform;

/// Configuration de l'API backend. S'adapte automatiquement au contexte
/// (Web, émulateur Android, simulateur iOS, appareil physique).
/// Sur appareil physique, l'utilisateur peut enregistrer l'URL du PC (ex. 192.168.1.203:8080).
class ApiConfig {
  ApiConfig._();

  static const String _prefsKey = 'api_base_url';

  static String? _resolvedBaseUrl;

  /// URL de base du backend (sans slash final). À appeler après [init].
  static String get baseUrl => _resolvedBaseUrl ?? 'http://localhost:8080';

  /// Initialise l'URL : d'abord valeur enregistrée, sinon détection plateforme.
  /// À appeler une fois au démarrage (ex. dans _AppLoader._init).
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null && stored.trim().isNotEmpty) {
      _resolvedBaseUrl = _normalizeUrl(stored.trim());
      return;
    }
    _resolvedBaseUrl = await _platform.getDefaultBackendBaseUrl();
  }

  static String _normalizeUrl(String url) {
    String s = url.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  /// Enregistre une URL personnalisée (ex. pour téléphone en USB sur le même Wi‑Fi).
  /// Après enregistrement, redémarrer l'application pour que le backend utilise cette URL.
  static Future<void> setStoredBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_prefsKey);
      _resolvedBaseUrl = null;
      return;
    }
    final normalized = _normalizeUrl(url.trim());
    await prefs.setString(_prefsKey, normalized);
    _resolvedBaseUrl = normalized;
  }

  /// URL actuellement enregistrée (pour affichage dans l'écran de config).
  static Future<String> getStoredBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? '';
  }

  // Chemins API (inchangés)
  static const String sendOtpPath = '/api/auth/send-otp';
  static const String verifyOtpPath = '/api/auth/verify-otp';
  static const String refreshTokenPath = '/api/auth/refresh-token';
  static const String logoutPath = '/api/auth/logout';
  static const String demoLoginPath = '/api/auth/demo';
  static const String mePath = '/api/users/me';
  static const String prixPath = '/api/prix';
}
