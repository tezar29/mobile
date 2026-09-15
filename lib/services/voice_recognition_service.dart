import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/config/app_config.dart';

/// Reconnaissance vocale 100% locale (rapide, fonctionne même en
/// coupure réseau partielle) — utilisée pour deux choses :
/// - l'écoute passive du mot-clé "Jarvis" (wake-word) ;
/// - la capture de la commande complète une fois le mot-clé détecté.
///
/// Note : `speech_to_text` s'appuie sur les moteurs natifs
/// (Android SpeechRecognizer / iOS Speech framework) plutôt que sur
/// un modèle wake-word dédié comme Porcupine — suffisant pour ce
/// scaffold, mais consomme un peu plus de batterie en écoute continue.
/// À évaluer en usage réel : bascule possible vers Porcupine si besoin.
class VoiceRecognitionService {
  VoiceRecognitionService() : _speech = stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _isInitialized = false;

  Future<bool> init() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return false;

    _isInitialized = await _speech.initialize(
      onError: (error) => _lastError = error.errorMsg,
      onStatus: (_) {},
    );
    return _isInitialized;
  }

  String? _lastError;
  String? get lastError => _lastError;

  bool get isListening => _speech.isListening;

  /// Écoute en continu jusqu'à détecter le mot-clé configuré
  /// (`AppConfig.wakeWord`, par défaut "jarvis") dans les résultats
  /// partiels, puis déclenche [onWakeWordDetected].
  Future<void> startWakeWordListening({
    required void Function() onWakeWordDetected,
    String localeId = 'fr_FR',
  }) async {
    if (!_isInitialized) return;

    await _speech.listen(
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(partialResults: true, cancelOnError: false),
      onResult: (result) {
        final heard = result.recognizedWords.toLowerCase();
        if (heard.contains(AppConfig.wakeWord)) {
          _speech.stop();
          onWakeWordDetected();
        }
      },
    );
  }

  /// Capture une commande complète (après détection du wake-word) et
  /// renvoie le texte final via [onFinalResult] une fois l'utilisateur
  /// silencieux pendant la durée de pause configurée.
  Future<void> startCommandListening({
    required void Function(String text) onFinalResult,
    void Function(String partialText)? onPartialResult,
    String localeId = 'fr_FR',
  }) async {
    if (!_isInitialized) return;

    await _speech.listen(
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(partialResults: true),
      onResult: (result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult?.call(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
