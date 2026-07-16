import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiIcon', () {
    test('when calling QuiIcon.cross, it should return a Widget', () {
      expect(QuiIcon.cross(), isA<Widget>());
    });

    test('when calling QuiIcon.cross with color, it should return a Widget', () {
      expect(QuiIcon.cross(color: Colors.red), isA<Widget>());
    });

    test('when calling QuiIcon.magnifierGlass with width and height, it should return a Widget', () {
      expect(QuiIcon.magnifierGlass(width: 18, height: 18), isA<Widget>());
    });

    test('when calling QuiIcon.arrowLeft, it should return a Widget', () {
      expect(QuiIcon.arrowLeft(), isA<Widget>());
    });

    test('when calling QuiIcon.arrowRotateClockwise, it should return a Widget', () {
      expect(QuiIcon.arrowRotateClockwise(), isA<Widget>());
    });

    test('when calling QuiIcon.arrowUp, it should return a Widget', () {
      expect(QuiIcon.arrowUp(), isA<Widget>());
    });

    test('when calling QuiIcon.chevronDown, it should return a Widget', () {
      expect(QuiIcon.chevronDown(), isA<Widget>());
    });

    test('when calling QuiIcon.circleBlock, it should return a Widget', () {
      expect(QuiIcon.circleBlock(), isA<Widget>());
    });

    test('when calling QuiIcon.clock, it should return a Widget', () {
      expect(QuiIcon.clock(), isA<Widget>());
    });

    test('when calling QuiIcon.exclamationCircle, it should return a Widget', () {
      expect(QuiIcon.exclamationCircle(), isA<Widget>());
    });

    test('when calling QuiIcon.exclamationTriangle, it should return a Widget', () {
      expect(QuiIcon.exclamationTriangle(), isA<Widget>());
    });

    test('when calling QuiIcon.mapPin, it should return a Widget', () {
      expect(QuiIcon.mapPin(), isA<Widget>());
    });

    test('when calling QuiIcon.phone, it should return a Widget', () {
      expect(QuiIcon.phone(), isA<Widget>());
    });

    test('when calling QuiIcon.pointerHandUp, it should return a Widget', () {
      expect(QuiIcon.pointerHandUp(), isA<Widget>());
    });

    test('when calling QuiIcon.smartphone, it should return a Widget', () {
      expect(QuiIcon.smartphone(), isA<Widget>());
    });

    test('when calling QuiIcon.whatsapp, it should return a Widget', () {
      expect(QuiIcon.whatsapp(), isA<Widget>());
    });

    test('when calling QuiIcon.wrench, it should return a Widget', () {
      expect(QuiIcon.wrench(), isA<Widget>());
    });
  });
}
