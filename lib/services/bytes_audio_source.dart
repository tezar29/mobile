import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Permet à just_audio de lire directement un buffer MP3 reçu du
/// backend (base64 décodé) sans passer par un fichier temporaire.
class BytesAudioSource extends StreamAudioSource {
  BytesAudioSource(this._bytes) : super(tag: 'jarvis-voice-response');

  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
