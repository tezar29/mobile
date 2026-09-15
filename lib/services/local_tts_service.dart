import 'package:flutter_tts/flutter_tts.dart';

/// Synthèse vocale locale (voix système). Utilisée comme repli quand
/// le backend ne peut pas fournir d'audio ElevenLabs (clé absente,
/// service indisponible, hors-ligne).
class LocalTtsService {
  LocalTtsService() : _tts = FlutterTts();

  final FlutterTts _tts;

  Future<void> setLanguage(String languageCode) => _tts.setLanguage(languageCode);

  Future<void> speak(String text) => _tts.speak(text);

  Future<void> stop() => _tts.stop();
}
