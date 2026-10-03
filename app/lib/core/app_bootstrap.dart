import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/me/me_state.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class AppBootstrap {
  static Future<void> setup({required ProviderContainer providerContainer}) async {
    PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;
    providerContainer.listen(meStateProvider, (_, _) {});
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Block until essential providers are loaded (fail-fatal on error).
    await Future.wait([
      providerContainer.read(appStorageStateProvider.future),
      providerContainer.read(cataquiApiCookieJarProvider.future),
    ]);

    final appAuthState = providerContainer.read(appAuthStateProvider.notifier);
    if (appAuthState.hasUsableLocalCredentials) {
      unawaited(appAuthState.refreshSessionInBackground());
    }

    // Fire-and-forget: start the feed network fetch early so it's already
    // in-flight (or completed) when the feed screen mounts.
    providerContainer.read(feedStateProvider);
  }
}
