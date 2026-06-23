import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/gen/fonts.gen.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:test_api/scaffolding.dart' as test_package;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  (binding as dynamic).defaultTestTimeout = const test_package.Timeout(Duration(seconds: 10));

  final isRunningInCi = Platform.environment['CI'] == 'true';
  await _loadQuiFonts();

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: !isRunningInCi,
        theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      ),
    ),
    run: testMain,
  );
}

Future<ByteData> _loadFontAsset(String path) async {
  try {
    return await rootBundle.load('packages/qui/assets/fonts/$path');
  } catch (_) {
    return rootBundle.load('assets/fonts/$path');
  }
}

Future<void> _loadQuiFonts() async {
  final interLoader = FontLoader(FontFamily.inter)
    ..addFont(_loadFontAsset('inter_variable.ttf'))
    ..addFont(_loadFontAsset('inter_italic.ttf'));

  await interLoader.load();
}
