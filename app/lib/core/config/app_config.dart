final class AppConfig {
  const AppConfig({required this.environment});

  final String environment;

  String get cataquiApiUrl => switch (environment) {
    'development' => 'https://staging.api.cataqui.com',
    'production' => 'https://api.cataqui.com',
    _ => throw StateError('Unsupported app environment: $environment.'),
  };

  bool get isDevelopment => environment == 'development';
}
