import 'package:cataqui_core/cataqui_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColorExtension', () {
    test('when darkening a color, it should lerp the color toward black by the provided amount', () {
      final color = const Color(0xFFE1E1E1).darken(0.28);

      expect(color, equals(Color.lerp(const Color(0xFFE1E1E1), Colors.black, 0.28)));
    });

    test('when darkening by less than zero, it should clamp to the original color', () {
      final color = const Color(0xFFE1E1E1).darken(-1);

      expect(color, equals(const Color(0xFFE1E1E1)));
    });

    test('when darkening by more than one, it should clamp to black', () {
      final color = const Color(0xFFE1E1E1).darken(2);

      expect(color, equals(Colors.black));
    });
  });
}
