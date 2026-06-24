import 'package:cataqui_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await setOfflineMaxConcurrentRequests(maxRequestsPerHost: 8);
  } catch (_) {
    // Best-effort optimization — map still works with default 5 per-host.
  }
  runApp(const ProviderScope(child: CataquiApp()));
}
