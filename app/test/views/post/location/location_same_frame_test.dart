import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../../utils/test_app.dart';
import 'post_location_test_helpers.dart';

void main() {
  testWidgets('when location slides into the safe area, it should paint content at its corrected position each frame', (
    tester,
  ) async {
    await PostLocationTestHelpers.pumpPost(tester, disableAnimations: false, keyboardInset: 300);
    final app = tester.widget<TestApp>(find.byType(TestApp));
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('route_capture'), child: app));
    await tester.pumpAndSettle();
    final theme = MateoTheme.of(tester.element(find.byKey(const ValueKey('post_location_chip'))));
    final color = theme.palette.red[9].toARGB32() & 0xffffff;
    final inputColor = theme.palette.neutral[2].toARGB32() & 0xffffff;
    await tester.tap(find.byKey(const ValueKey('post_location_chip')));
    await tester.pump();
    final errors = <double>[];
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      // The indicator fades in during the early entrance. Inspect every frame
      // through safe-area contact and settling after that fade has completed.
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('route_capture')));
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          if (frame < 11) return;
          final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          final rows = <int>[];
          int? headerBottom;
          for (var y = 30; y < 250; y++) {
            final index = (y * image.width + 42) * 4;
            final rgb = bytes.getUint8(index) << 16 | bytes.getUint8(index + 1) << 8 | bytes.getUint8(index + 2);
            if (rgb == color) rows.add(y);
            final headerIndex = (y * image.width + 180) * 4;
            final headerRgb =
                bytes.getUint8(headerIndex) << 16 |
                bytes.getUint8(headerIndex + 1) << 8 |
                bytes.getUint8(headerIndex + 2);
            if (headerRgb == inputColor) headerBottom = y + 1;
          }
          if (rows.isEmpty || rows.last == 249) return;
          expect(headerBottom, isNotNull);
          errors.add((rows.first + rows.last + 1) / 2 - headerBottom!);
        } finally {
          image.dispose();
        }
      });
    }
    await tester.pumpWidget(const SizedBox());
    expect(errors, isNotEmpty);
    expect(
      errors,
      everyElement(closeTo(errors.last, 1)),
      reason: 'The rasterized indicator must retain its settled offset from current-frame corrected geometry',
    );
  });
}
