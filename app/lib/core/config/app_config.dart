final class AppConfig {
  const AppConfig({required this.environment, required this.cataquiApiUrl});

  final String environment;
  final String cataquiApiUrl;

  bool get isDevelopment => environment == 'development';
}
