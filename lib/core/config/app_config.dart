/// Configuration statique de l'app. En production, ces valeurs viendront
/// de `--dart-define` (build CI) plutôt que d'être codées en dur.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jarvis-backend.onrender.com/api/v1',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://jarvis-backend.onrender.com/api/v1',
  );

  static const String wakeWord = 'jarvis';
}
