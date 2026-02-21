/// Configuration de l'API backend (auth + utilisateur + ajout prix).
class ApiConfig {
  /// URL de base du backend (sans slash final).
  /// En dev: http://10.0.2.2:8080 (Android emulator) ou http://localhost:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String sendOtpPath = '/api/auth/send-otp';
  static const String verifyOtpPath = '/api/auth/verify-otp';
  static const String refreshTokenPath = '/api/auth/refresh-token';
  static const String logoutPath = '/api/auth/logout';
  static const String mePath = '/api/users/me';
  static const String prixPath = '/api/prix';
}
