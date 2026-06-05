import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiSearchBar Golden Tests', () {
    goldenTest(
      'when rendering static states, it should match the approved goldens',
      fileName: 'qui_search_bar_static',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'resting',
            child: const QuiSearchBar(
              placeholder: 'Search for an opportunity...',
            ),
          ),
          GoldenTestScenario(
            name: 'active with text',
            child: QuiSearchBar(
              placeholder: 'Search for an opportunity...',
              controller: TextEditingController(
                text: 'Garcom para Fim de Semana',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'frosted glass resting',
            child: const _FrostedGlassBackdrop(
              child: QuiSearchBar(
                placeholder: 'Buscar oportunidades...',
                isFrostedGlass: true,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when tapping the text field, it should render the focused state',
      fileName: 'qui_search_bar_active_focused',
      whilePerforming: _tap(find.byKey(_fieldKey)),
      builder: () => const SizedBox(
        width: 400,
        child: QuiSearchBar(placeholder: 'Search for an opportunity...'),
      ),
    );

    goldenTest(
      'when tapping the frosted text field, it should render the focused state',
      fileName: 'qui_search_bar_frosted_active',
      whilePerforming: _tap(find.byKey(_fieldKey)),
      builder: () => const SizedBox(
        width: 400,
        child: _FrostedGlassBackdrop(
          child: QuiSearchBar(
            placeholder: 'Buscar oportunidades...',
            isFrostedGlass: true,
          ),
        ),
      ),
    );

    goldenTest(
      'when tapping the magnifier icon, it should render the focused state',
      fileName: 'qui_search_bar_tap_magnifier',
      whilePerforming: _tap(find.byKey(_iconButtonKey)),
      builder: () => const SizedBox(width: 400, child: QuiSearchBar()),
    );

    goldenTest(
      'when tapping the cross icon with text, it should render the rest state',
      fileName: 'qui_search_bar_tap_cross_with_text',
      whilePerforming: _tap(find.byKey(_iconButtonKey)),
      builder: () => SizedBox(
        width: 400,
        child: QuiSearchBar(
          controller: TextEditingController(text: 'Some text'),
        ),
      ),
    );

    goldenTest(
      'when tapping the empty cross icon, it should render the rest state',
      fileName: 'qui_search_bar_tap_cross_no_text',
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(_fieldKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(_iconButtonKey));
        await tester.pumpAndSettle();
        return null;
      },
      builder: () => const SizedBox(width: 400, child: QuiSearchBar()),
    );
  });
}

const _fieldKey = Key('qui_search_bar_field');
const _iconButtonKey = Key('qui_search_bar_icon_button');

Interaction _tap(Finder finder) {
  return (tester) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    return null;
  };
}

class _FrostedGlassBackdrop extends StatelessWidget {
  const _FrostedGlassBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFE66D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
