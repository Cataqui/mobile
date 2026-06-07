import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/gen/fonts.gen.dart';
import 'package:qui/src/theme/qui_theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

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

Future<void> _loadQuiFonts() async {
  final interLoader = FontLoader(FontFamily.inter)
    ..addFont(rootBundle.load('packages/qui/assets/fonts/inter_variable.ttf'))
    ..addFont(rootBundle.load('packages/qui/assets/fonts/inter_italic.ttf'));

  await interLoader.load();
}
