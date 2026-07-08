import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiRouteSettled Golden Tests', () {
    goldenTest(
      'when the route is settled, it should render the child fully visible',
      fileName: 'qui_route_settled_resting',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 300, height: 200),
        children: [
          GoldenTestScenario(
            name: 'resting',
            child: _RestingRouteSettled(
              child: const Text('Hello World', style: TextStyle(fontSize: 20)),
            ),
          ),
          GoldenTestScenario(
            name: 'with container',
            child: _RestingRouteSettled(
              child: Container(
                width: 100,
                height: 100,
                color: const Color(0xFFFF4A4B),
                alignment: Alignment.center,
                child: const Text('Box', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  });
}

/// Wraps [child] in a [QuiRouteSettled] inside a reduced-motion environment so
/// the settle animation completes instantly and golden output is deterministic.
class _RestingRouteSettled extends StatelessWidget {
  const _RestingRouteSettled({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Material(
        child: Center(
          child: QuiRouteSettled(child: child),
        ),
      ),
    );
  }
}
