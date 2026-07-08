import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHeroEdgeFade', () {
    test('when top and bottom are both provided, lerp should interpolate each side independently', () {
      const source = QuiHeroEdgeFade(
        top: QuiEdgeFadeStyle(color: Color(0xFFFF0000), height: 100),
        bottom: QuiEdgeFadeStyle(color: Color(0xFF0000FF), height: 50),
      );
      const destination = QuiHeroEdgeFade(
        top: QuiEdgeFadeStyle(color: Color(0xFF00FF00), height: 200),
        bottom: QuiEdgeFadeStyle(color: Color(0xFFFFFF00), height: 80),
      );

      final result = QuiHeroEdgeFade.lerp(source, destination, 0.5);

      expect(result.top, isNotNull);
      expect(result.top!.height, equals(150.0));
      expect(result.bottom, isNotNull);
      expect(result.bottom!.height, equals(65.0));
    });

    test('when top is null on both endpoints, lerp should keep top null', () {
      const source = QuiHeroEdgeFade(bottom: QuiEdgeFadeStyle(height: 100));
      const destination = QuiHeroEdgeFade(bottom: QuiEdgeFadeStyle(height: 200));

      final result = QuiHeroEdgeFade.lerp(source, destination, 0.5);

      expect(result.top, isNull);
      expect(result.bottom!.height, equals(150.0));
    });

    test('copyWith should update only the specified field', () {
      const original = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100), bottom: QuiEdgeFadeStyle(height: 50));

      final updated = original.copyWith(top: const QuiEdgeFadeStyle(height: 200));

      expect(updated.top!.height, equals(200.0));
      expect(updated.bottom, equals(original.bottom));
    });

    test('equality should compare both sides', () {
      const a = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100), bottom: QuiEdgeFadeStyle(height: 50));
      const b = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100), bottom: QuiEdgeFadeStyle(height: 50));

      expect(a, equals(b));
    });

    test('when using the default switchThreshold, lerp should preserve the current full-flight timing', () {
      const source = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 0));
      const destination = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100));

      final result = QuiHeroEdgeFade.lerp(source, destination, 0.5);

      expect(result.top!.height, equals(50.0));
    });

    test('when switchThreshold is 0.1, lerp should reach halfway at 5 percent of the flight', () {
      const source = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 0), switchThreshold: 0.1);
      const destination = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100));

      final result = QuiHeroEdgeFade.lerp(source, destination, 0.05);

      expect(result.top!.height, equals(50.0));
    });

    test('when switchThreshold is 0.1, lerp should reach the destination at 10 percent of the flight', () {
      const source = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 0), switchThreshold: 0.1);
      const destination = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100));

      final result = QuiHeroEdgeFade.lerp(source, destination, 0.1);

      expect(result.top!.height, equals(100.0));
    });

    test('when endpoints have different switchThreshold values, lerp should use the source threshold', () {
      const source = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 0), switchThreshold: 0.1);
      const destination = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100), switchThreshold: 0.9);

      final result = QuiHeroEdgeFade.lerp(source, destination, 0.1);

      expect(result.top!.height, equals(100.0));
    });

    test('when switchThreshold is zero, lerp should switch to the destination immediately', () {
      const source = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 0), switchThreshold: 0);
      const destination = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100));

      final result = QuiHeroEdgeFade.lerp(source, destination, 0);

      expect(result.top!.height, equals(100.0));
    });

    test('when creating with switchThreshold below zero, it should throw an assertion error', () {
      expect(() => QuiHeroEdgeFade(switchThreshold: -0.1), throwsA(isA<AssertionError>()));
    });

    test('when creating with switchThreshold above one, it should throw an assertion error', () {
      expect(() => QuiHeroEdgeFade(switchThreshold: 1.1), throwsA(isA<AssertionError>()));
    });

    test('when copying with a switchThreshold, it should update the threshold', () {
      const original = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100));

      final updated = original.copyWith(switchThreshold: 0.1);

      expect(updated.switchThreshold, equals(0.1));
    });
  });
}
