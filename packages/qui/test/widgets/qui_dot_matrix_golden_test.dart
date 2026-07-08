import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiDotMatrix Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_dot_matrix_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 360, height: 360),
        children: [
          GoldenTestScenario(
            name: 'default scene',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 240, height: 160, radius: 16),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'square image placeholder',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 200, height: 200, radius: 24),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'full-width banner',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 320, height: 80, radius: 12),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'no corner radius',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 200, height: 140, radius: 0),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'fully rounded pill',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 160, height: 160, radius: 80),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'tiny chip size',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 48, height: 48, radius: 12),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'large hero size',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 320, height: 320, radius: 28),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'non-square hero',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 320, height: 200, radius: 20),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'minimal single-dot size',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 28, height: 28, radius: 0),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'wide with moderate rounding',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 320, height: 120, radius: 36),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'full circle',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 180, height: 180, radius: 90),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'small circle',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 70, height: 70, radius: 35),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'small rect with large rounding',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 100, height: 80, radius: 35),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'pill banner',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 320, height: 64, radius: 32),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'medium square with large radius',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 260, height: 260, radius: 60),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'thin horizontal bar',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 280, height: 32, radius: 0),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'thin bar with pill rounding',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 280, height: 32, radius: 16),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'tiny oversquare',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 34, height: 34, radius: 0),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'tall narrow vertical',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 60, height: 260, radius: 10),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'medium rect with generous rounding',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(width: 200, height: 140, radius: 40),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'explicit blue color',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: const QuiDotMatrix(
                  width: 200,
                  height: 140,
                  radius: 16,
                  color: Color(0xFF4A90D9),
                ),
              ),
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
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}
