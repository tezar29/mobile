import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/chat_socket_service.dart';
import 'service_providers.dart';

class ChatMessageItem {
  const ChatMessageItem({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class ChatState {
  const ChatState({this.messages = const [], this.connected = false, this.errorMessage});

  final List<ChatMessageItem> messages;
  final bool connected;
  final String? errorMessage;

  ChatState copyWith({List<ChatMessageItem>? messages, bool? connected, String? errorMessage}) {
    return ChatState(
      messages: messages ?? this.messages,
      connected: connected ?? this.connected,
      errorMessage: errorMessage,
    );
  }
}

/// Gère la connexion WebSocket du chat texte et l'historique affiché à
/// l'écran — branché sur le même orchestrateur multi-agent que le
/// module vocal (voir voice_provider.dart), simplement sans synthèse
/// vocale de la réponse.
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._socket) : super(const ChatState()) {
    _socket.messages.listen(_onMessage);
  }

  final ChatSocketService _socket;

  Future<void> connect() async {
    await _socket.connect();
    state = state.copyWith(connected: true);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    state = state.copyWith(messages: [...state.messages, ChatMessageItem(text: text, isUser: true)]);
    _socket.sendMessage(text);
  }

  void _onMessage(ChatSocketMessage message) {
    if (message.type == 'assistant_message') {
      state = state.copyWith(
        messages: [...state.messages, ChatMessageItem(text: message.text ?? '', isUser: false)],
      );
    } else if (message.type == 'error') {
      state = state.copyWith(errorMessage: message.errorDetail);
    }
  }

  Future<void> disconnect() async {
    await _socket.disconnect();
    state = state.copyWith(connected: false);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(chatSocketServiceProvider));
});
