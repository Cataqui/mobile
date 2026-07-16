import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import '../test_app.dart';

void main() {
  group('QuiToastType', () {
    testWidgets(
      'when type is error, it should resolve the default error background color',
      (tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final colors = QuiToastType.error.colors(capturedContext);

        expect(colors.background, equals(QuiColorScheme.light().toast.error.background));
      },
    );

    testWidgets(
      'when type is error, it should resolve the default error foreground color',
      (tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final colors = QuiToastType.error.colors(capturedContext);

        expect(colors.foreground, equals(QuiColorScheme.light().toast.error.foreground));
      },
    );

    testWidgets(
      'when type is error, it should resolve the default error icon color',
      (tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final colors = QuiToastType.error.colors(capturedContext);

        expect(colors.icon, equals(QuiColorScheme.light().toast.error.icon));
      },
    );
  });
}
