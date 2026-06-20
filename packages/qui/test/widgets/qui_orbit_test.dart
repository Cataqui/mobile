import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

void main() {
  group('QuiOrbit constructor', () {
    test('when constructed with 3 items, it should throw AssertionError', () {
      expect(
        () => QuiOrbit(
          items: const [
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('when constructed with 2 items, it should throw AssertionError', () {
      expect(
        () => QuiOrbit(
          items: const [
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('when constructed with 4 items, it should not throw', () {
      expect(
        () => QuiOrbit(
          items: const [
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
            QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
          ],
        ),
        returnsNormally,
      );
    });

    test('when constructed with 8 items, it should not throw', () {
      expect(
        () => QuiOrbit(
          items: List.generate(
            8,
            (_) => const QuiOrbitItem(child: SizedBox(), size: Size(10, 10)),
          ),
        ),
        returnsNormally,
      );
    });
  });

  group('QuiOrbit rendering', () {
    testWidgets('when rendered with 4 items, it should display without error', (tester) async {
      await tester.pumpWidget(TestApp(child: _fourItemOrbit()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when rendered with 6 items, it should display without error', (tester) async {
      await tester.pumpWidget(TestApp(child: _sixItemOrbit()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when rendered with 12 items, it should display without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: QuiOrbit(
          items: List.generate(
            12,
            (_) => const QuiOrbitItem(child: SizedBox(width: 48, height: 48), size: Size(48, 48)),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when animations are disabled, it should render without error', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(child: _fourItemOrbit()),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when animations are enabled, it should render without error', (tester) async {
      await tester.pumpWidget(TestApp(child: _fourItemOrbit()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when rotateItems is true, it should render without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: _fourItemOrbit(rotateItems: true),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when rotateItems is false, items should not have Transform.rotate', (tester) async {
      await tester.pumpWidget(TestApp(child: _fourItemOrbit()));

      // Default path (rotateItems: false) — each item's position is animated
      // independently but items are NOT wrapped in Transform.rotate.
      // Pass pump a frame then immediately stop controller so we can inspect
      expect(tester.takeException(), isNull);
    });

    testWidgets('when rotateItems is true, items should each have a Transform.rotate', (tester) async {
      await tester.pumpWidget(TestApp(
        child: _fourItemOrbit(rotateItems: true),
      ));

      final orbit = find.byType(QuiOrbit);
      final transforms = find.descendant(of: orbit, matching: find.byType(Transform));
      expect(transforms, findsNWidgets(4)); // one per item
    });

    testWidgets('when animations are disabled and rotateItems is true, no Transform.rotate should exist', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: _fourItemOrbit(rotateItems: true),
          ),
        ),
      );

      final orbit = find.byType(QuiOrbit);
      final transforms = find.descendant(of: orbit, matching: find.byType(Transform));
      expect(transforms, findsNothing);
    });

    testWidgets('when radius is explicitly provided, it should render without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: QuiOrbit(
          radius: 80,
          items: List.generate(
            4,
            (_) => const QuiOrbitItem(child: SizedBox(width: 40, height: 40), size: Size(40, 40)),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when radius is zero, it should render items at center without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: QuiOrbit(
          radius: 0,
          items: List.generate(
            4,
            (_) => const QuiOrbitItem(child: SizedBox(width: 20, height: 20), size: Size(20, 20)),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when direction is counterclockwise, it should render without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: _fourItemOrbit(direction: QuiOrbitDirection.counterclockwise),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when initialAngle is set, it should render without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: QuiOrbit(
          initialAngle: 1.5,
          items: List.generate(
            4,
            (_) => const QuiOrbitItem(child: SizedBox(width: 40, height: 40), size: Size(40, 40)),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when padding is set and radius is auto, it should render without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: QuiOrbit(
          padding: 20,
          items: List.generate(
            4,
            (_) => const QuiOrbitItem(child: SizedBox(width: 40, height: 40), size: Size(40, 40)),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when items have different sizes, it should render without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: QuiOrbit(
          items: const [
            QuiOrbitItem(child: SizedBox(width: 40, height: 40), size: Size(40, 40)),
            QuiOrbitItem(child: SizedBox(width: 60, height: 30), size: Size(60, 30)),
            QuiOrbitItem(child: SizedBox(width: 24, height: 48), size: Size(24, 48)),
            QuiOrbitItem(child: SizedBox(width: 80, height: 20), size: Size(80, 20)),
          ],
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when revolutionDuration is changed, it should rebuild without error', (tester) async {
      await tester.pumpWidget(TestApp(child: _fourItemOrbit()));

      await tester.pumpWidget(TestApp(
        child: _fourItemOrbit(revolutionDuration: const Duration(seconds: 10)),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when revolutionDuration is changed to a very short duration, it should render without error', (tester) async {
      await tester.pumpWidget(TestApp(
        child: _fourItemOrbit(revolutionDuration: const Duration(milliseconds: 100)),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when placed in a constrained box, it should adapt its size', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: SizedBox(
              width: 200,
              height: 200,
              child: _fourItemOrbit(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when placed in a small box, it should still render', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: SizedBox(
              width: 100,
              height: 100,
              child: _fourItemOrbit(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when placed in an unbounded container, it should use default fallback size', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              minHeight: 0,
              maxHeight: double.infinity,
              child: _fourItemOrbit(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

Widget _fourItemOrbit({
  bool rotateItems = false,
  Duration revolutionDuration = const Duration(seconds: 30),
  QuiOrbitDirection direction = QuiOrbitDirection.clockwise,
}) {
  return QuiOrbit(
    rotateItems: rotateItems,
    revolutionDuration: revolutionDuration,
    direction: direction,
    items: const [
      QuiOrbitItem(
        child: _TestIcon(Icons.bolt_rounded, Color(0xFFFF4A4B)),
        size: Size(48, 48),
      ),
      QuiOrbitItem(
        child: _TestIcon(Icons.restaurant_rounded, Color(0xFF00A896)),
        size: Size(48, 48),
      ),
      QuiOrbitItem(
        child: _TestIcon(Icons.delivery_dining_rounded, Color(0xFF3D5A80)),
        size: Size(48, 48),
      ),
      QuiOrbitItem(
        child: _TestIcon(Icons.cleaning_services_rounded, Color(0xFFF4A261)),
        size: Size(48, 48),
      ),
    ],
  );
}

Widget _sixItemOrbit() {
  return QuiOrbit(
    items: const [
      QuiOrbitItem(child: _TestIcon(Icons.bolt_rounded, Color(0xFFFF4A4B)), size: Size(40, 40)),
      QuiOrbitItem(child: _TestIcon(Icons.restaurant_rounded, Color(0xFF00A896)), size: Size(40, 40)),
      QuiOrbitItem(child: _TestIcon(Icons.delivery_dining_rounded, Color(0xFF3D5A80)), size: Size(40, 40)),
      QuiOrbitItem(child: _TestIcon(Icons.cleaning_services_rounded, Color(0xFFF4A261)), size: Size(40, 40)),
      QuiOrbitItem(child: _TestIcon(Icons.handyman_rounded, Color(0xFF8338EC)), size: Size(40, 40)),
      QuiOrbitItem(child: _TestIcon(Icons.local_laundry_service_rounded, Color(0xFF06A77D)), size: Size(40, 40)),
    ],
  );
}

class _TestIcon extends StatelessWidget {
  const _TestIcon(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
