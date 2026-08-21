import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';

void main() {
  testWidgets('when the current-location button is shown, it should display its localized location guidance', (
    tester,
  ) async {
    final i18n = AppLocale.ptBr.buildSync();
    await tester.pumpWidget(
      TestApp(
        providerOverrides: [translationProvider.overrideWithValue(i18n)],
        child: const UseCurrentLocationButton(),
      ),
    );

    expect(
      (
        find.text(i18n.createJob.location.currentLocationTitle).evaluate().length,
        find.text(i18n.createJob.location.locationPermissionGuidance).evaluate().length,
      ),
      (1, 1),
    );
  });

  testWidgets('when the current-location button is shown in dark mode, it should report the unsupported theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) => Theme(
            data: Theme.of(context).copyWith(brightness: Brightness.dark),
            child: const UseCurrentLocationButton(),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      isA<UnsupportedError>().having(
        (error) => error.message,
        'message',
        'CurrentLocationButton does not support dark mode.',
      ),
    );
  });
}
