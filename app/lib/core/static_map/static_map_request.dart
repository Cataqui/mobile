import 'package:cataqui_app/core/static_map/enums/static_map_size.dart';

final class StaticMapRequest {
  const StaticMapRequest._({required this.url, required this.size});
  final String url;
  final StaticMapSize size;
  String get cacheKey => url;
  static StaticMapRequest? forSize({required String imageUrl, required StaticMapSize size}) {
    final base = Uri.tryParse(imageUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      return null;
    }
    final segments = base.pathSegments;
    if (segments.length != 3 ||
        segments[0] != 'static' ||
        segments[1] != 'v1' ||
        !RegExp(r'^[A-Za-z0-9_-]+\.webp$').hasMatch(segments[2])) {
      return null;
    }
    return StaticMapRequest._(
      url: base.replace(queryParameters: {'size': size.value}).toString(),
      size: size,
    );
  }
}
