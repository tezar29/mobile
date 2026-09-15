import '../services/api_client.dart';

class IntegrationsStatus {
  const IntegrationsStatus({required this.google, required this.whatsapp});

  final bool google;
  final bool whatsapp;

  factory IntegrationsStatus.fromJson(Map<String, dynamic> json) {
    return IntegrationsStatus(google: json['google'] as bool, whatsapp: json['whatsapp'] as bool);
  }
}

/// Lit l'état des intégrations externes (étape 7) et déclenche la
/// connexion Google — utilisé par l'écran Réglages (étape 9).
class IntegrationsService {
  IntegrationsService(this._api);

  final ApiClient _api;

  Future<IntegrationsStatus> getStatus() async {
    final response = await _api.dio.get('/integrations/status');
    return IntegrationsStatus.fromJson(response.data as Map<String, dynamic>);
  }

  /// Renvoie l'URL d'autorisation Google à ouvrir dans le navigateur
  /// système (voir SettingsScreen — url_launcher, pas de WebView
  /// intégrée pour rester sur le flux OAuth standard recommandé par Google).
  Future<String> getGoogleAuthUrl() async {
    final response = await _api.dio.get('/integrations/google/connect');
    return response.data['auth_url'] as String;
  }
}
