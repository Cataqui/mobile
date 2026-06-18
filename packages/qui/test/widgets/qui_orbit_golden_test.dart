import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiOrbit Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_orbit_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 400),
        children: [
          GoldenTestScenario(
            name: '4 items upright',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiOrbit(items: _fourOrbitItems)),
            ),
          ),
          GoldenTestScenario(
            name: '6 items upright',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiOrbit(items: _sixOrbitItems)),
            ),
          ),
          GoldenTestScenario(
            name: '8 items upright',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiOrbit(items: _eightOrbitItems)),
            ),
          ),
          GoldenTestScenario(
            name: 'rotateItems spin',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiOrbit(rotateItems: true, items: _fourOrbitItems)),
            ),
          ),
          GoldenTestScenario(
            name: 'custom radius',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiOrbit(radius: 60, items: _fourOrbitItems)),
            ),
          ),
          GoldenTestScenario(
            name: 'counterclockwise',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiOrbit(direction: QuiOrbitDirection.counterclockwise, items: _fourOrbitItems),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'initial angle offset',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiOrbit(initialAngle: 0.75, items: _fourOrbitItems)),
            ),
          ),
          GoldenTestScenario(
            name: 'different item sizes',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(
                child: QuiOrbit(
                  items: [
                    QuiOrbitItem(
                      child: _goldenChip(Icons.bolt_rounded, const Color(0xFFFF4A4B)),
                      size: const Size(64, 64),
                    ),
                    QuiOrbitItem(
                      child: _goldenChip(Icons.restaurant_rounded, const Color(0xFF00A896)),
                      size: const Size(48, 48),
                    ),
                    QuiOrbitItem(
                      child: _goldenChip(Icons.delivery_dining_rounded, const Color(0xFF3D5A80)),
                      size: const Size(32, 48),
                    ),
                    QuiOrbitItem(
                      child: _goldenChip(Icons.cleaning_services_rounded, const Color(0xFFF4A261)),
                      size: const Size(56, 40),
                    ),
                    QuiOrbitItem(
                      child: _goldenChip(Icons.handyman_rounded, const Color(0xFF8338EC)),
                      size: const Size(48, 32),
                    ),
                    QuiOrbitItem(
                      child: _goldenChip(Icons.local_laundry_service_rounded, const Color(0xFF06A77D)),
                      size: const Size(64, 64),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'padding inset',
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _GoldenFrame(child: QuiOrbit(padding: 30, items: _fourOrbitItems)),
            ),
          ),
        ],
      ),
    );
  });
}

final _fourOrbitItems = [
  QuiOrbitItem(child: _goldenChip(Icons.bolt_rounded, const Color(0xFFFF4A4B)), size: const Size(56, 56)),
  QuiOrbitItem(child: _goldenChip(Icons.restaurant_rounded, const Color(0xFF00A896)), size: const Size(56, 56)),
  QuiOrbitItem(child: _goldenChip(Icons.delivery_dining_rounded, const Color(0xFF3D5A80)), size: const Size(56, 56)),
  QuiOrbitItem(child: _goldenChip(Icons.cleaning_services_rounded, const Color(0xFFF4A261)), size: const Size(56, 56)),
];

final _sixOrbitItems = [
  QuiOrbitItem(child: _goldenChip(Icons.bolt_rounded, const Color(0xFFFF4A4B)), size: const Size(48, 48)),
  QuiOrbitItem(child: _goldenChip(Icons.restaurant_rounded, const Color(0xFF00A896)), size: const Size(48, 48)),
  QuiOrbitItem(child: _goldenChip(Icons.delivery_dining_rounded, const Color(0xFF3D5A80)), size: const Size(48, 48)),
  QuiOrbitItem(child: _goldenChip(Icons.cleaning_services_rounded, const Color(0xFFF4A261)), size: const Size(48, 48)),
  QuiOrbitItem(child: _goldenChip(Icons.handyman_rounded, const Color(0xFF8338EC)), size: const Size(48, 48)),
  QuiOrbitItem(
    child: _goldenChip(Icons.local_laundry_service_rounded, const Color(0xFF06A77D)),
    size: const Size(48, 48),
  ),
];

final _eightOrbitItems = [
  QuiOrbitItem(child: _goldenChip(Icons.bolt_rounded, const Color(0xFFFF4A4B)), size: const Size(40, 40)),
  QuiOrbitItem(child: _goldenChip(Icons.restaurant_rounded, const Color(0xFF00A896)), size: const Size(40, 40)),
  QuiOrbitItem(child: _goldenChip(Icons.delivery_dining_rounded, const Color(0xFF3D5A80)), size: const Size(40, 40)),
  QuiOrbitItem(child: _goldenChip(Icons.cleaning_services_rounded, const Color(0xFFF4A261)), size: const Size(40, 40)),
  QuiOrbitItem(child: _goldenChip(Icons.handyman_rounded, const Color(0xFF8338EC)), size: const Size(40, 40)),
  QuiOrbitItem(
    child: _goldenChip(Icons.local_laundry_service_rounded, const Color(0xFF06A77D)),
    size: const Size(40, 40),
  ),
  QuiOrbitItem(child: _goldenChip(Icons.pets_rounded, const Color(0xFFE76F51)), size: const Size(40, 40)),
  QuiOrbitItem(child: _goldenChip(Icons.directions_bike_rounded, const Color(0xFF264653)), size: const Size(40, 40)),
];

Widget _goldenChip(IconData icon, Color color) {
  return Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4))],
    ),
    child: Icon(icon, color: Colors.white, size: 24),
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
