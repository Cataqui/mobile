import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiIconButton Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_icon_button_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(minWidth: 96),
        children: [
          GoldenTestScenario(
            name: 'resting with label',
            child: QuiIconButton(
              label: 'Buscar',
              iconBuilder: (state) => Icon(Icons.search, color: state.recommendedIconColor, size: state.iconSize),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'resting without label',
            child: QuiIconButton(
              iconBuilder: (state) => Icon(Icons.add, color: state.recommendedIconColor, size: state.iconSize),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'custom background',
            child: QuiIconButton(
              backgroundColor: const Color(0xFF00A676),
              label: 'Mapa',
              iconBuilder: (state) => Icon(Icons.location_on, color: state.recommendedIconColor, size: state.iconSize),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'custom disabled background',
            child: QuiIconButton(
              disabledBackgroundColor: const Color(0xFFDDDDDD),
              label: 'Fechado',
              iconBuilder: (state) => Icon(Icons.lock, color: state.recommendedIconColor, size: state.iconSize),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled with label',
            child: QuiIconButton(
              label: 'Bloqueado',
              iconBuilder: (state) => Icon(Icons.lock, color: state.recommendedIconColor, size: state.iconSize),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when pressing the button, it should match the approved golden',
      fileName: 'qui_icon_button_pressed',
      whilePerforming: (tester) async {
        final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('qui_icon_button_circle'))));
        await tester.pump(const Duration(milliseconds: 120));
        addTearDown(gesture.removePointer);
        return null;
      },
      builder: () => QuiIconButton(
        label: 'Buscar',
        iconBuilder: (state) => Icon(Icons.search, color: state.recommendedIconColor, size: state.iconSize),
        onPressed: () {},
      ),
    );
  });
}
