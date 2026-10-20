import 'package:cataqui_app/core/static_map/enums/static_map_size.dart';
import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = 'https://maps.cataqui.com/static/v1/opaque_reference.webp';
  for (final (size, value) in const [(StaticMapSize.square, '480x480'), (StaticMapSize.tall, '480x1280')]) {
    test('when requesting ${size.value}, it should add only the size query parameter', () {
      expect(StaticMapRequest.forSize(imageUrl: base, size: size)!.url, '$base?size=$value');
    });
    test('when caching ${size.value}, it should use the complete image URL as its key', () {
      final request = StaticMapRequest.forSize(imageUrl: base, size: size)!;
      expect(request.cacheKey, request.url);
    });
  }
  for (final url in [
    '',
    'http://maps.cataqui.com/static/v1/ref.webp',
    'https://user@maps.cataqui.com/static/v1/ref.webp',
    '$base?size=480x480',
    '$base#fragment',
    'https://maps.cataqui.com/static/v2/ref.webp',
    'https://maps.cataqui.com/static/v1/ref',
    'https://maps.cataqui.com/static/v1/ref.signature.webp',
    '$base/extra',
  ]) {
    test('when the base URL is invalid ($url), it should reject the request', () {
      expect(StaticMapRequest.forSize(imageUrl: url, size: .square), isNull);
    });
  }
}
