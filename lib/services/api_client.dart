import 'package:dio/dio.dart';

import '../core/config/app_config.dart';
import 'secure_storage_service.dart';

/// Client HTTP central. Injecte automatiquement le Bearer token et
/// tente un refresh transparent sur une réponse 401 avant d'abandonner.
class ApiClient {
  ApiClient(this._storage) : dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final alreadyRetried = error.requestOptions.extra['authRetry'] == true;
          final isRefreshRequest = error.requestOptions.path.endsWith('/auth/refresh');
          if (error.response?.statusCode == 401 && !alreadyRetried && !isRefreshRequest) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              error.requestOptions.extra['authRetry'] = true;
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final SecureStorageService _storage;

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      await _storage.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
      return true;
    } on DioException {
      await _storage.clear();
      return false;
    }
  }
}
