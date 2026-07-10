import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

void main() {
  group('QuiPrimaryButton', () {
    group('tap behavior', () {
      testWidgets('when tapped with a sync callback, it should invoke onPressed', (tester) async {
        var tapCount = 0;

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () => tapCount += 1),
          ),
        );

        await tester.tap(find.text('Ver oportunidades'));
        await tester.pump(const Duration(milliseconds: 800));

        expect(tapCount, equals(1));
      });

      testWidgets('when onPressed is null, tapping should not throw', (tester) async {
        await tester.pumpWidget(const TestApp(child: QuiPrimaryButton(label: 'Indisponivel')));

        await tester.tap(find.text('Indisponivel'));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('when onPressed returns a non-Future value, it should not enter loading state', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () {}),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await tester.pump(const Duration(milliseconds: 140));

        expect(find.byType(QuiDotLoadingIndicator), findsNothing);
      });

      testWidgets('when enabled, it should wrap in QuiTapAnimation with scaleFade animation', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
          ),
        );

        final animation = tester.widget<QuiTapAnimation>(
          find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(QuiTapAnimation)),
        );

        expect(animation.onPressed, isNotNull);
        expect(animation.animation, equals(QuiTapAnimationType.scaleFade));
      });

      testWidgets('when disabled, it should pass null onPressed to QuiTapAnimation', (tester) async {
        await tester.pumpWidget(const TestApp(child: QuiPrimaryButton(label: 'Indisponivel')));

        final animation = tester.widget<QuiTapAnimation>(
          find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(QuiTapAnimation)),
        );

        expect(animation.onPressed, isNull);
      });
    });

    group('semantics', () {
      testWidgets('when enabled, it should expose enabled semantics', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
          ),
        );

        final semantics = tester.widget<Semantics>(
          find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(Semantics)),
        );

        expect(semantics.properties.enabled, isTrue);
      });

      testWidgets('when disabled, it should expose disabled semantics', (tester) async {
        await tester.pumpWidget(const TestApp(child: QuiPrimaryButton(label: 'Indisponivel')));

        final semantics = tester.widget<Semantics>(
          find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(Semantics)),
        );

        expect(semantics.properties.enabled, isFalse);
      });
    });

    group('layout and sizing', () {
      testWidgets('when fit is fit, it should size to content', (tester) async {
        await tester.pumpWidget(
          const TestApp(
            child: QuiPrimaryButton(label: 'Encaixar', fit: QuiButtonFit.fit, onPressed: null),
          ),
        );

        final buttonWidth = tester.getSize(find.byKey(const Key('qui_primary_button_container'))).width;
        final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
        expect(buttonWidth, lessThan(screenWidth));
      });

      testWidgets('when fit is expand, it should fill the available width', (tester) async {
        await tester.pumpWidget(
          const TestApp(
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(label: 'Expandir', fit: QuiButtonFit.expand, onPressed: null),
            ),
          ),
        );

        expect(tester.getSize(find.byKey(const Key('qui_primary_button_container'))).width, equals(300));
      });

      testWidgets('when fit is expand in a tall parent, it should not fill the available height', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
              child: const QuiPrimaryButton(label: 'Expandir', fit: QuiButtonFit.expand, onPressed: null),
            ),
          ),
        );

        expect(tester.getSize(find.byKey(const Key('qui_primary_button_container'))).height, lessThan(200));
      });

      testWidgets('when padding is customized, it should use the provided content padding', (tester) async {
        await tester.pumpWidget(
          const TestApp(
            child: QuiPrimaryButton(
              label: 'Compacto',
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: null,
            ),
          ),
        );

        expect(_buttonPadding(tester), equals(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)));
      });

      testWidgets('when padding uses the default, it should apply symmetric 20x12', (tester) async {
        await tester.pumpWidget(
          const TestApp(
            child: QuiPrimaryButton(label: 'Padrao', onPressed: null),
          ),
        );

        expect(_buttonPadding(tester), equals(const EdgeInsets.symmetric(horizontal: 20, vertical: 12)));
      });
    });

    group('background colors', () {
      testWidgets('when background is not customized, it should use the primary color', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
          ),
        );

        expect(_buttonBackgroundColor(tester), equals(const Color(0xFFFF4A4B)));
      });

      testWidgets('when background is customized, it should use the provided color', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Mapa', backgroundColor: const Color(0xFF00A676), onPressed: () {}),
          ),
        );

        expect(_buttonBackgroundColor(tester), equals(const Color(0xFF00A676)));
      });

      testWidgets('when disabled, it should use the disabled background color', (tester) async {
        await tester.pumpWidget(const TestApp(child: QuiPrimaryButton(label: 'Indisponivel')));

        expect(_buttonBackgroundColor(tester), equals(const Color(0xFFE1E1E1)));
      });

      testWidgets('when disabled background is customized, it should use the provided color', (tester) async {
        await tester.pumpWidget(
          const TestApp(
            child: QuiPrimaryButton(label: 'Fechado', disabledBackgroundColor: Color(0xFFDDDDDD)),
          ),
        );

        expect(_buttonBackgroundColor(tester), equals(const Color(0xFFDDDDDD)));
      });
    });

    group('foreground colors', () {
      testWidgets('when foreground is not customized, it should use white as the label color', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
          ),
        );

        expect(_labelStyle(tester).color, equals(Colors.white));
      });

      testWidgets('when foreground is customized, it should use the provided color as the label color', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Salvar', foregroundColor: const Color(0xFF1A1A1A), onPressed: () {}),
          ),
        );

        final style = tester.widget<Text>(find.text('Salvar')).style!;
        expect(style.color, equals(const Color(0xFF1A1A1A)));
      });

      testWidgets('when disabled, it should use the disabled foreground color', (tester) async {
        await tester.pumpWidget(const TestApp(child: QuiPrimaryButton(label: 'Indisponivel')));

        final style = tester.widget<Text>(find.text('Indisponivel')).style!;
        expect(style.color, equals(const Color(0xFF8E8E8E)));
      });
    });

    group('icon builders', () {
      testWidgets('when leading icon spacing is customized, it should use the provided spacing', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Buscar',
              leadingIconBuilder: (state) => const Icon(Icons.search),
              leadingIconSpacing: 10,
              onPressed: () {},
            ),
          ),
        );

        final padding = tester.widget<Padding>(find.descendant(of: find.byType(Row), matching: find.byType(Padding)));

        expect(padding.padding, equals(const EdgeInsets.only(right: 10)));
      });

      testWidgets('when trailing icon spacing is customized, it should use the provided spacing', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Continuar',
              trailingIconBuilder: (state) => const Icon(Icons.arrow_forward),
              trailingIconSpacing: 12,
              onPressed: () {},
            ),
          ),
        );

        final padding = tester.widget<Padding>(find.descendant(of: find.byType(Row), matching: find.byType(Padding)));

        expect(padding.padding, equals(const EdgeInsets.only(left: 12)));
      });

      testWidgets('when leading icon spacing is default, it should use 8px', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Buscar',
              leadingIconBuilder: (state) => const Icon(Icons.search),
              onPressed: () {},
            ),
          ),
        );

        final padding = tester.widget<Padding>(find.descendant(of: find.byType(Row), matching: find.byType(Padding)));

        expect(padding.padding, equals(const EdgeInsets.only(right: 8)));
      });

      testWidgets('when enabled, it should pass the foreground color to leadingIconBuilder', (tester) async {
        Color? foregroundColor;

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Buscar',
              foregroundColor: const Color(0xFFFF4A4B),
              leadingIconBuilder: (state) {
                foregroundColor = state.foregroundColor;
                return const Icon(Icons.search);
              },
              onPressed: () {},
            ),
          ),
        );

        expect(foregroundColor, equals(const Color(0xFFFF4A4B)));
      });

      testWidgets('when disabled, it should pass disabled state to leadingIconBuilder', (tester) async {
        bool? isEnabled;

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Indisponivel',
              leadingIconBuilder: (state) {
                isEnabled = state.isEnabled;
                return const Icon(Icons.lock);
              },
            ),
          ),
        );

        expect(isEnabled, isFalse);
      });

      testWidgets('when disabled, it should pass disabled foreground color to leadingIconBuilder', (tester) async {
        Color? foregroundColor;

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Indisponivel',
              leadingIconBuilder: (state) {
                foregroundColor = state.foregroundColor;
                return const Icon(Icons.lock);
              },
            ),
          ),
        );

        expect(foregroundColor, equals(const Color(0xFF8E8E8E)));
      });

      testWidgets('when both icons are provided, it should render three children in the row', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Filtrar',
              leadingIconBuilder: (state) => const Icon(Icons.tune),
              trailingIconBuilder: (state) => const Icon(Icons.arrow_drop_down),
              onPressed: () {},
            ),
          ),
        );

        final row = tester.widget<Row>(find.byType(Row));
        expect(row.children.length, equals(3));
      });

      testWidgets('when both icons are provided, it should render the leading icon', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Filtrar',
              leadingIconBuilder: (state) => const Icon(Icons.tune),
              trailingIconBuilder: (state) => const Icon(Icons.arrow_drop_down),
              onPressed: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.tune), findsOneWidget);
      });

      testWidgets('when both icons are provided, it should render the trailing icon', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Filtrar',
              leadingIconBuilder: (state) => const Icon(Icons.tune),
              trailingIconBuilder: (state) => const Icon(Icons.arrow_drop_down),
              onPressed: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      });

      testWidgets('when only trailing icon is provided, it should render the label and trailing icon', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Continuar',
              trailingIconBuilder: (state) => const Icon(Icons.arrow_forward),
              onPressed: () {},
            ),
          ),
        );

        expect(find.text('Continuar'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('when only leading icon is provided, it should render the label and leading icon', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Voltar',
              leadingIconBuilder: (state) => const Icon(Icons.arrow_back),
              onPressed: () {},
            ),
          ),
        );

        expect(find.text('Voltar'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });

    group('loading states', () {
      testWidgets('when tapped with a pending future, it should show the loading indicator after the delay', (
        tester,
      ) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () => completer.future),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await _pumpLoadingState(tester);

        expect(find.byType(QuiDotLoadingIndicator), findsOneWidget);
      });

      testWidgets('when the pending future completes, it should restore the label content', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () => completer.future),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await _pumpLoadingState(tester);
        completer.complete();
        await _pumpContentRestoredState(tester);

        expect(find.text('Salvar agora'), findsOneWidget);
      });

      testWidgets('when loading, it should hide the label text', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () => completer.future),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await _pumpLoadingState(tester);

        expect(find.text('Salvar agora'), findsNothing);
      });

      testWidgets('when loading, it should ignore a second tap', (tester) async {
        final completer = Completer<void>();
        var tapCount = 0;

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Salvar agora',
              onPressed: () {
                tapCount += 1;
                return completer.future;
              },
            ),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await tester.pump(const Duration(milliseconds: 51));
        await tester.tap(find.byKey(const Key('qui_primary_button_container')));
        await tester.pump();
        completer.complete();
        await _pumpContentRestoredState(tester);

        expect(tapCount, equals(1));
      });

      testWidgets('when loading with custom foreground color, it should pass that color to the loading indicator', (
        tester,
      ) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Salvar agora',
              foregroundColor: const Color(0xFF1A1A1A),
              onPressed: () => completer.future,
            ),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await _pumpLoadingState(tester);

        expect(_loadingIndicator(tester).color, equals(const Color(0xFF1A1A1A)));
      });

      testWidgets('when operation completes during loading delay, it should skip the loading state', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Rapido', onPressed: () => completer.future),
          ),
        );

        await tester.tap(find.text('Rapido'));
        completer.complete();
        await tester.pump(const Duration(milliseconds: 60));

        expect(find.byType(QuiDotLoadingIndicator), findsNothing);
        expect(find.text('Rapido'), findsOneWidget);
      });

      testWidgets('when rapidly tapped multiple times while pending, later taps should be ignored', (
        tester,
      ) async {
        final firstCompleter = Completer<void>();
        var callCount = 0;

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Enviar',
              onPressed: () {
                callCount += 1;
                return firstCompleter.future;
              },
            ),
          ),
        );

        await tester.tap(find.text('Enviar'));
        await tester.pump(const Duration(milliseconds: 20));
        await tester.tap(find.byKey(const Key('qui_primary_button_container')));
        await tester.pump(const Duration(milliseconds: 60));

        firstCompleter.complete();
        await _pumpContentRestoredState(tester);

        expect(callCount, equals(1));
        expect(find.text('Enviar'), findsOneWidget);
      });
    });

    group('loading resize behavior', () {
      testWidgets('when fit is fit and loading, it should animate to a narrower width', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Enviar candidatura completa', onPressed: () => completer.future),
          ),
        );

        final restingWidth = tester.getSize(find.byKey(const Key('qui_primary_button_container'))).width;
        await tester.tap(find.text('Enviar candidatura completa'));
        await _pumpLoadingState(tester);
        await tester.pump(const Duration(milliseconds: 300));
        final loadingWidth = tester.getSize(find.byKey(const Key('qui_primary_button_container'))).width;

        expect(loadingWidth, lessThan(restingWidth));
      });

      testWidgets('when fit is expand and loading, it should keep the expanded width', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Enviar candidatura completa',
                fit: QuiButtonFit.expand,
                onPressed: () => completer.future,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Enviar candidatura completa'));
        await _pumpLoadingState(tester);
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.getSize(find.byKey(const Key('qui_primary_button_container'))).width, equals(300));
      });

      testWidgets('when loading completes, it should transition through overlay state', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Salvar agora',
              onPressed: () => completer.future,
            ),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await _pumpLoadingState(tester);
        completer.complete();
        await _pumpContentRestoredState(tester);

        expect(find.byType(QuiDotLoadingIndicator), findsNothing);
        expect(find.text('Salvar agora'), findsOneWidget);
      });

      testWidgets('when an icon button is shrinking into loading, it should not overflow mid animation', (
        tester,
      ) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Ligar agora',
              leadingIconBuilder: (state) => const SizedBox.square(dimension: 24),
              onPressed: () => completer.future,
            ),
          ),
        );

        await tester.tap(find.text('Ligar agora'));
        await _pumpLoadingState(tester);

        expect(tester.takeException(), isNull);
      });

      testWidgets('when loading completes while expanding back to icon content, it should not clip mid animation', (
        tester,
      ) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(
              label: 'Ligar agora',
              leadingIconBuilder: (state) => const SizedBox.square(dimension: 24),
              onPressed: () => completer.future,
            ),
          ),
        );

        await tester.tap(find.text('Ligar agora'));
        await _pumpLoadingState(tester);
        completer.complete();
        await tester.pump(const Duration(milliseconds: 120));
        final exception = tester.takeException();
        await _pumpContentRestoredState(tester);

        expect(exception, isNull);
      });
    });

    group('content fade animation', () {
      testWidgets('when loading completes, it should fade content in without dropping opacity', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () => completer.future),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await _pumpLoadingState(tester);
        completer.complete();
        await tester.pump(const Duration(milliseconds: 226));
        final firstOpacity = _contentFadeOpacity(tester);
        await tester.pump(const Duration(milliseconds: 45));
        final secondOpacity = _contentFadeOpacity(tester);
        await tester.pump(const Duration(milliseconds: 45));
        final thirdOpacity = _contentFadeOpacity(tester);

        expect(firstOpacity <= secondOpacity && secondOpacity <= thirdOpacity, isTrue);
      });
    });

    group('animations disabled', () {
      testWidgets('when animations are disabled and loading, it should switch content without AnimatedSize', (
        tester,
      ) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () => completer.future),
            ),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await tester.pump(const Duration(milliseconds: 60));

        expect(find.byType(AnimatedSize), findsNothing);
      });

      testWidgets('when animations are disabled and loading restores, it should restore instantly', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () => completer.future),
            ),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await tester.pump(const Duration(milliseconds: 60));
        completer.complete();
        await tester.pump();
        await tester.pump();

        expect(find.text('Salvar agora'), findsOneWidget);
        expect(find.byType(QuiDotLoadingIndicator), findsNothing);
      });
    });

    group('lifecycle', () {
      testWidgets('when the widget is unmounted before the future completes, it should not call setState', (
        tester,
      ) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () => completer.future),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await _pumpLoadingState(tester);

        await tester.pumpWidget(const SizedBox.shrink());

        completer.complete();
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('when the widget is unmounted during loading delay, it should not call setState', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          TestApp(
            child: QuiPrimaryButton(label: 'Salvar agora', onPressed: () => completer.future),
          ),
        );

        await tester.tap(find.text('Salvar agora'));
        await tester.pump(const Duration(milliseconds: 30));

        await tester.pumpWidget(const SizedBox.shrink());

        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      });
    });

    group('alignment', () {
      testWidgets('when alignment is left with expand, it should align content to the left', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Esquerda',
                fit: QuiButtonFit.expand,
                alignment: QuiButtonAlignment.left,
                onPressed: () {},
              ),
            ),
          ),
        );

        final align = tester.widget<Align>(
          find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(Align)),
        );

        expect(align.alignment, equals(Alignment.centerLeft));
      });

      testWidgets('when alignment is right with expand, it should align content to the right', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Direita',
                fit: QuiButtonFit.expand,
                alignment: QuiButtonAlignment.right,
                onPressed: () {},
              ),
            ),
          ),
        );

        final align = tester.widget<Align>(
          find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(Align)),
        );

        expect(align.alignment, equals(Alignment.centerRight));
      });

      testWidgets('when alignment is center with expand, it should align content to the center', (tester) async {
        await tester.pumpWidget(
          TestApp(
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Centro',
                fit: QuiButtonFit.expand,
                alignment: QuiButtonAlignment.center,
                onPressed: () {},
              ),
            ),
          ),
        );

        final align = tester.widget<Align>(
          find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(Align)),
        );

        expect(align.alignment, equals(Alignment.center));
      });
    });
  });
}

Color? _buttonBackgroundColor(WidgetTester tester) {
  final decorated = tester.widget<DecoratedBox>(
    find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(DecoratedBox)),
  );
  return (decorated.decoration as BoxDecoration).color;
}

EdgeInsetsGeometry? _buttonPadding(WidgetTester tester) {
  return tester.widget<Padding>(
    find.byKey(const Key('qui_primary_button_container')),
  ).padding;
}

TextStyle _labelStyle(WidgetTester tester) {
  return tester.widget<Text>(find.text('Ver oportunidades')).style!;
}

QuiDotLoadingIndicator _loadingIndicator(WidgetTester tester) {
  return tester.widget<QuiDotLoadingIndicator>(find.byType(QuiDotLoadingIndicator));
}

double _contentFadeOpacity(WidgetTester tester) {
  final fadeTransitions = tester
      .widgetList<FadeTransition>(find.ancestor(of: find.text('Salvar agora'), matching: find.byType(FadeTransition)))
      .toList();

  return fadeTransitions.map((fadeTransition) => fadeTransition.opacity.value).reduce(math.min);
}

Future<void> _pumpLoadingState(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 60));
  for (var i = 0; i < 19; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump();
}

Future<void> _pumpContentRestoredState(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 226));
  for (var i = 0; i < 19; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump();
}
