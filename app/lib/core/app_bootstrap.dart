import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

abstract final class AppBootstrap {
  static Future<void> setup({required ProviderContainer providerContainer}) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    await Future.wait([_warmUpGoogleMaps(), Future<String>.value(JobLocationMapStyle.googleMapsJson)]);

    // Block until essential providers are loaded (fail-fatal on error).
    await Future.wait([
      providerContainer.read(appStorageStateProvider.future),
      providerContainer.read(cataquiApiCookieJarProvider.future),
    ]);

    // Fire-and-forget: start the feed network fetch early so it's already
    // in-flight (or completed) when the feed screen mounts.
    providerContainer.read(feedStateProvider);
  }

  static Future<void> _warmUpGoogleMaps() async {
    // Only android supports it from flutter. iOS is warming up directly in native code
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is! GoogleMapsFlutterAndroid) return;

    try {
      await mapsImplementation.warmup();
    } catch (_) {
      // Best effort: the first map can still initialize through the normal path.
    }
  }
}
