import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when selecting a tall image, should request the prepared tall variant', () {
    const request = StaticMapRequest(imageUrl: 'https://maps.test/static/asset', size: .pixels960x2560);
    expect(request.url, 'https://maps.test/static/asset?size=480x1280&scale=2&zoom=13');
  });
  test('when selecting a square image, should request the prepared square variant', () {
    const request = StaticMapRequest(imageUrl: 'https://maps.test/static/asset', size: .pixels960x960);
    expect(request.url, 'https://maps.test/static/asset?size=480x480&scale=2&zoom=13');
  });
  test('when caching variants of one asset, should use distinct complete URLs', () {
    const square = StaticMapRequest(imageUrl: 'https://maps.test/static/asset', size: .pixels960x960);
    const tall = StaticMapRequest(imageUrl: 'https://maps.test/static/asset', size: .pixels960x2560);
    expect(
      (square.cacheKey == square.url, tall.cacheKey == tall.url, square.cacheKey == tall.cacheKey),
      (true, true, false),
    );
  });
}
