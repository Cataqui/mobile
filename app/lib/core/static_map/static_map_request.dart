import 'package:cataqui_app/core/static_map/enums/static_map_size.dart';

final class StaticMapRequest {
  const StaticMapRequest({required this.imageUrl, required this.size});

  final String imageUrl;
  final StaticMapSize size;

  String get url =>
      Uri.parse(imageUrl).replace(queryParameters: {'size': size.logicalSize, 'scale': '2', 'zoom': '13'}).toString();

  String get cacheKey => url;
}
