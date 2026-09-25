import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/widgets/logout_warning_sheet/logout_warning_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';
import 'logout_warning_sheet_test_host.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () => goldenTest(
      'when opened, the logout warning sheet matches the reference layout',
      fileName: 'logout_warning_sheet',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(LogoutWarningSheetTestHost.openButtonKey));
        await tester.pumpAndSettle();
        expect(find.byType(LogoutWarningSheet), findsOneWidget);
        return null;
      },
      builder: () => const TestApp.screen(
        mediaQueryData: MediaQueryData(size: Size(390, 844), disableAnimations: true),
        child: LogoutWarningSheetTestHost(),
      ),
    ),
  );
}
