import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when the app restarts, it should reload the persisted Cloudflare visitor cookie', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp('cataqui_api_cookie_test_');
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final requestUri = Uri.parse('https://api.cataqui.com/v1/feed');

    final firstCookieJar = PersistCookieJar(storage: FileStorage(temporaryDirectory.path));
    await firstCookieJar.saveFromResponse(requestUri, <Cookie>[
      Cookie('_cfuvid', 'opaque-cloudflare-value')..maxAge = 1800,
    ]);

    final restartedCookieJar = PersistCookieJar(storage: FileStorage(temporaryDirectory.path));
    final cookiesAfterRestart = await restartedCookieJar.loadForRequest(requestUri);

    expect(cookiesAfterRestart.map((cookie) => (cookie.name, cookie.value)), <(String, String)>[
      ('_cfuvid', 'opaque-cloudflare-value'),
    ]);
  });
}
