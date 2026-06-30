import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import '../test_app.dart';

void main() {
  late List<MethodCall> hapticCalls;

  setUp(() {
    hapticCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        hapticCalls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  group('QuiViewBackButton', () {
    testWidgets('when tapped, it should invoke the onPressed callback', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(TestApp(child: QuiViewBackButton(onPressed: () => tapCount += 1)));

      await tester.tap(find.byType(QuiViewBackButton));
      await tester.pump();

      expect(tapCount, equals(1));
    });

    testWidgets('when rendered with the default label, it should expose go back semantics', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiViewBackButton(onPressed: () {})));

      final semantics = tester.widget<Semantics>(find.byKey(const Key('qui_view_back_button_semantics')));

      expect(semantics.properties.label, equals('Go back'));
    });

    testWidgets('when rendered with a custom label, it should expose the custom semantics label', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiViewBackButton(semanticLabel: 'Voltar', onPressed: () {}),
        ),
      );

      final semantics = tester.widget<Semantics>(find.byKey(const Key('qui_view_back_button_semantics')));

      expect(semantics.properties.label, equals('Voltar'));
    });

    testWidgets('when rendered, it should render the fixed tap target size of 53', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiViewBackButton(onPressed: () {})));

      expect(tester.getSize(find.byKey(const Key('qui_view_back_button_tap_target'))), equals(const Size.square(53)));
    });

    testWidgets('when rendered, it should render the fixed icon box size of 22', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiViewBackButton(onPressed: () {})));

      expect(tester.getSize(find.byKey(const Key('qui_view_back_button_icon_box'))), equals(const Size.square(22)));
    });

    testWidgets('when tapped, it should trigger a light impact haptic feedback', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiViewBackButton(onPressed: () {})));

      await tester.tap(find.byType(QuiViewBackButton));
      await tester.pump();

      expect(
        hapticCalls.any(
          (call) => call.method == 'HapticFeedback.vibrate' && call.arguments == 'HapticFeedbackType.lightImpact',
        ),
        isTrue,
      );
    });
  });
}
