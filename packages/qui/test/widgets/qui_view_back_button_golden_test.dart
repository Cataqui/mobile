import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiViewBackButton Golden Tests', () {
    goldenTest(
      'when rendering the resting back button, it should match the approved golden',
      fileName: 'qui_view_back_button_resting',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'resting',
            child: QuiViewBackButton(onPressed: () {}),
          ),
        ],
      ),
    );
  });
}
