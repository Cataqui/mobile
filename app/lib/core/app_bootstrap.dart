import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

abstract final class AppBootstrap {
  static Future<void> setup({required ProviderContainer providerContainer}) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    try {
      await setOfflineMaxConcurrentRequests(maxRequestsPerHost: 8);
    } catch (_) {
      // Best-effort optimization — map still works with default 5 per-host.
    }

    // Block until essential providers are loaded (fail-fatal on error).
    await providerContainer.read(appStorageStateProvider.future);

    // Fire-and-forget: start the feed network fetch early so it's already
    // in-flight (or completed) when the feed screen mounts.
    providerContainer.read(feedStateProvider);
  }
}
