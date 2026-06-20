import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiSearchBarButton Golden Tests', () {
    goldenTest(
      'when rendering the resting search bar button, it should match the approved golden',
      fileName: 'qui_search_bar_button_resting',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'resting',
            child: const SizedBox(
              width: 400,
              child: QuiSearchBarButton(
                placeholder: 'Search for an opportunity...',
              ),
            ),
          ),
        ],
      ),
    );
  });
}
