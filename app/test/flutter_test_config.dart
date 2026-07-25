import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:test_api/scaffolding.dart' as test_package;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  (binding as dynamic).defaultTestTimeout = const test_package.Timeout(Duration(seconds: 10));

  final isRunningInCi = Platform.environment['CI'] == 'true';
  await _loadMateoFonts();

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: MateoTheme.light(primaryColor: const Color(0xFFFF4A4B), onPrimary: const Color(0xFFFFFFFF)),
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isRunningInCi, theme: MateoTheme.light()),
      ciGoldensConfig: CiGoldensConfig(diffThreshold: isRunningInCi ? 0.03 : 0),
    ),
    run: testMain,
  );
}

Future<ByteData> _loadFontAsset(String path) async {
  try {
    return await rootBundle.load('packages/mateo_mobile/assets/fonts/$path');
  } catch (_) {
    return rootBundle.load('assets/fonts/$path');
  }
}

Future<void> _loadMateoFonts() async {
  final interLoader = FontLoader(MateoTypography.fontFamily)
    ..addFont(_loadFontAsset('inter_variable.ttf'))
    ..addFont(_loadFontAsset('inter_italic.ttf'));

  await interLoader.load();
}
