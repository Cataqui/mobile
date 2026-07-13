import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

final _colorScheme = QuiColorScheme.light();

void main() {
  group('QuiSkeletonShimmerEffect', () {
    test('when color is null, the gradient middle color equals colorScheme.skeleton.shimmerGlow', () {
      const effect = QuiSkeletonShimmerEffect();
      final paint = effect.buildPaint(bounds: const Rect.fromLTWH(0, 0, 100, 50), t: 0, colorScheme: _colorScheme, style: const QuiSkeletonStyle());

      expect(paint.shader, isA<ui.Gradient>());
    });

    test('when color is set, it should override the theme color', () {
      const effect = QuiSkeletonShimmerEffect(color: Color(0xFFFF0000));
      final paint = effect.buildPaint(bounds: const Rect.fromLTWH(0, 0, 100, 50), t: 0, colorScheme: _colorScheme, style: const QuiSkeletonStyle());

      expect(paint.shader, isA<ui.Gradient>());
    });

    test('when angle is zero, the gradient is horizontal', () {
      const effect = QuiSkeletonShimmerEffect();
      final paint = effect.buildPaint(bounds: const Rect.fromLTWH(0, 0, 100, 50), t: 0, colorScheme: _colorScheme, style: const QuiSkeletonStyle());

      expect(paint.shader, isA<ui.Gradient>());
    });

    test('when angle is pi/2, the gradient is vertical', () {
      const effect = QuiSkeletonShimmerEffect(angle: math.pi / 2);
      final paint = effect.buildPaint(bounds: const Rect.fromLTWH(0, 0, 100, 50), t: 0, colorScheme: _colorScheme, style: const QuiSkeletonStyle());

      expect(paint.shader, isA<ui.Gradient>());
    });

    test('when bounds are empty, buildPaint should not throw', () {
      const effect = QuiSkeletonShimmerEffect();
      final paint = effect.buildPaint(bounds: Rect.zero, t: 0, colorScheme: _colorScheme, style: const QuiSkeletonStyle());

      expect(paint.shader, isA<ui.Gradient>());
    });

    test('when angle is zero, two equal effects should be equal', () {
      const a = QuiSkeletonShimmerEffect();
      const b = QuiSkeletonShimmerEffect();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('when color differs, effects should not be equal', () {
      const a = QuiSkeletonShimmerEffect(color: Color(0xFFFFFFFF));
      const b = QuiSkeletonShimmerEffect(color: Color(0xFF000000));

      expect(a, isNot(equals(b)));
    });

    test('when angle differs, effects should not be equal', () {
      const a = QuiSkeletonShimmerEffect(angle: 0);
      const b = QuiSkeletonShimmerEffect(angle: math.pi / 4);

      expect(a, isNot(equals(b)));
    });
  });
}
