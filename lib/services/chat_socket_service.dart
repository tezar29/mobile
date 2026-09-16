import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config/app_config.dart';
import 'secure_storage_service.dart';

class ChatSocketMessage {
  const ChatSocketMessage._({required this.type, this.text, this.agent, this.errorDetail});

  factory ChatSocketMessage.assistant(String text, String? agent) =>
      ChatSocketMessage._(type: 'assistant_message', text: text, agent: agent);

  factory ChatSocketMessage.error(String detail) =>
      ChatSocketMessage._(type: 'error', errorDetail: detail);

  final String type;
  final String? text;
  final String? agent;
  final String? errorDetail;
}

/// Connexion temps réel vers `/api/v1/chat/ws` — pendant mobile texte
/// du module vocal, branchée sur le même orchestrateur multi-agent
/// côté backend (voir voice_socket_service.dart pour le pendant vocal).
class ChatSocketService {
  ChatSocketService(this._storage);

  final SecureStorageService _storage;
  WebSocketChannel? _channel;
  final _messagesController = StreamController<ChatSocketMessage>.broadcast();

  Stream<ChatSocketMessage> get messages => _messagesController.stream;

  Future<void> connect() async {
    await disconnect();
    final token = await _storage.accessToken;
    final uri = Uri.parse('${AppConfig.wsBaseUrl}/chat/ws').replace(
      queryParameters: {'token': token ?? ''},
    );

    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      _handleMessage,
      onError: (error) => _messagesController.add(ChatSocketMessage.error(error.toString())),
      onDone: () {},
    );
  }

  void _handleMessage(dynamic raw) {
    try {
      final message = jsonDecode(raw as String) as Map<String, dynamic>;

      switch (message['type']) {
        case 'assistant_message':
          _messagesController.add(
            ChatSocketMessage.assistant(message['text'] as String, message['agent'] as String?),
          );
          break;
        case 'error':
          _messagesController.add(ChatSocketMessage.error(message['detail'] as String? ?? 'Erreur inconnue'));
          break;
      }
    } catch (error) {
      _messagesController.add(ChatSocketMessage.error('Réponse serveur invalide : $error'));
    }
  }

  void sendMessage(String text) {
    _channel?.sink.add(jsonEncode({'type': 'user_message', 'text': text}));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _messagesController.close();
  }
}
