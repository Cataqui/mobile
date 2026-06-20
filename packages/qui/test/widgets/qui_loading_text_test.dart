import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

/// Pumps a frame to flush flutter_animate's deferred startup timer.
///
/// [QuiLoadingText] uses flutter_animate's repeating shimmer, which defers
/// its initial animation start via `Future.delayed(Duration.zero)`.
/// In the test framework this timer only fires when clock advances past zero,
/// so we pump 1ms to drain it.
Future<void> pumpWithAnimation(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  group('QuiLoadingText', () {
    testWidgets('when provided with text, it should render the text', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: QuiLoadingText(text: 'Carregando...')),
      );
      await pumpWithAnimation(tester);

      expect(find.text('Carregando...'), findsOneWidget);
    });

    testWidgets('when rendered, it should show a CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: QuiLoadingText(text: 'Carregando...')),
      );
      await pumpWithAnimation(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('when rendered without custom color, it should resolve to primary', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: QuiLoadingText(text: 'Carregando...')),
      );
      await pumpWithAnimation(tester);

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(indicator.color, equals(const Color(0xFFFF4A4B)));
    });

    testWidgets('when given a custom progressIndicatorColor, it should use it', (tester) async {
      const customColor = Color(0xFF00A676);

      await tester.pumpWidget(
        const TestApp(
          child: QuiLoadingText(
            text: 'Buscando...',
            progressIndicatorColor: customColor,
          ),
        ),
      );
      await pumpWithAnimation(tester);

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(indicator.color, equals(customColor));
    });

    testWidgets('when animations are enabled, it should apply shimmer to the text', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: QuiLoadingText(text: 'Carregando...')),
      );
      await pumpWithAnimation(tester);

      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('when animations are disabled, it should not apply shimmer', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: QuiLoadingText(text: 'Carregando...'),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsNothing);
    });


  });
}
