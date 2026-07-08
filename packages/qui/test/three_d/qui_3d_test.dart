import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/gen/assets.gen.dart';
import 'package:qui/src/three_d/qui_3d.dart';

void main() {
  group('Qui3d', () {
    test(
      'when calling build with (assets) => assets.box, the underlying asset '
      'should resolve to the box asset path',
      () {
        expect(Assets.threeD.box.path, 'assets/three_d/box.webp');
      },
    );

    test(
      'when calling build with (assets) => assets.motorcycle, the '
      'underlying asset should resolve to the motorcycle asset path',
      () {
        expect(
          Assets.threeD.motorcycle.path,
          'assets/three_d/motorcycle.webp',
        );
      },
    );

    test(
      'when calling build with (assets) => assets.toolBox, the '
      'underlying asset should resolve to the tool_box asset path',
      () {
        expect(Assets.threeD.toolBox.path, 'assets/three_d/tool_box.webp');
      },
    );

    test(
      'when reading Assets.threeD.box keyName, it should be '
      'package-qualified',
      () {
        expect(
          Assets.threeD.box.keyName,
          'packages/qui/assets/three_d/box.webp',
        );
      },
    );

    testWidgets(
      'when calling build with (assets) => assets.box, it should return '
      'an Image',
      (tester) async {
        late Image result;
        await tester.pumpWidget(
          Builder(builder: (context) {
            result = Qui3d.instance.build(context, (assets) => assets.box);
            return const SizedBox();
          }),
        );
        expect(result, isA<Image>());
      },
    );
  });
}
