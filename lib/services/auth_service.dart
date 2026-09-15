import 'package:dio/dio.dart';

import 'api_client.dart';
import 'secure_storage_service.dart';

class AuthResult {
  AuthResult.success() : error = null;
  AuthResult.failure(this.error);

  final String? error;
  bool get isSuccess => error == null;
}

/// Enveloppe les appels réseau d'authentification et la persistance
/// des tokens — correspond 1:1 aux endpoints définis dans le backend
/// (POST /auth/register, /auth/login, /auth/refresh, GET /auth/me).
class AuthService {
  AuthService(this._api, this._storage);

  final ApiClient _api;
  final SecureStorageService _storage;

  Future<AuthResult> register({required String email, required String password}) async {
    try {
      await _api.dio.post('/auth/register', data: {'email': email, 'password': password});
      return AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(_extractError(e));
    }
  }

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final response = await _api.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _storage.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
      return AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(_extractError(e));
    }
  }

  Future<bool> isLoggedIn() async => (await _storage.accessToken) != null;

  Future<void> logout() => _storage.clear();

  String _extractError(DioException e) {
    final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
    return detail?.toString() ?? 'Une erreur réseau est survenue.';
  }
}
