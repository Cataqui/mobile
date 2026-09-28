import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

abstract final class JobMapWarmup {
  static Future<void> run() async {
    if (defaultTargetPlatform != .android) return;
    final mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is! GoogleMapsFlutterAndroid) return;
    try {
      await mapsImplementation.warmup();
    } on Object {
      // The first map can still initialize through the normal path.
    }
  }
}
