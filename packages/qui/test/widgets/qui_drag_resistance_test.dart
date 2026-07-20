import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

dynamic _findResistanceTransformRenderObject(WidgetTester tester) {
  return tester.renderObject(find.byType(QuiDragResistance));
}

void main() {
  group('QuiDragResistance', () {
    testWidgets(
      'when dragging toward an enabled side, it should move with strong resistance',
      (tester) async {
        await _pumpResistanceApp(
          tester,
          top: false,
          bottom: false,
          left: false,
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(120, 0));
        await tester.pump();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(
          renderObject.currentResistanceOffset.dx,
          allOf(greaterThan(0), lessThan(6)),
        );
        await gesture.cancel();
      },
    );

    testWidgets(
      'when dragging toward a disabled side, it should keep the child at rest',
      (tester) async {
        await _pumpResistanceApp(
          tester,
          top: false,
          right: false,
          bottom: false,
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(120, 0));
        await tester.pump();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(renderObject.currentResistanceOffset, Offset.zero);
        await gesture.cancel();
      },
    );

    testWidgets(
      'when configuring a smaller offset, it should approach that configured limit',
      (tester) async {
        await _pumpResistanceApp(tester, offset: const Offset(3, 8));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(10000, 0));
        await tester.pump();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(
          renderObject.currentResistanceOffset.dx,
          allOf(greaterThan(2.9), lessThan(3)),
        );
        await gesture.cancel();
      },
    );

    testWidgets(
      'when configuring zero offset, it should bypass resistance gesture and compositing work',
      (tester) async {
        await _pumpResistanceApp(tester, offset: Offset.zero);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(120, 120));
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(QuiDragResistance),
            matching: find.byType(Listener),
          ),
          findsNothing,
        );
        await gesture.cancel();
      },
    );

    testWidgets(
      'when configuring zero for one offset axis, it should disable only that axis',
      (tester) async {
        await _pumpResistanceApp(tester, offset: const Offset(6, 0));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(120, 120));
        await tester.pump();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(
          renderObject.currentResistanceOffset,
          isA<Offset>()
              .having(
                (value) => value.dx,
                'horizontal resistance',
                greaterThan(0),
              )
              .having((value) => value.dy, 'vertical resistance', 0),
        );
        await gesture.cancel();
      },
    );

    testWidgets(
      'when releasing a resisted drag, it should ease the child back to rest',
      (tester) async {
        await _pumpResistanceApp(tester);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(120, 0));
        await gesture.up();
        await tester.pumpAndSettle();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(renderObject.currentResistanceOffset, Offset.zero);
      },
    );

    testWidgets(
      'when the pointer is cancelled during resistance, it should ease the child back to rest',
      (tester) async {
        await _pumpResistanceApp(tester);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(120, 0));
        await gesture.cancel();
        await tester.pumpAndSettle();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(renderObject.currentResistanceOffset, Offset.zero);
      },
    );

    testWidgets(
      'when reduced motion is enabled, it should bypass resistance gesture and compositing work',
      (tester) async {
        await _pumpResistanceApp(tester, disableAnimations: true);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(120, 0));
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(QuiDragResistance),
            matching: find.byType(Listener),
          ),
          findsNothing,
        );
        await gesture.cancel();
      },
    );

    testWidgets(
      'when wrapping a button, it should preserve the button tap action',
      (tester) async {
        var tapCount = 0;
        await _pumpResistanceApp(
          tester,
          child: FilledButton(
            key: _ResistanceTestApp.childKey,
            onPressed: () => tapCount += 1,
            child: const Text('Continue'),
          ),
        );
        await tester.tap(find.byKey(_ResistanceTestApp.childKey));
        await tester.pumpAndSettle();

        expect(tapCount, 1);
      },
    );

    testWidgets(
      'when dragging resisted content, it should move without repainting the child',
      (tester) async {
        var paintCount = 0;
        await _pumpResistanceApp(
          tester,
          child: CustomPaint(
            key: _ResistanceTestApp.childKey,
            size: const Size(120, 56),
            painter: _PaintCountingPainter(() => paintCount += 1),
          ),
        );
        final paintCountAtRest = paintCount;
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(120, 0));
        await tester.pump();

        expect(paintCount, paintCountAtRest);
        await gesture.cancel();
      },
    );

    testWidgets(
      'when a disabled direction is reversed before crossing the pointer origin, it should not resist early',
      (tester) async {
        await _pumpResistanceApp(
          tester,
          right: false,
          bottom: false,
          left: false,
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_ResistanceTestApp.childKey)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await gesture.moveBy(const Offset(0, -40));
        await tester.pump();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(renderObject.currentResistanceOffset, Offset.zero);
        await gesture.cancel();
      },
    );
  });
}

Future<void> _pumpResistanceApp(
  WidgetTester tester, {
  bool top = true,
  bool right = true,
  bool bottom = true,
  bool left = true,
  Offset offset = const Offset(6, 6),
  bool disableAnimations = false,
  Widget child = const SizedBox(
    key: _ResistanceTestApp.childKey,
    width: 120,
    height: 56,
  ),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: QuiDragResistance(
              top: top,
              right: right,
              bottom: bottom,
              left: left,
              offset: offset,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

abstract final class _ResistanceTestApp {
  static const childKey = Key('drag_resistance_child');
}

class _PaintCountingPainter extends CustomPainter {
  _PaintCountingPainter(this.onPaint);

  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) => onPaint();

  @override
  bool shouldRepaint(covariant _PaintCountingPainter oldDelegate) => false;
}
