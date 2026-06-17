import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiSwipeDeck Golden Tests', () {
    goldenTest(
      'when rendering static states, it should match the approved goldens',
      fileName: 'qui_swipe_deck_static',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'current with next',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['first', 'second'])),
          ),
          GoldenTestScenario(
            name: 'single card',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['solo'])),
          ),
          GoldenTestScenario(
            name: 'empty end',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: [], showEndState: true)),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering drag states, it should match the approved goldens',
      fileName: 'qui_swipe_deck_drag_states',
      whilePerforming: (tester) async {
        await _holdDrag(tester, 'left_first', const Offset(-150, 20));
        await _holdDrag(tester, 'right_first', const Offset(150, -20));
        await _holdDrag(tester, 'high_first', const Offset(320, 30));

        return null;
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'left partial drag',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['left_first', 'left_second'])),
          ),
          GoldenTestScenario(
            name: 'right partial drag',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['right_first', 'right_second'])),
          ),
          GoldenTestScenario(
            name: 'high progress drag',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['high_first', 'high_second'])),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering after actions, it should match the approved goldens',
      fileName: 'qui_swipe_deck_after_actions',
      whilePerforming: (tester) async {
        await tester.drag(find.byKey(_cardKey('dismiss_first')), const Offset(-180, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.byKey(_cardKey('accept_first')), const Offset(180, 0));
        await tester.pumpAndSettle();

        return null;
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'after dismiss',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['dismiss_first', 'dismiss_second'])),
          ),
          GoldenTestScenario(
            name: 'after accept',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['accept_first', 'accept_second'])),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering pagination states, it should match the approved goldens',
      fileName: 'qui_swipe_deck_pagination_states',
      whilePerforming: (tester) async {
        await tester.pump();
        await tester.drag(find.byKey(_cardKey('loading_dismissed')), const Offset(-180, 0));
        await tester.pumpAndSettle();

        return null;
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 400, height: 600),
        children: [
          GoldenTestScenario(
            name: 'last card with loading',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['loading_current'], isLoadingFixture: true)),
          ),
          GoldenTestScenario(
            name: 'full loading',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: ['loading_dismissed'], isLoadingFixture: true)),
          ),
          GoldenTestScenario(
            name: 'pagination error',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: [], showLoadMoreError: true)),
          ),
          GoldenTestScenario(
            name: 'end state',
            child: const _GoldenFrame(child: _GoldenSwipeList(items: [], showEndState: true)),
          ),
          GoldenTestScenario(
            name: 'early threshold',
            child: const _GoldenFrame(
              child: _GoldenSwipeList(items: ['first', 'second', 'third'], loadMoreThreshold: 0.5),
            ),
          ),
        ],
      ),
    );
  });
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
    'dismiss_second' => const _GoldenCard(
      key: Key('golden_card_dismiss_second'),
      title: 'Ajuda em evento',
      neighborhood: 'Vila Madalena',
      pay: r'R$ 240',
      color: Color(0xFF00A896),
    ),
    'accept_first' => const _GoldenCard(
      key: Key('golden_card_accept_first'),
      title: 'Garcom para hoje',
      neighborhood: 'Pinheiros',
      pay: r'R$ 180',
      color: Color(0xFFFF4A4B),
    ),
    final String value when value.endsWith('second') => _GoldenCard(
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

class _GoldenSwipeList extends StatelessWidget {
  const _GoldenSwipeList({
    required this.items,
    this.loadMoreThreshold = 1,
    this.isLoadingFixture = false,
    this.showLoadMoreError = false,
    this.showEndState = false,
  });

  final List<String> items;
  final double loadMoreThreshold;
  final bool isLoadingFixture;
  final bool showLoadMoreError;
  final bool showEndState;

  @override
  Widget build(BuildContext context) {
    return QuiSwipeDeck<String>(
      itemCount: items.length,
      itemProvider: (index) => items[index],
      loadMoreThreshold: loadMoreThreshold,
      onLoadMore: isLoadingFixture ? () => Completer<void>().future : null,
      loadingMoreBuilder: _loadingMoreBuilder,
      buildLoadMoreError: showLoadMoreError ? _buildLoadMoreError : null,
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

Widget _buildLoadMoreError(BuildContext context, VoidCallback retry) {
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
      child: Padding(padding: const EdgeInsets.all(24), child: child),
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
