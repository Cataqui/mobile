import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiWidgetTransition Golden Tests', () {
    goldenTest(
      'when rendering static states, it should match the approved goldens',
      fileName: 'qui_widget_transition_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 300, height: 400),
        children: [
          GoldenTestScenario(
            name: 'loading',
            child: const _GoldenFrame(
              child: _StaticTransition(index: 0),
            ),
          ),
          GoldenTestScenario(
            name: 'content',
            child: const _GoldenFrame(
              child: _StaticTransition(index: 1),
            ),
          ),
          GoldenTestScenario(
            name: 'error',
            child: const _GoldenFrame(
              child: _StaticTransition(index: 2),
            ),
          ),
        ],
      ),
    );
  });
}

class _StaticTransition extends StatelessWidget {
  const _StaticTransition({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return QuiWidgetTransition(
      builder: (_) => KeyedSubtree(
        key: ValueKey('state_$index'),
        child: _GoldenChild(index: index),
      ),
      outDuration: const Duration(milliseconds: 300),
      outTransition: (child, controller) => FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(controller),
        child: child,
      ),
      inDuration: const Duration(milliseconds: 500),
      inTransition: (child, controller) {
        final curved = CurveTween(curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(controller)),
          child: child,
        );
      },
    );
  }
}

class _GoldenChild extends StatelessWidget {
  const _GoldenChild({required this.index});

  final int index;

  static const _colors = [
    Color(0xFFFF4A4B),
    Color(0xFF00A896),
    Color(0xFF3D5A80),
  ];

  static const _labels = ['Carregando...', 'Item A', 'Item B'];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _colors[index],
      child: Center(
        child: Text(
          _labels[index],
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _GoldenFrame extends StatelessWidget {
  const _GoldenFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F4F1),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}
