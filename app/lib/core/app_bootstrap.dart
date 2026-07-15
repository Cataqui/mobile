import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

abstract final class AppBootstrap {
  static Future<void> setup() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    try {
      await setOfflineMaxConcurrentRequests(maxRequestsPerHost: 8);
    } catch (_) {
      // Best-effort optimization — map still works with default 5 per-host.
    }
  }
}
