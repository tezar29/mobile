/// Configuration statique de l'app. En production, ces valeurs viendront
/// de `--dart-define` (build CI) plutôt que d'être codées en dur.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.27.65:8000/api/v1', // 10.0.2.2 = localhost depuis l'émulateur Android
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://192.168.27.65:8000/api/v1',
  );

  static const String wakeWord = 'jarvis';
}
