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
  bool _wakeWordListening = false;
  String _wakeLocale = 'fr_FR';
  void Function()? _onWakeWordDetected;

  Future<bool> init() async {
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }
    if (!micStatus.isGranted) {
      _lastError = micStatus.isPermanentlyDenied
          ? 'Accès au micro bloqué. Autorisez le micro dans les réglages de l’application.'
          : 'Autorisation du micro refusée.';
      return false;
    }

    _isInitialized = await _speech.initialize(
      onError: (error) => _lastError = error.errorMsg,
      onStatus: _handleStatus,
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

    _wakeWordListening = true;
    _wakeLocale = localeId;
    _onWakeWordDetected = onWakeWordDetected;
    await _listenForWakeWord();
  }

  Future<void> _listenForWakeWord() async {
    if (!_isInitialized || !_wakeWordListening || _speech.isListening) return;

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _wakeLocale,
        partialResults: true,
        cancelOnError: false,
      ),
      onResult: (result) {
        final heard = result.recognizedWords.toLowerCase();
        if (heard.contains(AppConfig.wakeWord)) {
          _wakeWordListening = false;
          _speech.stop();
          final callback = _onWakeWordDetected;
          _onWakeWordDetected = null;
          callback?.call();
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

    _wakeWordListening = false;
    _onWakeWordDetected = null;
    await _speech.stop();

    var finalResultDelivered = false;
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: localeId, partialResults: true),
      onResult: (result) {
        if (result.finalResult && !finalResultDelivered) {
          finalResultDelivered = true;
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult?.call(result.recognizedWords);
        }
      },
    );
  }

  void _handleStatus(String status) {
    if (!_wakeWordListening || (status != 'done' && status != 'notListening')) return;
    Future<void>.delayed(const Duration(milliseconds: 250), _listenForWakeWord);
  }

  Future<void> stop() async {
    _wakeWordListening = false;
    _onWakeWordDetected = null;
    await _speech.stop();
  }

  Future<void> cancel() async {
    _wakeWordListening = false;
    _onWakeWordDetected = null;
    await _speech.cancel();
  }
}
