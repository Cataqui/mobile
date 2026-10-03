final class AppConfig {
  const AppConfig({required this.flavor});

  final String flavor;

  String get cataquiApiUrl => switch (flavor) {
    'development' => 'https://staging.api.cataqui.com',
    'production' => 'https://api.cataqui.com',
    _ => throw StateError('Unsupported app flavor: $flavor.'),
  };

  String get mapsUrl => switch (flavor) {
    'development' => 'https://staging.maps.cataqui.com',
    'production' => 'https://maps.cataqui.com',
    _ => throw StateError('Unsupported app flavor: $flavor.'),
  };

  bool get isDevelopment => flavor == 'development';
}
