import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import '../test_app.dart';

dynamic _findResistanceTransformRenderObject(WidgetTester tester) {
  return tester.renderObject(find.byType(QuiDragResistance));
}

void main() {
  group('QuiToast', () {
    testWidgets(
      'when shown, it should insert the message into the nearest overlay',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Something went wrong');
        await tester.pump();

        expect(find.text('Something went wrong'), findsOneWidget);
      },
    );

    testWidgets(
      'when another toast is shown, it should replace the visible message',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: QuiToastMessenger(
              child: Builder(
                builder: (context) {
                  toastContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'First error');
        await tester.pump();

        QuiToast.show(toastContext, message: 'Second error');
        await tester.pump();

        expect(find.text('First error'), findsNothing);
      },
    );

    testWidgets(
      'when tapping the toast, it should dismiss the visible message',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Tap me');
        await tester.pump();
        await tester.tap(find.byKey(const Key('qui_toast_surface')));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Tap me'), findsNothing);
      },
    );

    testWidgets(
      'when tapping the toast above another control, it should not pass the tap to the control below',
      (tester) async {
        late BuildContext toastContext;
        var tapCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: QuiTheme.light(),
            home: Scaffold(
              body: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: 220,
                        height: 58,
                        child: TextButton(
                          onPressed: () => tapCount += 1,
                          child: const Text('Under toast'),
                        ),
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      toastContext = context;
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Tap me');
        await tester.pump();
        await tester.tap(find.byKey(const Key('qui_toast_surface')));

        expect(tapCount, equals(0));
      },
    );

    testWidgets(
      'when a child overlay inserts an entry after the toast, it should keep the toast above that entry',
      (tester) async {
        final childOverlayKey = GlobalKey<OverlayState>();
        late BuildContext toastContext;
        var childOverlayTapCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: QuiTheme.light(),
            home: QuiToastMessenger(
              child: Overlay(
                key: childOverlayKey,
                initialEntries: [
                  OverlayEntry(
                    builder: (context) {
                      toastContext = context;
                      return const SizedBox.expand();
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Above heroes');
        await tester.pump();
        childOverlayKey.currentState!.insert(
          OverlayEntry(
            builder: (_) => Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => childOverlayTapCount += 1,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('qui_toast_surface')));

        expect(childOverlayTapCount, equals(0));
      },
    );

    testWidgets(
      'when holding the toast, it should scale the surface down slightly',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Hold me');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('qui_toast_gesture_target'))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final transition = tester.widget<ScaleTransition>(
          find.byKey(const Key('qui_toast_press_scale_transition')),
        );

        expect(transition.scale.value, equals(0.985));
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging the toast downward, it should move with strong resistance instead of staying capped',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Pull me');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('qui_toast_gesture_target'))),
        );
        await gesture.moveBy(const Offset(0, 18));
        await gesture.moveBy(const Offset(0, 96));
        await tester.pump();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(
          renderObject.currentResistanceOffset.dy,
          allOf(greaterThan(0), lessThan(7)),
        );
      },
    );

    testWidgets(
      'when dragging the toast sideways, it should move with strong resistance instead of staying capped',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Pull me');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('qui_toast_gesture_target'))),
        );
        await gesture.moveBy(const Offset(18, 0));
        await gesture.moveBy(const Offset(96, 0));
        await tester.pump();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(
          renderObject.currentResistanceOffset.dx,
          allOf(greaterThan(0), lessThan(7)),
        );
      },
    );

    testWidgets(
      'when dragging the toast back from a dismiss gesture, it should restore progress before applying resistance',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Pull me');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('qui_toast_gesture_target'))),
        );
        await gesture.moveBy(const Offset(0, -18));
        await gesture.moveBy(const Offset(0, -24));
        await gesture.moveBy(const Offset(0, 12));
        await tester.pump();
        final renderObject = _findResistanceTransformRenderObject(tester);

        expect(renderObject.currentResistanceOffset.dy, equals(0));
      },
    );

    testWidgets(
      'when swiping the toast upward, it should not restore full opacity before dismissing',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Swipe me');
        await tester.pump();
        await tester.fling(
          find.byKey(const Key('qui_toast_gesture_target')),
          const Offset(0, -80),
          1200,
        );
        final transition = tester.widget<FadeTransition>(
          find.byKey(const Key('qui_toast_fade_transition')),
        );

        expect(transition.opacity.value, lessThan(1));
      },
    );

    testWidgets(
      'when swiping the toast upward very fast, it should keep enough opacity for the dismiss animation',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Swipe me');
        await tester.pump();
        await tester.fling(
          find.byKey(const Key('qui_toast_gesture_target')),
          const Offset(0, -240),
          3000,
        );
        final transition = tester.widget<FadeTransition>(
          find.byKey(const Key('qui_toast_fade_transition')),
        );

        expect(transition.opacity.value, greaterThan(0.2));
      },
    );

    testWidgets(
      'when dragging the toast upward, it should dismiss the visible message',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Swipe me');
        await tester.pump();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('qui_toast_gesture_target'))),
        );
        await gesture.moveBy(const Offset(0, -18));
        await gesture.moveBy(const Offset(0, -96));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Swipe me'), findsNothing);
      },
    );

    testWidgets(
      'when shown, it should center the toast surface in the overlay',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'uh lala');
        await tester.pump();

        expect(
          tester.getCenter(find.byKey(const Key('qui_toast_surface'))).dx,
          equals(tester.getSize(find.byType(Overlay).first).width / 2),
        );
      },
    );

    testWidgets(
      'when shown with custom padding after the safe area, it should move the toast surface horizontally within the padded space',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(
          toastContext,
          message: 'uh lala',
          padding: const EdgeInsets.fromLTRB(36, 40, 4, 16),
        );
        await tester.pump();

        expect(
          tester.getCenter(find.byKey(const Key('qui_toast_surface'))).dx,
          equals(tester.getSize(find.byType(Overlay).first).width / 2 + 16),
        );
      },
    );

    testWidgets(
      'when an explicit duration completes, it should dismiss the toast',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(
          toastContext,
          message: 'Short error',
          duration: const Duration(milliseconds: 20),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Short error'), findsNothing);
      },
    );

    testWidgets(
      'when the timer fires while holding the toast, it should not dismiss until the finger releases',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(
          toastContext,
          message: 'Hold past timer',
          duration: const Duration(milliseconds: 2000),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('qui_toast_gesture_target'))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2500));

        expect(find.text('Hold past timer'), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Hold past timer'), findsNothing);
      },
    );

    testWidgets(
      'when holding the toast and releasing before the timer fires, it should not dismiss immediately',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(
          toastContext,
          message: 'Hold under timer',
          duration: const Duration(milliseconds: 5000),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('qui_toast_gesture_target'))),
        );
        await tester.pump(const Duration(milliseconds: 200));

        await gesture.up();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Hold under timer'), findsOneWidget);
      },
    );

    testWidgets(
      'when duration is computed for a short message, it should respect the minimum reading time',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'No');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2400));

        expect(find.text('No'), findsOneWidget);
      },
    );

    testWidgets(
      'when duration is computed for a short message and time passes, it should dismiss the toast',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'No');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3000));

        expect(find.text('No'), findsNothing);
      },
    );

    testWidgets(
      'when duration is computed for a long message, it should stay visible past the short minimum',
      (tester) async {
        late BuildContext toastContext;
        final longMessage = List.filled(32, 'long message').join(' ');

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: longMessage);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3000));

        expect(find.text(longMessage), findsOneWidget);
      },
    );

    testWidgets(
      'when duration is computed for a long message and the maximum passes, it should dismiss the toast',
      (tester) async {
        late BuildContext toastContext;
        final longMessage = List.filled(32, 'long message').join(' ');

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: longMessage);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 8500));

        expect(find.text(longMessage), findsNothing);
      },
    );

    testWidgets(
      'when rendered as error, it should resolve the toast error background color',
      (tester) async {
        await tester.pumpWidget(
          const TestApp(child: QuiToast(message: 'Error')),
        );

        final decoration = tester
            .widget<DecoratedBox>(find.byKey(const Key('qui_toast_surface')))
            .decoration;

        expect(
          (decoration as BoxDecoration).color,
          equals(QuiColorScheme.light().toast.error.background),
        );
      },
    );

    testWidgets(
      'when rendered as error, it should resolve the toast error foreground color',
      (tester) async {
        await tester.pumpWidget(
          const TestApp(child: QuiToast(message: 'Error')),
        );

        final text = tester.widget<Text>(
          find.byKey(const Key('qui_toast_message')),
        );

        expect(
          text.style?.color,
          equals(QuiColorScheme.light().toast.error.foreground),
        );
      },
    );

    testWidgets(
      'when rendered outside the material text tree, it should not inherit fallback text decoration',
      (tester) async {
        await tester.pumpWidget(
          const TestApp(child: QuiToast(message: 'Error')),
        );

        final text = tester.widget<Text>(
          find.byKey(const Key('qui_toast_message')),
        );

        expect(text.style?.decoration, equals(TextDecoration.none));
      },
    );

    testWidgets(
      'when shown from a custom QUI theme, it should use the caller toast error background color',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);

                return Theme(
                  data: theme.copyWith(
                    extensions: [
                      theme.extension<QuiThemeData>()!.copyWith(
                        colorScheme: QuiColorScheme.light().copyWith(
                          toast: _QuiToastTestFixtures.customToastColorScheme,
                        ),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      toastContext = context;
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Themed error');
        await tester.pump();

        final decoration = tester
            .widget<DecoratedBox>(find.byKey(const Key('qui_toast_surface')))
            .decoration;

        expect(
          (decoration as BoxDecoration).color,
          equals(_QuiToastTestFixtures.customToastColorScheme.error.background),
        );
      },
    );

    testWidgets(
      'when shown from a custom QUI theme, it should use the caller toast error foreground color',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);

                return Theme(
                  data: theme.copyWith(
                    extensions: [
                      theme.extension<QuiThemeData>()!.copyWith(
                        colorScheme: QuiColorScheme.light().copyWith(
                          toast: _QuiToastTestFixtures.customToastColorScheme,
                        ),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      toastContext = context;
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'Themed error');
        await tester.pump();

        final text = tester.widget<Text>(
          find.byKey(const Key('qui_toast_message')),
        );

        expect(
          text.style?.color,
          equals(_QuiToastTestFixtures.customToastColorScheme.error.foreground),
        );
      },
    );

    testWidgets(
      'when animations are disabled, it should render the toast fully visible immediately',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  toastContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        QuiToast.show(toastContext, message: 'No motion');
        await tester.pump();

        final transition = tester.widget<FadeTransition>(
          find.byKey(const Key('qui_toast_fade_transition')),
        );

        expect(transition.opacity.value, equals(1));
      },
    );

    testWidgets(
      'when a custom iconBuilder is provided, it should render the custom icon widget instead of the default one',
      (tester) async {
        await tester.pumpWidget(
          const TestApp(
            child: QuiToast(
              message: 'Custom icon',
              iconBuilder: _buildTestCustomIcon,
            ),
          ),
        );

        expect(find.byKey(const Key('qui_toast_custom_icon')), findsOneWidget);
      },
    );

    testWidgets(
      'when a custom iconBuilder is provided, it should pass the recommended icon size of 30px',
      (tester) async {
        double? capturedIconSize;

        await tester.pumpWidget(
          TestApp(
            child: QuiToast(
              message: 'Check size',
              iconBuilder: (state) {
                capturedIconSize = state.iconSize;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(capturedIconSize, equals(30));
      },
    );

    testWidgets(
      'when a custom iconBuilder is provided, it should pass the design-system icon color for the toast type',
      (tester) async {
        Color? capturedIconColor;

        await tester.pumpWidget(
          TestApp(
            child: QuiToast(
              message: 'Check color',
              iconBuilder: (state) {
                capturedIconColor = state.iconColor;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(
          capturedIconColor,
          equals(QuiColorScheme.light().toast.error.icon),
        );
      },
    );

    testWidgets(
      'when no iconBuilder is provided, it should render the default icon in the icon box',
      (tester) async {
        await tester.pumpWidget(
          const TestApp(child: QuiToast(message: 'Default icon')),
        );

        final iconBox = tester.widget<SizedBox>(
          find.byKey(const Key('qui_toast_icon_box')),
        );
        final child = iconBox.child;

        expect(child, isNotNull);
      },
    );

    testWidgets(
      'when QuiToast.show is called with an iconBuilder, it should render the custom icon in the overlay',
      (tester) async {
        late BuildContext toastContext;

        await tester.pumpWidget(
          TestApp(
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        QuiToast.show(
          toastContext,
          message: 'Custom overlay icon',
          iconBuilder: _buildTestCustomIcon,
        );
        await tester.pump();

        expect(find.byKey(const Key('qui_toast_custom_icon')), findsOneWidget);
      },
    );
  });
}

Widget _buildTestCustomIcon(QuiToastState state) {
  return SizedBox(
    key: const Key('qui_toast_custom_icon'),
    width: state.iconSize,
    height: state.iconSize,
    child: Icon(Icons.warning, color: state.iconColor, size: state.iconSize),
  );
}

abstract final class _QuiToastTestFixtures {
  static const customToastColorScheme = QuiToastColorScheme(
    success: QuiToastVariantColorScheme(
      background: Color(0xFF000001),
      foreground: Color(0xFF000002),
      icon: Color(0xFF000003),
    ),
    error: QuiToastVariantColorScheme(
      background: Color(0xFF123456),
      foreground: Color(0xFFABCDEF),
      icon: Color(0xFF654321),
    ),
    warning: QuiToastVariantColorScheme(
      background: Color(0xFF000004),
      foreground: Color(0xFF000005),
      icon: Color(0xFF000006),
    ),
    info: QuiToastVariantColorScheme(
      background: Color(0xFF000007),
      foreground: Color(0xFF000008),
      icon: Color(0xFF000009),
    ),
    neutral: QuiToastVariantColorScheme(
      background: Color(0xFF00000A),
      foreground: Color(0xFF00000B),
      icon: Color(0xFF00000C),
    ),
  );
}
