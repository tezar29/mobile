import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../services/bytes_audio_source.dart';
import '../services/local_tts_service.dart';
import '../services/voice_recognition_service.dart';
import '../services/voice_socket_event.dart';
import '../services/voice_socket_service.dart';
import 'service_providers.dart';

enum VoiceStatus { idle, wakeListening, listening, processing, speaking, error }

class VoiceState {
  const VoiceState({
    this.status = VoiceStatus.idle,
    this.transcript = '',
    this.responseText = '',
    this.errorMessage,
  });

  final VoiceStatus status;
  final String transcript;
  final String responseText;
  final String? errorMessage;

  static const Object _unset = Object();

  VoiceState copyWith({
    VoiceStatus? status,
    String? transcript,
    String? responseText,
    Object? errorMessage = _unset,
  }) {
    return VoiceState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      responseText: responseText ?? this.responseText,
      errorMessage: identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
    );
  }
}

/// Orchestre le cycle complet du module vocal :
/// mot-clé "Jarvis" → capture de la commande → envoi au backend →
/// réception de la réponse (texte + audio ElevenLabs, ou repli TTS local)
/// → retour automatique en écoute passive.
class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier(this._recognition, this._localTts, this._socket) : super(const VoiceState()) {
    _socket.events.listen(_onSocketEvent);
  }

  final VoiceRecognitionService _recognition;
  final LocalTtsService _localTts;
  final VoiceSocketService _socket;
  final AudioPlayer _player = AudioPlayer();

  String _language = 'fr_FR';

  /// Active le module vocal : initialise le micro, connecte le WebSocket,
  /// puis démarre l'écoute passive du mot-clé.
  Future<void> activate({String language = 'fr_FR'}) async {
    _language = language;
    try {
      final ready = await _recognition.init();
      if (!ready) {
        state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: _recognition.lastError ?? 'Impossible d’accéder au micro.',
        );
        return;
      }
      await _socket.connect();
      await _listenForWakeWord();
    } catch (error) {
      state = state.copyWith(status: VoiceStatus.error, errorMessage: 'Connexion vocale impossible : $error');
    }
  }

  Future<void> _listenForWakeWord() async {
    state = state.copyWith(status: VoiceStatus.wakeListening, transcript: '', responseText: '');
    await _recognition.startWakeWordListening(
      localeId: _language,
      onWakeWordDetected: _startCommandCapture,
    );
  }

  Future<void> _startCommandCapture() async {
    state = state.copyWith(status: VoiceStatus.listening);
    await _recognition.startCommandListening(
      localeId: _language,
      onPartialResult: (partial) => state = state.copyWith(transcript: partial),
      onFinalResult: (finalText) {
        state = state.copyWith(transcript: finalText, status: VoiceStatus.processing);
        _socket.sendUserText(finalText, language: _language.split('_').first);
      },
    );
  }

  void _onSocketEvent(VoiceSocketEvent event) {
    switch (event.type) {
      case VoiceSocketEventType.assistantText:
        state = state.copyWith(responseText: event.text ?? '');
        break;
      case VoiceSocketEventType.assistantAudio:
        state = state.copyWith(status: VoiceStatus.speaking);
        _playAudio(event.audioBytes!);
        break;
      case VoiceSocketEventType.audioUnavailable:
        state = state.copyWith(status: VoiceStatus.speaking);
        _speakLocally(state.responseText);
        break;
      case VoiceSocketEventType.cancelled:
        _listenForWakeWord();
        break;
      case VoiceSocketEventType.error:
        state = state.copyWith(status: VoiceStatus.error, errorMessage: event.errorDetail);
        break;
    }
  }

  Future<void> _playAudio(Uint8List bytes) async {
    try {
      await _player.setAudioSource(BytesAudioSource(bytes));
      await _player.play();
      _player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          _listenForWakeWord();
        }
      });
    } catch (_) {
      await _speakLocally(state.responseText);
    }
  }

  Future<void> _speakLocally(String text) async {
    await _localTts.setLanguage(_language.replaceAll('_', '-'));
    await _localTts.speak(text);
    await _listenForWakeWord();
  }

  /// Interrompt tout (écoute, lecture audio, tour backend en cours) —
  /// utilisé par le bouton d'annulation de l'UI.
  Future<void> cancel() async {
    _socket.cancelCurrentTurn();
    await _recognition.cancel();
    await _player.stop();
    await _localTts.stop();
    state = state.copyWith(status: VoiceStatus.idle, errorMessage: null);
  }

  Future<void> deactivate() async {
    await _recognition.stop();
    await _player.stop();
    await _localTts.stop();
    await _socket.disconnect();
    state = const VoiceState();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  return VoiceNotifier(
    ref.watch(voiceRecognitionServiceProvider),
    ref.watch(localTtsServiceProvider),
    ref.watch(voiceSocketServiceProvider),
  );
});
