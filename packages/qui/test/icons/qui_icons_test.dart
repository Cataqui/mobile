import 'package:flutter_test/flutter_test.dart';
import 'package:qui/gen/assets.gen.dart';
import 'package:qui/src/icons/qui_icons.dart';

void main() {
  group('QuiIcons', () {
    test(
      'when accessing QuiIcons.cross, it should resolve to the cross asset path',
      () {
        expect(QuiIcons.cross.path, 'assets/icons/cross.svg');
      },
    );

    test(
      'when accessing QuiIcons.magnifierGlass, it should resolve to the '
      'magnifier_glass asset path',
      () {
        expect(QuiIcons.magnifierGlass.path, 'assets/icons/magnifier_glass.svg');
      },
    );

    test(
      'when accessing QuiIcons.chevronDown, it should resolve to the '
      'chevron_down asset path',
      () {
        expect(QuiIcons.chevronDown.path, 'assets/icons/chevron_down.svg');
      },
    );

    test(
      'when reading QuiIcons.cross keyName, it should be package-qualified',
      () {
        expect(
          QuiIcons.cross.keyName,
          'packages/qui/assets/icons/cross.svg',
        );
      },
    );

    test(
      'when comparing QuiIcons to Assets.icons, it should be the same instance',
      () {
        expect(identical(QuiIcons, Assets.icons), isTrue);
      },
    );
  });
}
