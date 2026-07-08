import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/gen/assets.gen.dart';
import 'package:qui/src/icons/qui_icons.dart';

void main() {
  group('QuiIcons', () {
    test(
      'when calling build with (assets) => assets.cross, it should return an '
      'SvgPicture',
      () {
        expect(
          QuiIcons.instance.build((assets) => assets.cross),
          isA<SvgPicture>(),
        );
      },
    );

    test(
      'when calling build with (assets) => assets.cross, the underlying asset '
      'should resolve to the cross asset path',
      () {
        const expectedPath = 'assets/icons/cross.svg';
        // Use the raw generated asset to verify path resolution
        expect(Assets.icons.cross.path, expectedPath);
      },
    );

    test(
      'when calling build with (assets) => assets.magnifierGlass, the '
      'underlying asset should resolve to the magnifier_glass asset path',
      () {
        expect(
          Assets.icons.magnifierGlass.path,
          'assets/icons/magnifier_glass.svg',
        );
      },
    );

    test(
      'when calling build with (assets) => assets.chevronDown, the '
      'underlying asset should resolve to the chevron_down asset path',
      () {
        expect(
          Assets.icons.chevronDown.path,
          'assets/icons/chevron_down.svg',
        );
      },
    );

    test(
      'when reading Assets.icons.cross keyName, it should be '
      'package-qualified',
      () {
        expect(
          Assets.icons.cross.keyName,
          'packages/qui/assets/icons/cross.svg',
        );
      },
    );
  });
}
