import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiSkeletonStyle', () {
    test('when two instances have the same fields, it should be equal', () {
      const a = QuiSkeletonStyle();
      const b = QuiSkeletonStyle();

      expect(a, equals(b));
    });

    test('when color differs, it should not be equal', () {
      const a = QuiSkeletonStyle(color: Color(0xFF111111));
      const b = QuiSkeletonStyle(color: Color(0xFF222222));

      expect(a, isNot(equals(b)));
    });

    test('when effect differs, it should not be equal', () {
      final a = const QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect());
      final b = const QuiSkeletonStyle();

      expect(a, isNot(equals(b)));
    });

    test('when textRadius differs, it should not be equal', () {
      const a = QuiSkeletonStyle(textRadius: Radius.zero);
      const b = QuiSkeletonStyle(textRadius: Radius.circular(8));

      expect(a, isNot(equals(b)));
    });

    test('when all fields are null, the default constructor should create a const instance', () {
      const style = QuiSkeletonStyle();

      expect(style.color, isNull);
      expect(style.effect, isNull);
      expect(style.textRadius, isNull);
    });

    test('when hashing two equal styles, it should produce the same hashCode', () {
      const a = QuiSkeletonStyle(color: Color(0xFF333333), textRadius: Radius.circular(4));
      const b = QuiSkeletonStyle(color: Color(0xFF333333), textRadius: Radius.circular(4));

      expect(a.hashCode, equals(b.hashCode));
    });

    test('when passing color, it should be stored', () {
      const style = QuiSkeletonStyle(color: Color(0xFF444444));

      expect(style.color, equals(const Color(0xFF444444)));
    });

    test('when passing textRadius, it should be stored', () {
      const style = QuiSkeletonStyle(textRadius: Radius.circular(12));

      expect(style.textRadius, equals(const Radius.circular(12)));
    });

    test('when passing effect, it should be stored', () {
      const style = QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect());

      expect(style.effect, isA<QuiSkeletonShimmerEffect>());
    });
  });
}
