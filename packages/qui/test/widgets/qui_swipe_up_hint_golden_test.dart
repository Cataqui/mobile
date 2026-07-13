import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiSwipeUpHint Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_swipe_up_hint_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 300, height: 300),
        children: [
          GoldenTestScenario(
            name: 'default theme colors',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiSwipeUpHint()),
            ),
          ),
          GoldenTestScenario(
            name: 'custom phone color',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiSwipeUpHint(phoneColor: Color(0xFF1F1F1F))),
            ),
          ),
          GoldenTestScenario(
            name: 'custom accent color',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiSwipeUpHint(accentColor: Color(0xFFFF4A4B))),
            ),
          ),
          GoldenTestScenario(
            name: 'custom colors both',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiSwipeUpHint(phoneColor: Color(0xFF1F1F1F), accentColor: Color(0xFFFF4A4B)),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'small height',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiSwipeUpHint(height: 80)),
            ),
          ),
          GoldenTestScenario(
            name: 'large height',
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiSwipeUpHint(height: 240)),
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
