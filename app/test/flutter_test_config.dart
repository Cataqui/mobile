import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final isRunningInCi = Platform.environment['CI'] == 'true';

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
