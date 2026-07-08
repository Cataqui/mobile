import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

const _testDpr = 3.0;

Widget _buildApp(void Function(BuildContext) captureContext) {
  return MediaQuery(
    data: const MediaQueryData(
      devicePixelRatio: _testDpr,
      size: Size(400, 800),
    ),
    child: Builder(builder: (context) {
      captureContext(context);
      return const SizedBox();
    }),
  );
}

void main() {
  group('when Qui3d.build is called', () {
    testWidgets(
      'with width, it should set cacheWidth to width times devicePixelRatio',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_buildApp((c) => ctx = c));

        final image = Qui3d.instance.build(
          ctx,
          (assets) => assets.box,
          width: 100,
        );

        expect((image.image as ResizeImage).width, (100 * _testDpr).ceil());
      },
    );

    testWidgets(
      'with width and height, it should set cacheWidth and cacheHeight to '
      'width and height times devicePixelRatio',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_buildApp((c) => ctx = c));

        final image = Qui3d.instance.build(
          ctx,
          (assets) => assets.box,
          width: 100,
          height: 150,
        );

        expect((image.image as ResizeImage).width, (100 * _testDpr).ceil());
        expect((image.image as ResizeImage).height, (150 * _testDpr).ceil());
      },
    );

    testWidgets(
      'with only width, it should leave cacheHeight null',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_buildApp((c) => ctx = c));

        final image = Qui3d.instance.build(
          ctx,
          (assets) => assets.box,
          width: 100,
        );

        expect((image.image as ResizeImage).height, isNull);
      },
    );

    testWidgets(
      'with only height, it should leave cacheWidth null',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_buildApp((c) => ctx = c));

        final image = Qui3d.instance.build(
          ctx,
          (assets) => assets.box,
          height: 100,
        );

        expect((image.image as ResizeImage).width, isNull);
      },
    );

    testWidgets(
      'without any size, it should not wrap the provider in ResizeImage',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_buildApp((c) => ctx = c));

        final image = Qui3d.instance.build(ctx, (assets) => assets.box);

        expect(image.image, isNot(isA<ResizeImage>()));
      },
    );

    testWidgets(
      'when color is passed, it should apply the color to the returned image',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_buildApp((c) => ctx = c));

        const testColor = Colors.red;
        final image = Qui3d.instance.build(
          ctx,
          (assets) => assets.box,
          color: testColor,
          width: 50,
        );

        expect(image.color, testColor);
      },
    );

    testWidgets(
      'with width, it should set the display width on the returned image',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_buildApp((c) => ctx = c));

        final image = Qui3d.instance.build(
          ctx,
          (assets) => assets.box,
          width: 75,
        );

        expect(image.width, 75);
      },
    );
  });
}
