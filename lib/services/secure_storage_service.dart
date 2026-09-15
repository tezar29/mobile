import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encapsule flutter_secure_storage (Keychain iOS / Keystore Android)
/// pour stocker les tokens JWT — jamais en SharedPreferences en clair.
class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'jarvis_access_token';
  static const _refreshTokenKey = 'jarvis_refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
