import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiDotLoadingIndicator Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_dot_loading_indicator_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 220, height: 160),
        children: [
          GoldenTestScenario(
            name: 'default primary dots',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiDotLoadingIndicator()),
            ),
          ),
          GoldenTestScenario(
            name: 'custom neutral dots',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiDotLoadingIndicator(color: Color(0xFF1F1F1F))),
            ),
          ),
          GoldenTestScenario(
            name: 'compact radius',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiDotLoadingIndicator(dotRadius: 3)),
            ),
          ),
          GoldenTestScenario(
            name: 'larger radius',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiDotLoadingIndicator(dotRadius: 6)),
            ),
          ),
        ],
      ),
    );
  });
}

class _GoldenFrame extends StatelessWidget {
  const _GoldenFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F4F1),
      child: Center(child: child),
    );
  }
}
