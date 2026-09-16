import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config/app_config.dart';
import 'secure_storage_service.dart';
import 'voice_socket_event.dart';

/// Connexion temps réel vers `/api/v1/voice/ws` : envoie le texte
/// transcrit localement (voir [VoiceRecognitionService]) et reçoit la
/// réponse texte + audio (ElevenLabs, en base64) de l'assistant.
class VoiceSocketService {
  VoiceSocketService(this._storage);

  final SecureStorageService _storage;
  WebSocketChannel? _channel;
  final _eventsController = StreamController<VoiceSocketEvent>.broadcast();

  Stream<VoiceSocketEvent> get events => _eventsController.stream;

  Future<void> connect() async {
    await disconnect();
    final token = await _storage.accessToken;
    final uri = Uri.parse('${AppConfig.wsBaseUrl}/voice/ws').replace(
      queryParameters: {'token': token ?? ''},
    );

    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      _handleMessage,
      onError: (error) => _eventsController.add(VoiceSocketEvent.error(error.toString())),
      onDone: () {},
    );
  }

  void _handleMessage(dynamic raw) {
    try {
      final message = jsonDecode(raw as String) as Map<String, dynamic>;

      switch (message['type']) {
        case 'assistant_text':
          _eventsController.add(VoiceSocketEvent.assistantText(message['text'] as String));
          break;
        case 'assistant_audio':
          final bytes = base64Decode(message['audio_base64'] as String);
          _eventsController.add(VoiceSocketEvent.assistantAudio(bytes));
          break;
        case 'assistant_audio_unavailable':
          _eventsController.add(VoiceSocketEvent.audioUnavailable());
          break;
        case 'cancelled':
          _eventsController.add(VoiceSocketEvent.cancelled());
          break;
        case 'error':
          _eventsController.add(VoiceSocketEvent.error(message['detail'] as String? ?? 'Erreur inconnue'));
          break;
      }
    } catch (error) {
      _eventsController.add(VoiceSocketEvent.error('Réponse vocale invalide : $error'));
    }
  }

  void sendUserText(String text, {String language = 'fr'}) {
    _channel?.sink.add(jsonEncode({'type': 'user_text', 'text': text, 'language': language}));
  }

  /// Annule le tour de conversation en cours côté backend (ex : l'utilisateur
  /// recommence à parler pendant que Jarvis répond encore).
  void cancelCurrentTurn() {
    _channel?.sink.add(jsonEncode({'type': 'cancel'}));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _eventsController.close();
  }
}
