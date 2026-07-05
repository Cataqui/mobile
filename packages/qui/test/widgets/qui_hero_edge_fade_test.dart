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
  });
}
