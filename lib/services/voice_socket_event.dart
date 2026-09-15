import 'dart:typed_data';

enum VoiceSocketEventType { assistantText, assistantAudio, audioUnavailable, cancelled, error }

class VoiceSocketEvent {
  const VoiceSocketEvent._(this.type, {this.text, this.audioBytes, this.errorDetail});

  factory VoiceSocketEvent.assistantText(String text) =>
      VoiceSocketEvent._(VoiceSocketEventType.assistantText, text: text);

  factory VoiceSocketEvent.assistantAudio(Uint8List bytes) =>
      VoiceSocketEvent._(VoiceSocketEventType.assistantAudio, audioBytes: bytes);

  factory VoiceSocketEvent.audioUnavailable() =>
      const VoiceSocketEvent._(VoiceSocketEventType.audioUnavailable);

  factory VoiceSocketEvent.cancelled() => const VoiceSocketEvent._(VoiceSocketEventType.cancelled);

  factory VoiceSocketEvent.error(String detail) =>
      VoiceSocketEvent._(VoiceSocketEventType.error, errorDetail: detail);

  final VoiceSocketEventType type;
  final String? text;
  final Uint8List? audioBytes;
  final String? errorDetail;
}
