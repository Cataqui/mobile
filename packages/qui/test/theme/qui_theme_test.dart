import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_data.dart';

void main() {
  group('QuiThemeData', () {
    test('copyWith preserves existing values when no arguments provided', () {
      const original = QuiThemeData(backgroundColor: Color(0xFFFFFFFF));
      final result = original.copyWith();

      expect(result.backgroundColor, equals(const Color(0xFFFFFFFF)));
    });

    test('copyWith replaces backgroundColor when provided', () {
      const original = QuiThemeData(backgroundColor: Color(0xFFFFFFFF));
      const black = Color(0xFF000000);
      final result = original.copyWith(backgroundColor: black);

      expect(result.backgroundColor, equals(black));
    });

    test('lerp interpolates backgroundColor between two themes', () {
      const a = QuiThemeData(backgroundColor: Color(0xFFFFFFFF));
      const b = QuiThemeData(backgroundColor: Color(0xFF000000));
      final result = a.lerp(b, 0.5);

      expect(
        result.backgroundColor,
        equals(const Color.from(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)),
      );
    });
  });

  group('QuiTheme', () {
    test('light theme registers QuiThemeData extension', () {
      final theme = QuiTheme.light();
      final data = theme.extension<QuiThemeData>();

      expect(data, isNotNull);
    });

    test('light theme sets scaffoldBackgroundColor to white', () {
      final theme = QuiTheme.light();

      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFFFFFF)));
    });

    test('light theme enables Material 3', () {
      final theme = QuiTheme.light();

      expect(theme.useMaterial3, isTrue);
    });
  });

  group('QuiThemeContext', () {
    testWidgets('extension retrieves QuiThemeData from BuildContext', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuiTheme.light(),
          home: Builder(
            builder: (context) {
              final data = Theme.of(context).extension<QuiThemeData>();

              expect(data, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
