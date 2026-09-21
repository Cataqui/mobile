import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/views/add_contact/add_contact_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      for (final scenario in [
        (name: 'empty', width: 390.0, keyboard: 0.0, text: '', scale: 1.0),
        (name: 'keyboard', width: 390.0, keyboard: 300.0, text: '', scale: 1.0),
        (name: 'populated', width: 390.0, keyboard: 300.0, text: '+5511912345678', scale: 1.0),
        (name: 'narrow_large_text', width: 320.0, keyboard: 300.0, text: '', scale: 1.5),
      ]) {
        goldenTest(
          'Add contact renders ${scenario.name}',
          fileName: 'add_contact_${scenario.name}',
          constraints: BoxConstraints.tightFor(width: scenario.width, height: 844),
          builder: () => TestApp.screen(
            mediaQueryData: MediaQueryData(
              size: Size(scenario.width, 844),
              padding: const EdgeInsets.only(top: 47, bottom: 34),
              viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
              viewInsets: EdgeInsets.only(bottom: scenario.keyboard),
              textScaler: TextScaler.linear(scenario.scale),
            ),
            child: const AddContactView(),
          ),
          whilePerforming: (tester) async {
            await tester.pumpAndSettle();
            if (scenario.text.isNotEmpty) {
              await tester.enterText(find.byType(EditableText), scenario.text);
              await tester.pump();
            }
            return null;
          },
        );
      }
    },
  );
}
