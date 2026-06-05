import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:qui/src/theme/qui_theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isRunningInCi = Platform.environment['CI'] == 'true';

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isRunningInCi),
    ),
    run: testMain,
  );
}
