import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/chat_socket_service.dart';
import '../services/local_tts_service.dart';
import '../services/secure_storage_service.dart';
import '../services/voice_recognition_service.dart';
import '../services/voice_socket_service.dart';

/// Point central d'injection de dépendances — chaque service est
/// instancié une seule fois et réutilisé dans toute l'app.
final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider), ref.watch(secureStorageProvider));
});

final voiceRecognitionServiceProvider = Provider<VoiceRecognitionService>((ref) {
  return VoiceRecognitionService();
});

final localTtsServiceProvider = Provider<LocalTtsService>((ref) => LocalTtsService());

final voiceSocketServiceProvider = Provider<VoiceSocketService>((ref) {
  final service = VoiceSocketService(ref.watch(secureStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService(ref.watch(secureStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});
