import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiDotMatrix Color Golden Tests', () {
    goldenTest(
      'when rendering with different colors, it should match the approved goldens',
      fileName: 'qui_dot_matrix_colors',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 320, height: 1300),
        children: [
          GoldenTestScenario(
            name: 'no explicit color',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _ColorFrame(
                child: const QuiDotMatrix(width: 240, height: 160, radius: 16),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'blue',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _ColorFrame(
                child: const QuiDotMatrix(width: 240, height: 160, radius: 16, colors: [Color(0xFF4A90D9)]),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'green',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _ColorFrame(
                child: const QuiDotMatrix(width: 240, height: 160, radius: 16, colors: [Color(0xFF34C759)]),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'orange',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _ColorFrame(
                child: const QuiDotMatrix(width: 240, height: 160, radius: 16, colors: [Color(0xFFFF9500)]),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'red',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _ColorFrame(
                child: const QuiDotMatrix(width: 240, height: 160, radius: 16, colors: [Color(0xFFFF3B30)]),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'purple',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _ColorFrame(
                child: const QuiDotMatrix(width: 240, height: 160, radius: 16, colors: [Color(0xFFAF52DE)]),
              ),
            ),
          ),
        ],
      ),
    );
  });
}

class _ColorFrame extends StatelessWidget {
  const _ColorFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F4F1),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}
