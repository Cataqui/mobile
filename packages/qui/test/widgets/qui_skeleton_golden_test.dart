import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiSkeleton Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_skeleton_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 340),
        children: [
          GoldenTestScenario(
            name: 'disabled (pass through)',
            child: const _SkeletonFrame(child: QuiSkeleton(enabled: false, shimmer: false, child: _CardContent())),
          ),
          GoldenTestScenario(
            name: 'static skeleton (no shimmer)',
            child: const _SkeletonFrame(child: QuiSkeleton(shimmer: false, child: _CardContent())),
          ),
          GoldenTestScenario(
            name: 'text only skeleton',
            child: const _SkeletonFrame(
              child: QuiSkeleton(
                shimmer: false,
                child: Text('Loading text that becomes skeleton bones', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'card with icon',
            child: const _SkeletonFrame(child: QuiSkeleton(shimmer: false, child: _CardContent())),
          ),
        ],
      ),
    );
  });
}

class _SkeletonFrame extends StatelessWidget {
  const _SkeletonFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F4F1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 340,
          child: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: child),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Garçom para Fim de Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(r'Pinheiros • R$ 180 • 18h-23h'),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, size: 16),
              SizedBox(width: 4),
              Flexible(child: Text('4.8 (32 avaliações)')),
            ],
          ),
        ],
      ),
    );
  }
}
