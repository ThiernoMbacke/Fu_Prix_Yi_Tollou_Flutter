import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage des tokens JWT.
/// - Sur mobile (Android / iOS) : [FlutterSecureStorage] chiffré.
/// - Sur web : [SharedPreferences] (localStorage).
class TokenStorage {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccess);
    }
    return _secureStorage.read(key: _keyAccess);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefresh);
    }
    return _secureStorage.read(key: _keyRefresh);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccess, accessToken);
      await prefs.setString(_keyRefresh, refreshToken);
      return;
    }
    await _secureStorage.write(key: _keyAccess, value: accessToken);
    await _secureStorage.write(key: _keyRefresh, value: refreshToken);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccess);
      await prefs.remove(_keyRefresh);
      return;
    }
    await _secureStorage.deleteAll();
  }
}
