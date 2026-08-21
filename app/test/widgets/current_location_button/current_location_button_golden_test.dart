import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when the current-location button is resting, it should match the approved appearance',
        fileName: 'current_location_button_resting',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        builder: () => Center(
          child: SizedBox(
            width: 350,
            child: ProviderScope(
              overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
              key: const ValueKey('current_location_button_golden'),
              child: const UseCurrentLocationButton(),
            ),
          ),
        ),
      );

      goldenTest(
        'when the current-location button is pressed, it should match the approved touch feedback',
        fileName: 'current_location_button_pressed',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        whilePerforming: press(find.byType(UseCurrentLocationButton), holdFor: const Duration(milliseconds: 150)),
        builder: () => Center(
          child: SizedBox(
            width: 350,
            child: ProviderScope(
              overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
              key: const ValueKey('current_location_button_golden'),
              child: const UseCurrentLocationButton(),
            ),
          ),
        ),
      );
    },
  );
}
