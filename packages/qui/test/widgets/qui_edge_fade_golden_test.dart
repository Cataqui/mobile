import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

/// A reusable widget that shows the edge-fade effect against a visible
/// background so the gradient is captured in golden screenshots.
class _FadeScenario extends StatelessWidget {
  const _FadeScenario({
    required this.position,
    this.color,
    this.backgroundColor = const Color(0xFF4A90D9),
  });

  final QuiEdgeFadePosition position;
  final Color? color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: backgroundColor),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: QuiEdgeFade(position: position, color: color),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('QuiEdgeFade Golden Tests', () {
    goldenTest(
      'when rendering positions and colors, it should match the approved goldens',
      fileName: 'qui_edge_fade_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
        children: [
          GoldenTestScenario(
            name: 'top edge',
            child: const _FadeScenario(position: QuiEdgeFadePosition.top),
          ),
          GoldenTestScenario(
            name: 'bottom edge',
            child: const _FadeScenario(position: QuiEdgeFadePosition.bottom),
          ),
          GoldenTestScenario(
            name: 'custom color',
            child: const _FadeScenario(
              position: QuiEdgeFadePosition.top,
              color: Color(0xFFFF4A4B),
            ),
          ),
          GoldenTestScenario(
            name: 'default color on light background',
            child: const _FadeScenario(
              position: QuiEdgeFadePosition.top,
              backgroundColor: Color(0xFFE8E8E8),
            ),
          ),
        ],
      ),
    );
  });
}
