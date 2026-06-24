import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiTikTokFeed Golden Tests', () {
    goldenTest(
      'when rendering static states, it should match the approved goldens',
      fileName: 'qui_tiktok_feed_static',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'current with next',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['first', 'second'])),
          ),
          GoldenTestScenario(
            name: 'single card',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['solo'])),
          ),
          GoldenTestScenario(
            name: 'empty end',
            child: const _GoldenFrame(child: _GoldenFeed(items: [], showEndState: true)),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering drag states, it should match the approved goldens',
      fileName: 'qui_tiktok_feed_drag_states',
      whilePerforming: (tester) async {
        await _holdDrag(tester, 'up_first', const Offset(0, -200));
        await _holdDrag(tester, 'down_first', const Offset(0, 200));
        await _holdDrag(tester, 'high_up_first', const Offset(0, -400));

        return null;
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'up partial drag',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['up_first', 'up_second'])),
          ),
          GoldenTestScenario(
            name: 'down partial drag',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['down_first', 'down_second'])),
          ),
          GoldenTestScenario(
            name: 'high progress up drag',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['high_up_first', 'high_up_second'])),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering after actions, it should match the approved goldens',
      fileName: 'qui_tiktok_feed_after_actions',
      whilePerforming: (tester) async {
        await tester.drag(find.byKey(_cardKey('next_first')), const Offset(0, -300));
        await tester.pumpAndSettle();

        return null;
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'after next',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['next_first', 'next_second'])),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering pagination states, it should match the approved goldens',
      fileName: 'qui_tiktok_feed_pagination_states',
      whilePerforming: (tester) async {
        await tester.pump();
        await tester.drag(find.byKey(_cardKey('loading_dismissed')), const Offset(0, -300));
        await tester.pumpAndSettle();

        return null;
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'last card with loading',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['loading_current'], isLoadingFixture: true)),
          ),
          GoldenTestScenario(
            name: 'full loading',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['loading_dismissed'], isLoadingFixture: true)),
          ),
          GoldenTestScenario(
            name: 'pagination error',
            child: const _GoldenFrame(child: _GoldenFeed(items: [], showLoadMoreError: true)),
          ),
          GoldenTestScenario(
            name: 'end state',
            child: const _GoldenFrame(child: _GoldenFeed(items: [], showEndState: true)),
          ),
          GoldenTestScenario(
            name: 'early threshold',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['first', 'second', 'third'], loadMoreThreshold: 0.5)),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering an exhausted deck during a drag, it should show the end card behind the outgoing card',
      fileName: 'qui_tiktok_feed_exhausted_drag',
      whilePerforming: (tester) async {
        await tester.pump();
        await tester.pump();
        await _holdDrag(tester, 'solo', const Offset(0, -200));

        return null;
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'exhausted last card dragged up',
            child: const _GoldenFrame(child: _GoldenFeed(items: ['solo'], showEndState: true, isExhausted: true)),
          ),
        ],
      ),
    );
  });

  goldenTest(
    'when rendering drag states with spacing, it should match the approved goldens',
    fileName: 'qui_tiktok_feed_spacing_drag_states',
    whilePerforming: (tester) async {
      await _holdDrag(tester, 'spacing_up_first', const Offset(0, -200));

      return null;
    },
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
      children: [
        GoldenTestScenario(
          name: 'spacing up partial drag',
          child: const _GoldenFrame(
            child: _GoldenFeed(items: ['spacing_up_first', 'spacing_up_second'], spacing: 40),
          ),
        ),
      ],
    ),
  );
}

Key _cardKey(String item) => Key('golden_card_$item');

Future<void> _holdDrag(WidgetTester tester, String item, Offset offset) async {
  final gesture = await tester.startGesture(tester.getCenter(find.byKey(_cardKey(item))));
  await gesture.moveBy(offset);
  await tester.pump();
}

Widget _goldenCardBuilder(BuildContext context, String item, int index) {
  return switch (item) {
    'solo' => const _GoldenCard(
      key: Key('golden_card_solo'),
      title: 'Entrega rapida',
      neighborhood: 'Bela Vista',
      pay: r'R$ 65',
      color: Color(0xFF3D5A80),
    ),
    final String value when value.contains('second') || value == 'loading_current' || value == 'loading_dismissed' =>
      _GoldenCard(
        key: _cardKey(value),
        title: 'Ajuda em evento',
        neighborhood: 'Vila Madalena',
        pay: r'R$ 240',
        color: const Color(0xFF00A896),
      ),
    _ => _GoldenCard(
      key: _cardKey(item),
      title: 'Garcom para hoje',
      neighborhood: 'Pinheiros',
      pay: r'R$ 180',
      color: const Color(0xFFFF4A4B),
    ),
  };
}

class _GoldenFeed extends StatelessWidget {
  const _GoldenFeed({
    required this.items,
    this.loadMoreThreshold = 1,
    this.spacing = 0,
    this.isLoadingFixture = false,
    this.showLoadMoreError = false,
    this.showEndState = false,
    this.isExhausted = false,
  });

  final List<String> items;
  final double loadMoreThreshold;
  final double spacing;
  final bool isLoadingFixture;
  final bool showLoadMoreError;
  final bool showEndState;
  final bool isExhausted;

  @override
  Widget build(BuildContext context) {
    return QuiTikTokFeed<String>(
      items: (count: items.length, provider: (int i) => items[i], keyBuilder: null),
      loadMoreThreshold: loadMoreThreshold,
      spacing: spacing,
      onLoadMore: isLoadingFixture
          ? () => Completer<void>().future
          : isExhausted
          ? () async {}
          : null,
      loadingMoreBuilder: _loadingMoreBuilder,
      loadMoreErrorBuilder: showLoadMoreError ? _loadMoreErrorBuilder : null,
      endBuilder: showEndState ? _endBuilder : null,
      builder: _goldenCardBuilder,
    );
  }
}

Widget _loadingMoreBuilder(BuildContext context) {
  return const _PaginationStateCard(
    title: 'Buscando mais',
    subtitle: 'Carregando novas oportunidades...',
    icon: Icons.sync_rounded,
    color: Color(0xFF3D5A80),
  );
}

Widget _loadMoreErrorBuilder(BuildContext context, VoidCallback retry) {
  return _PaginationStateCard(
    title: 'Tente de novo',
    subtitle: 'Nao conseguimos carregar agora.',
    icon: Icons.refresh_rounded,
    color: const Color(0xFFFF4A4B),
    onPressed: retry,
  );
}

Widget _endBuilder(BuildContext context) {
  return const _PaginationStateCard(
    title: 'Tudo visto',
    subtitle: 'Volte em breve para novas chances.',
    icon: Icons.check_rounded,
    color: Color(0xFF00A896),
  );
}

class _GoldenFrame extends StatelessWidget {
  const _GoldenFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F4F1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _GoldenCard extends StatelessWidget {
  const _GoldenCard({
    required super.key,
    required this.title,
    required this.neighborhood,
    required this.pay,
    required this.color,
  });

  final String title;
  final String neighborhood;
  final String pay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
            ),
            const Spacer(),
            Text(
              pay,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                const Icon(Icons.place_rounded, size: 18),
                Text(neighborhood),
                const SizedBox(width: 10),
                const Icon(Icons.schedule_rounded, size: 18),
                const Text('Agora'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationStateCard extends StatelessWidget {
  const _PaginationStateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF757575)),
            ),
            if (onPressed != null) ...[
              const SizedBox(height: 18),
              TextButton(onPressed: onPressed, child: const Text('Recarregar')),
            ],
          ],
        ),
      ),
    );
  }
}
