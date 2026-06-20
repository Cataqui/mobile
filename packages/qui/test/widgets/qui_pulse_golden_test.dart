import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiPulse Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_pulse_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 300, height: 300),
        children: [
          GoldenTestScenario(
            name: 'default circular pulse',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(child: _goldenDot()),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'square border radius',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(
                  steps: const [
                    QuiPulseStep(borderRadius: BorderRadius.zero),
                    QuiPulseStep(borderRadius: BorderRadius.zero),
                  ],
                  child: _goldenDot(),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'squircle border radius',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(
                  steps: const [
                    QuiPulseStep(borderRadius: BorderRadius.all(Radius.circular(24))),
                    QuiPulseStep(borderRadius: BorderRadius.all(Radius.circular(24))),
                  ],
                  child: _goldenDot(),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'custom colors per step',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(
                  steps: const [
                    QuiPulseStep(color: Color(0xFFFF4A4B)),
                    QuiPulseStep(color: Color(0xFF00A896)),
                  ],
                  child: _goldenDot(),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'custom alpha per step',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(
                  steps: const [
                    QuiPulseStep(color: Color(0xFFFF4A4B), alpha: 0.7),
                    QuiPulseStep(color: Color(0xFF00A896), alpha: 0.15),
                  ],
                  child: _goldenDot(),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'single step',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(
                  steps: const [QuiPulseStep()],
                  child: _goldenDot(),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'four steps',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(
                  steps: const [
                    QuiPulseStep(color: Color(0xFFFF4A4B)),
                    QuiPulseStep(color: Color(0xFF00A896)),
                    QuiPulseStep(color: Color(0xFF3D5A80)),
                    QuiPulseStep(color: Color(0xFFF4A261)),
                  ],
                  child: _goldenDot(),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'small child',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(child: _goldenDot(size: 24)),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'large child',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(child: _goldenDot(size: 120)),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'transparent child (pulse from behind)',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiPulse(
                  child: const Icon(Icons.bolt_rounded, size: 56, color: Color(0xFFFF4A4B)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}

Widget _goldenDot({double size = 56, Color color = const Color(0xFFFF4A4B)}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4))],
    ),
    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
  );
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
