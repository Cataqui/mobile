import 'package:flutter_test/flutter_test.dart';
import 'package:qui/gen/assets.gen.dart';
import 'package:qui/src/three_d/qui_3d.dart';

void main() {
  group('Qui3d', () {
    test(
      'when accessing Qui3d.box, it should resolve to the box asset path',
      () {
        expect(Qui3d.box.path, 'assets/three_d/box.webp');
      },
    );

    test(
      'when accessing Qui3d.motorcycle, it should resolve to the '
      'motorcycle asset path',
      () {
        expect(Qui3d.motorcycle.path, 'assets/three_d/motorcycle.webp');
      },
    );

    test(
      'when accessing Qui3d.toolBox, it should resolve to the '
      'tool_box asset path',
      () {
        expect(Qui3d.toolBox.path, 'assets/three_d/tool_box.webp');
      },
    );

    test(
      'when reading Qui3d.box keyName, it should be package-qualified',
      () {
        expect(
          Qui3d.box.keyName,
          'packages/qui/assets/three_d/box.webp',
        );
      },
    );

    test(
      'when comparing Qui3d to Assets.threeD, it should be the same instance',
      () {
        expect(identical(Qui3d, Assets.threeD), isTrue);
      },
    );
  });
}
