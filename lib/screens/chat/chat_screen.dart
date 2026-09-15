import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/holographic/glow_container.dart';
import '../../widgets/holographic/holo_background.dart';

/// Écran de conversation texte — branché sur `/api/v1/chat/ws`, qui
/// partage le même orchestrateur multi-agent que le module vocal
/// (voir chat_provider.dart et backend `app/ai/orchestrator.py`).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).connect());
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).disconnect();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: HoloBackground(
        child: SafeArea(
        child: Column(
          children: [
            if (chatState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(chatState.errorMessage!, style: const TextStyle(color: AppColors.danger)),
              ),
            Expanded(
              child: chatState.messages.isEmpty
                  ? const Center(
                      child: Text('Écrivez à Jarvis pour démarrer la conversation.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatState.messages[index];
                        return Align(
                          alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: GlowContainer(
                              glowIntensity: message.isUser ? 0.15 : 0.35,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Text(message.text),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Écrivez à Jarvis...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primaryGlow),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
