import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHero.group', () {
    testWidgets('when built under a column, it should lay out heroes vertically', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                QuiHero.group(
                  tag: 'group',
                  heroes: [
                    QuiHero.text(text: 'Hello'),
                    QuiHero.text(text: 'Hola'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('Hola')).dy > tester.getTopLeft(find.text('Hello')).dy, isTrue);
    });

    testWidgets('when built under a row, it should lay out heroes horizontally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                QuiHero.group(
                  tag: 'group',
                  heroes: [
                    QuiHero.text(text: 'Hello'),
                    QuiHero.text(text: 'Hola'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('Hola')).dx > tester.getTopLeft(find.text('Hello')).dx, isTrue);
    });

    testWidgets('when built under a stack, it should lay out heroes as a stack', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                QuiHero.group(
                  tag: 'group',
                  heroes: [
                    QuiHero.text(text: 'Hello'),
                    QuiHero.text(text: 'Hola'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('Hola')), equals(tester.getTopLeft(find.text('Hello'))));
    });

    testWidgets('when built with grouped heroes, it should render one Flutter Hero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                QuiHero.group(
                  tag: 'group',
                  heroes: [
                    QuiHero.text(text: 'Hello', padding: const EdgeInsets.only(bottom: 4)),
                    QuiHero.text(text: 'Hola'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('when built under a bounded column, it should reserve the full column width for the flight', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Column(
                children: [
                  QuiHero.group(
                    tag: 'group',
                    heroes: [
                      QuiHero.text(text: 'Hello'),
                      QuiHero.text(text: 'Hola'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(Hero)).width, equals(300));
    });

    testWidgets(
      'when source and destination hero counts do not match, it should match by min length without throwing',
      (tester) async {
        await tester.pumpWidget(const _MismatchedGroupTestApp());
        await tester.tap(find.text('Hello'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('when source and destination hero types differ at an index, it should not throw an assertion error', (
      tester,
    ) async {
      await tester.pumpWidget(const _TypeMismatchGroupTestApp());
      await tester.tap(find.byKey(_TypeMismatchGroupTestApp.sourceKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(tester.takeException(), isNot(isAssertionError));
    });

    testWidgets(
      'when a grouped title flies from a narrow card to a wide card, it should wrap inside the flight width',
      (tester) async {
        await tester.pumpWidget(const _GroupedTitleFlightWidthTestApp());
        await tester.tap(find.text(_GroupedTitleFlightWidthTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(_GroupedTitleFlightWidthTestApp.hasTitleOverflow(tester), isFalse);
      },
    );

    testWidgets('when a grouped title pops from a wide card, it should stay on one line while the flight is wide', (
      tester,
    ) async {
      await tester.pumpWidget(const _GroupedTitlePopWidthTestApp());
      await tester.tap(find.text(_GroupedTitlePopWidthTestApp.title));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text(_GroupedTitlePopWidthTestApp.title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(_GroupedTitlePopWidthTestApp.hasTwoLineFlightTitle(tester), isFalse);
    });

    testWidgets(
      'when a grouped full description pops back to a card summary, it should progressively reduce visible lines',
      (tester) async {
        await tester.pumpWidget(const _GroupedDescriptionPopLineClampTestApp());
        await tester.tap(find.text(_GroupedDescriptionPopLineClampTestApp.summary));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.text(_GroupedDescriptionPopLineClampTestApp.description));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        final firstFrameMaxLines = _GroupedDescriptionPopLineClampTestApp.flightDescriptionMaxLines(tester);

        await tester.pump(const Duration(milliseconds: 32));

        final secondFrameMaxLines = _GroupedDescriptionPopLineClampTestApp.flightDescriptionMaxLines(tester);
        expect(
          secondFrameMaxLines < firstFrameMaxLines,
          isTrue,
          reason: 'firstFrameMaxLines=$firstFrameMaxLines secondFrameMaxLines=$secondFrameMaxLines',
        );
      },
    );

    testWidgets(
      'when a grouped header opens to lower detail text, it should move the title and payment down toward the detail screen',
      (tester) async {
        await tester.pumpWidget(const _GroupedHeaderVerticalOffsetTestApp());

        final sourceTitleTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.title,
        );
        final sourcePaymentTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.payment,
        );

        await tester.tap(find.text(_GroupedHeaderVerticalOffsetTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final flightTitleTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.title,
        );
        final flightPaymentTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.payment,
        );

        await tester.pumpAndSettle();

        final destinationTitleTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.title,
        );
        final destinationPaymentTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.payment,
        );

        expect((
          sourceTitleTop < flightTitleTop,
          flightTitleTop < destinationTitleTop,
          sourcePaymentTop < flightPaymentTop,
          flightPaymentTop < destinationPaymentTop,
        ), equals((true, true, true, true)));
      },
    );

    testWidgets(
      'when a grouped header closes to higher card text, it should move the title and payment up toward the card',
      (tester) async {
        await tester.pumpWidget(const _GroupedHeaderVerticalOffsetTestApp());

        final sourceTitleTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.title,
        );
        final sourcePaymentTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.payment,
        );

        await tester.tap(find.text(_GroupedHeaderVerticalOffsetTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();

        final destinationTitleTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.title,
        );
        final destinationPaymentTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.payment,
        );

        await tester.tap(find.text(_GroupedHeaderVerticalOffsetTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final flightTitleTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.title,
        );
        final flightPaymentTop = _GroupedHeaderVerticalOffsetTestApp.textTop(
          tester,
          _GroupedHeaderVerticalOffsetTestApp.payment,
        );

        expect((
          sourceTitleTop < flightTitleTop,
          flightTitleTop < destinationTitleTop,
          sourcePaymentTop < flightPaymentTop,
          flightPaymentTop < destinationPaymentTop,
        ), equals((true, true, true, true)));
      },
    );

    testWidgets(
      'when a grouped header title closes with enough card width, it should rewrap from two lines to one line during the flight',
      (tester) async {
        await tester.pumpWidget(const _GroupedHeaderDynamicWrapTestApp());
        await tester.tap(find.text(_GroupedHeaderDynamicWrapTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.text(_GroupedHeaderDynamicWrapTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 360));

        expect(_GroupedHeaderDynamicWrapTestApp.flightTitleLineCount(tester), equals(1));
      },
    );

    testWidgets(
      'when a grouped title opens into multiple lines, it should move the payment below the title during the flight',
      (tester) async {
        await tester.pumpWidget(const _GroupedHeaderSiblingWrapTestApp());
        await tester.tap(find.text(_GroupedHeaderSiblingWrapTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));

        final sample = _GroupedHeaderSiblingWrapTestApp.flightSample(tester);

        expect(
          (sample.titleLineCount >= 2, sample.paymentTop >= sample.titleBottom - 6),
          equals((true, true)),
          reason: 'sample=$sample',
        );
      },
    );

    testWidgets(
      'when a grouped title needs two card lines and three detail lines, it should not add a fourth line or ellipsis during the flight',
      (tester) async {
        await tester.pumpWidget(const _GroupedHeaderEndpointLineCeilingTestApp());
        await tester.tap(find.text(_GroupedHeaderEndpointLineCeilingTestApp.title));
        await tester.pump();

        final samples = <({bool hasEllipsis, int lineCount})>[];
        var elapsed = Duration.zero;

        for (final sample in _GroupedHeaderEndpointLineCeilingTestApp.samples) {
          await tester.pump(sample - elapsed);
          elapsed = sample;
          samples.add(_GroupedHeaderEndpointLineCeilingTestApp.titleFlightSample(tester));
        }

        expect(
          (samples.every((sample) => sample.lineCount <= 3), samples.every((sample) => !sample.hasEllipsis)),
          equals((true, true)),
          reason: 'samples=$samples',
        );
      },
    );

    testWidgets(
      'when a grouped title would paint past the hero edge, it should wrap without ellipsis during the flight',
      (tester) async {
        await tester.pumpWidget(const _GroupedHeaderBorderWrapTestApp());
        await tester.tap(find.text(_GroupedHeaderBorderWrapTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));

        final sample = _GroupedHeaderBorderWrapTestApp.titleFlightSample(tester);

        expect((sample.lineCount >= 2, sample.hasEllipsis), equals((true, false)), reason: 'sample=$sample');
      },
    );

    testWidgets(
      'when a grouped title is closing before one-line space is available, it should stay wrapped without ellipsis',
      (tester) async {
        await tester.pumpWidget(const _GroupedHeaderBorderWrapTestApp());
        await tester.tap(find.text(_GroupedHeaderBorderWrapTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.text(_GroupedHeaderBorderWrapTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final sample = _GroupedHeaderBorderWrapTestApp.titleFlightSample(tester);

        expect((sample.lineCount >= 2, sample.hasEllipsis), equals((true, false)), reason: 'sample=$sample');
      },
    );

    testWidgets('when a grouped header title finishes closing, it should keep the same height when the card settles', (
      tester,
    ) async {
      await tester.pumpWidget(const _GroupedHeaderDynamicWrapTestApp());
      await tester.tap(find.text(_GroupedHeaderDynamicWrapTestApp.title));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text(_GroupedHeaderDynamicWrapTestApp.title));
      await tester.pump();
      await tester.pump(QuiHeroPage.defaultReverseTransitionDuration - const Duration(milliseconds: 1));

      final flightHeight = _GroupedHeaderDynamicWrapTestApp.titleHeight(tester);

      await tester.pumpAndSettle();

      final settledHeight = _GroupedHeaderDynamicWrapTestApp.titleHeight(tester);

      expect((flightHeight - settledHeight).abs() < 2, isTrue);
    });

    testWidgets('when a grouped title changes font size while closing, it should avoid sudden painted baseline jumps', (
      tester,
    ) async {
      await tester.pumpWidget(const _GroupedHeaderBaselineTestApp());

      await tester.tap(find.text(_GroupedHeaderBaselineTestApp.title));
      await tester.pump();
      await tester.pumpAndSettle();

      final baselines = <double>[];
      var elapsed = Duration.zero;

      await tester.tap(find.text(_GroupedHeaderBaselineTestApp.title));
      await tester.pump();

      for (final sample in _GroupedHeaderBaselineTestApp.samples) {
        await tester.pump(sample - elapsed);
        elapsed = sample;
        baselines.add(_GroupedHeaderBaselineTestApp.titleBaseline(tester));
      }

      final deltas = [
        for (var index = 1; index < baselines.length; index += 1) baselines[index] - baselines[index - 1],
      ];
      final magnitudes = deltas.map((delta) => delta.abs()).toList();
      final isAlwaysMovingTowardCard = deltas.every((delta) => delta < 0);
      final hasNoMidFlightSpike = [
        for (var index = 2; index < magnitudes.length; index += 1) magnitudes[index] <= magnitudes[index - 1] + 0.5,
      ].every((isSmooth) => isSmooth);

      expect(
        (isAlwaysMovingTowardCard, hasNoMidFlightSpike),
        equals((true, true)),
        reason: 'baselines=$baselines deltas=$deltas',
      );
    });
  });

  group('QuiHero optional tags', () {
    testWidgets('when a single text hero omits the tag on both routes, it should animate without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(const _SingleUntaggedTextHeroTestApp());
      await tester.tap(find.text('Hello'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('when a single box hero omits the tag on both routes, it should animate without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(const _SingleUntaggedBoxHeroTestApp());
      await tester.tap(find.byKey(_SingleUntaggedBoxHeroTestApp.sourceKey));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('when a single group hero omits the tag on both routes, it should animate without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(const _SingleUntaggedGroupHeroTestApp());
      await tester.tap(find.text('Hello'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('when one tagless text box and group are on both routes, it should animate every variant', (
      tester,
    ) async {
      await tester.pumpWidget(const _MixedUntaggedHeroVariantsTestApp());
      await tester.tap(find.text('Hello'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('when multiple untagged text heroes are on one route, it should assert during navigation', (
      tester,
    ) async {
      await tester.pumpWidget(const _MultipleUntaggedTextHeroesTestApp());
      await tester.tap(find.text('Hello'));
      await tester.pump();

      expect(tester.takeException(), isNotNull);
    });

    testWidgets('when multiple untagged group heroes are on one route, it should assert during navigation', (
      tester,
    ) async {
      await tester.pumpWidget(const _MultipleUntaggedGroupHeroesTestApp());
      await tester.tap(find.text('Hello'));
      await tester.pump();

      expect(tester.takeException(), isNotNull);
    });

    testWidgets('when multiple text heroes use explicit tags, it should animate without throwing', (tester) async {
      await tester.pumpWidget(const _MultipleExplicitTextHeroesTestApp());
      await tester.tap(find.text('Hello'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

class _MismatchedGroupTestApp extends StatelessWidget {
  const _MismatchedGroupTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push<void>(MaterialPageRoute<void>(builder: _MismatchedGroupTestApp.buildDestination));
                },
                child: QuiHero.group(
                  tag: 'group',
                  heroes: [QuiHero.text(text: 'Hello')],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          QuiHero.group(
            tag: 'group',
            heroes: [
              QuiHero.text(text: 'Hello'),
              QuiHero.text(text: 'Hola'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupedTitleFlightWidthTestApp extends StatelessWidget {
  const _GroupedTitleFlightWidthTestApp();

  static const title = 'Oficial Mecanico de Refrigeracao Veicular';

  static bool hasTitleOverflow(WidgetTester tester) {
    final titleRects = find
        .text(title, skipOffstage: false)
        .evaluate()
        .map((element) => element.renderObject)
        .whereType<RenderBox>()
        .where((renderBox) => renderBox.hasSize)
        .map((renderBox) => renderBox.localToGlobal(Offset.zero) & renderBox.size);

    return titleRects.any((rect) => rect.left < -1 || rect.right > 181);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(builder: _GroupedTitleFlightWidthTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(
                width: 180,
                child: _GroupedTitleFlightWidthTestAppHeader(title: _GroupedTitleFlightWidthTestApp.title),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return const Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 360, child: _GroupedTitleFlightWidthTestAppHeader(title: 'Detalhes da oportunidade')),
      ),
    );
  }
}

class _GroupedTitleFlightWidthTestAppHeader extends StatelessWidget {
  const _GroupedTitleFlightWidthTestAppHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'group',
          heroes: [
            QuiHero.text(text: '2 dias atras', style: const TextStyle(fontSize: 14)),
            QuiHero.text(
              text: title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            QuiHero.text(text: r'R$3.800/mes', style: const TextStyle(fontSize: 25)),
          ],
        ),
      ],
    );
  }
}

class _GroupedTitlePopWidthTestApp extends StatelessWidget {
  const _GroupedTitlePopWidthTestApp();

  static const title = 'Instrumentista';

  static bool hasTwoLineFlightTitle(WidgetTester tester) {
    final titleRects = find
        .text(title, skipOffstage: false)
        .evaluate()
        .map((element) => element.renderObject)
        .whereType<RenderBox>()
        .where((renderBox) => renderBox.hasSize)
        .map((renderBox) => renderBox.localToGlobal(Offset.zero) & renderBox.size)
        .toList();

    return titleRects.any((rect) => rect.width > 260 && rect.height > 30);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(builder: _GroupedTitlePopWidthTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 180, child: _GroupedTitlePopWidthTestAppHeader(width: 180, fontSize: 20)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(width: 360, child: _GroupedTitlePopWidthTestAppHeader(width: 360, fontSize: 20)),
        ),
      ),
    );
  }
}

class _GroupedTitlePopWidthTestAppHeader extends StatelessWidget {
  const _GroupedTitlePopWidthTestAppHeader({required this.width, required this.fontSize});

  final double width;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          child: QuiHero.group(
            tag: 'pop-group',
            heroes: [
              QuiHero.text(text: '2 dias atras', style: const TextStyle(fontSize: 14)),
              QuiHero.text(
                text: _GroupedTitlePopWidthTestApp.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
              ),
              QuiHero.text(text: r'R$2.100/mes', style: const TextStyle(fontSize: 25)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupedDescriptionPopLineClampTestApp extends StatelessWidget {
  const _GroupedDescriptionPopLineClampTestApp();

  static const summary =
      'Empresa esta contratando Instrumentista para atuar no Jaragua, em Sao Paulo. Jornada de segunda a sexta.';
  static const description =
      'Empresa esta contratando Instrumentista para atuar no Jaragua, em Sao Paulo. A jornada ocorre de segunda a sexta, '
      'das 07h30 as 17h18, com 1 hora de intervalo. A oportunidade e destinada ao publico masculino. O profissional '
      'sera responsavel por realizar testes de recepcao para identificar possiveis falhas nos instrumentos, identificar '
      'instrumentos e pecas conforme codigo interno, executar desmontagem, inspecao e avaliacao dos componentes, '
      'efetuar ajustes, substituicao de reparos, montagem e testes funcionais, alem de realizar instalacao, calibracao '
      'e regulagem dos instrumentos conforme especificacoes tecnicas dos equipamentos.';

  static int flightDescriptionMaxLines(WidgetTester tester) {
    return tester
        .widgetList<Text>(find.text(description, skipOffstage: false))
        .map((text) => text.maxLines ?? 999)
        .reduce(math.min);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(
                    builder: _GroupedDescriptionPopLineClampTestApp.buildDestination,
                  ).createRoute(context),
                );
              },
              child: const SizedBox(width: 300, child: _GroupedDescriptionHeader(description: summary, maxLines: 3)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(width: 300, child: _GroupedDescriptionHeader(description: description)),
        ),
      ),
    );
  }
}

class _GroupedDescriptionHeader extends StatelessWidget {
  const _GroupedDescriptionHeader({required this.description, this.maxLines});

  final String description;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'description-group',
          heroes: [
            QuiHero.text(text: '17h atras', style: const TextStyle(fontSize: 14)),
            QuiHero.text(
              text: 'Instrumentista',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
            ),
            QuiHero.text(text: r'R$4.000/mes', style: const TextStyle(fontSize: 30)),
            QuiHero.text(
              text: description,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              switchThreshold: 0.8,
              style: const TextStyle(fontSize: 18, height: 1.38, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupedHeaderVerticalOffsetTestApp extends StatelessWidget {
  const _GroupedHeaderVerticalOffsetTestApp();

  static const title = 'Vendedora de Loja';
  static const payment = r'R$150/dia';

  static double textTop(WidgetTester tester, String text) {
    return tester.getTopLeft(find.text(text, skipOffstage: false).last).dy;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(builder: _GroupedHeaderVerticalOffsetTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 300, child: _GroupedHeaderVerticalOffsetHeader(isDetail: false)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(width: 300, child: _GroupedHeaderVerticalOffsetHeader(isDetail: true)),
        ),
      ),
    );
  }
}

class _GroupedHeaderVerticalOffsetHeader extends StatelessWidget {
  const _GroupedHeaderVerticalOffsetHeader({required this.isDetail});

  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'vertical-offset-group',
          heroes: [
            QuiHero.text(
              text: '20h atras',
              style: TextStyle(fontSize: isDetail ? 16 : 14, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.only(bottom: 6),
            ),
            QuiHero.text(
              text: _GroupedHeaderVerticalOffsetTestApp.title,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
            QuiHero.text(
              text: _GroupedHeaderVerticalOffsetTestApp.payment,
              style: TextStyle(fontSize: isDetail ? 30 : 25, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupedHeaderDynamicWrapTestApp extends StatelessWidget {
  const _GroupedHeaderDynamicWrapTestApp();

  static const title = 'Cozinha Noturno';

  static int flightTitleLineCount(WidgetTester tester) {
    final titleEntry = find
        .text(title, skipOffstage: false)
        .evaluate()
        .map((element) => (widget: element.widget as Text, renderObject: element.renderObject))
        .where((entry) => entry.renderObject is RenderBox)
        .map((entry) => (widget: entry.widget, renderBox: entry.renderObject! as RenderBox))
        .where((entry) => entry.renderBox.hasSize)
        .reduce((largest, current) => current.renderBox.size.width > largest.renderBox.size.width ? current : largest);
    final textPainter = TextPainter(
      text: TextSpan(text: titleEntry.widget.data, style: titleEntry.widget.style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: titleEntry.renderBox.size.width);

    return textPainter.computeLineMetrics().length;
  }

  static double titleHeight(WidgetTester tester) {
    return find
        .text(title, skipOffstage: false)
        .evaluate()
        .map((element) => element.renderObject)
        .whereType<RenderBox>()
        .where((renderBox) => renderBox.hasSize)
        .map((renderBox) => renderBox.size.height)
        .reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(builder: _GroupedHeaderDynamicWrapTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 400, child: _GroupedHeaderDynamicWrapHeader(isDetail: false)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(width: 400, child: _GroupedHeaderDynamicWrapHeader(isDetail: true)),
        ),
      ),
    );
  }
}

class _GroupedHeaderDynamicWrapHeader extends StatelessWidget {
  const _GroupedHeaderDynamicWrapHeader({required this.isDetail});

  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'dynamic-wrap-group',
          heroes: [
            QuiHero.text(
              text: '20h atras',
              style: TextStyle(fontSize: isDetail ? 16 : 14),
            ),
            QuiHero.text(
              text: _GroupedHeaderDynamicWrapTestApp.title,
              maxLines: isDetail ? null : 2,
              overflow: isDetail ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
            QuiHero.text(
              text: r'R$2.235,97/mes',
              style: TextStyle(fontSize: isDetail ? 30 : 25),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupedHeaderSiblingWrapTestApp extends StatelessWidget {
  const _GroupedHeaderSiblingWrapTestApp();

  static const title = 'Atendente de Relacionamento (Voz e Chat)';
  static const payment = r'R$1.766,99/mes';

  static ({double paymentTop, double titleBottom, int titleLineCount}) flightSample(WidgetTester tester) {
    final titleEntry = find
        .text(title, skipOffstage: false)
        .evaluate()
        .map((element) => (widget: element.widget as Text, renderObject: element.renderObject))
        .where((entry) => entry.renderObject is RenderBox)
        .map((entry) => (widget: entry.widget, renderBox: entry.renderObject! as RenderBox))
        .where((entry) => entry.renderBox.hasSize && entry.renderBox.size.width > 0)
        .reduce(
          (largest, current) => current.renderBox.size.height > largest.renderBox.size.height ? current : largest,
        );
    final paymentTop = tester.getTopLeft(find.text(payment, skipOffstage: false).last).dy;
    final titleTop = titleEntry.renderBox.localToGlobal(Offset.zero).dy;
    final titleLineCount = _lineCount(titleEntry);

    return (
      paymentTop: paymentTop,
      titleBottom: titleTop + titleEntry.renderBox.size.height,
      titleLineCount: titleLineCount,
    );
  }

  static int _lineCount(({RenderBox renderBox, Text widget}) entry) {
    final textPainter = TextPainter(
      text: TextSpan(text: entry.widget.data, style: entry.widget.style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: entry.renderBox.size.width);

    return textPainter.computeLineMetrics().length;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(builder: _GroupedHeaderSiblingWrapTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 300, child: _GroupedHeaderSiblingWrapHeader(isDetail: false)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return const Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 300, child: _GroupedHeaderSiblingWrapHeader(isDetail: true)),
      ),
    );
  }
}

class _GroupedHeaderSiblingWrapHeader extends StatelessWidget {
  const _GroupedHeaderSiblingWrapHeader({required this.isDetail});

  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'sibling-wrap-group',
          heroes: [
            QuiHero.text(
              text: '3 dias atras',
              style: TextStyle(fontSize: isDetail ? 16 : 14, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.only(bottom: 6),
            ),
            QuiHero.text(
              text: _GroupedHeaderSiblingWrapTestApp.title,
              maxLines: isDetail ? null : 2,
              overflow: isDetail ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
            QuiHero.text(
              text: _GroupedHeaderSiblingWrapTestApp.payment,
              style: TextStyle(fontSize: isDetail ? 30 : 25, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupedHeaderEndpointLineCeilingTestApp extends StatelessWidget {
  const _GroupedHeaderEndpointLineCeilingTestApp();

  static const title = 'Auxiliar de Cozinha Noturno Agua Branca';
  static const samples = [
    Duration(milliseconds: 240),
    Duration(milliseconds: 280),
    Duration(milliseconds: 320),
    Duration(milliseconds: 360),
  ];

  static ({bool hasEllipsis, int lineCount}) titleFlightSample(WidgetTester tester) {
    final entries = find
        .text(title, skipOffstage: false)
        .evaluate()
        .map((element) => (widget: element.widget as Text, renderObject: element.renderObject))
        .where((entry) => entry.renderObject is RenderBox)
        .map((entry) => (widget: entry.widget, renderBox: entry.renderObject! as RenderBox))
        .where((entry) => entry.renderBox.hasSize && entry.renderBox.size.width > 0)
        .toList();

    return (
      hasEllipsis: entries.any((entry) => entry.widget.maxLines != 2 && entry.widget.overflow == TextOverflow.ellipsis),
      lineCount: entries.map(_lineCount).reduce(math.max),
    );
  }

  static int _lineCount(({RenderBox renderBox, Text widget}) entry) {
    final textPainter = TextPainter(
      text: TextSpan(text: entry.widget.data, style: entry.widget.style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: entry.renderBox.size.width);

    final lineCount = textPainter.computeLineMetrics().length;
    final maxLines = entry.widget.maxLines;
    if (maxLines != null && lineCount > maxLines) return maxLines;
    return lineCount;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(
                    builder: _GroupedHeaderEndpointLineCeilingTestApp.buildDestination,
                  ).createRoute(context),
                );
              },
              child: const SizedBox(width: 280, child: _GroupedHeaderEndpointLineCeilingHeader(isDetail: false)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return const Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 560, child: _GroupedHeaderEndpointLineCeilingHeader(isDetail: true)),
      ),
    );
  }
}

class _GroupedHeaderEndpointLineCeilingHeader extends StatelessWidget {
  const _GroupedHeaderEndpointLineCeilingHeader({required this.isDetail});

  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'endpoint-line-ceiling-group',
          heroes: [
            QuiHero.text(
              text: _GroupedHeaderEndpointLineCeilingTestApp.title,
              maxLines: isDetail ? null : 2,
              overflow: isDetail ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupedHeaderBorderWrapTestApp extends StatelessWidget {
  const _GroupedHeaderBorderWrapTestApp();

  static const title = 'Atendente Geral de Restaurante';

  static ({bool hasEllipsis, int lineCount}) titleFlightSample(WidgetTester tester) {
    final entries = find
        .text(title, skipOffstage: false)
        .evaluate()
        .map((element) => (widget: element.widget as Text, renderObject: element.renderObject))
        .where((entry) => entry.renderObject is RenderBox)
        .map((entry) => (widget: entry.widget, renderBox: entry.renderObject! as RenderBox))
        .where((entry) => entry.renderBox.hasSize && entry.renderBox.size.width > 0)
        .where((entry) => entry.widget.maxLines != 2)
        .toList();

    return (
      hasEllipsis: entries.any((entry) => entry.widget.overflow == TextOverflow.ellipsis),
      lineCount: entries.map(_lineCount).reduce(math.max),
    );
  }

  static int _lineCount(({RenderBox renderBox, Text widget}) entry) {
    final textPainter = TextPainter(
      text: TextSpan(text: entry.widget.data, style: entry.widget.style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: entry.renderBox.size.width);

    final lineCount = textPainter.computeLineMetrics().length;
    final maxLines = entry.widget.maxLines;
    if (maxLines != null && lineCount > maxLines) return maxLines;
    return lineCount;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(builder: _GroupedHeaderBorderWrapTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 300, child: _GroupedHeaderBorderWrapHeader(isDetail: false)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return const Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 300, child: _GroupedHeaderBorderWrapHeader(isDetail: true)),
      ),
    );
  }
}

class _GroupedHeaderBorderWrapHeader extends StatelessWidget {
  const _GroupedHeaderBorderWrapHeader({required this.isDetail});

  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'border-wrap-group',
          heroes: [
            QuiHero.text(
              text: _GroupedHeaderBorderWrapTestApp.title,
              maxLines: isDetail ? null : 2,
              overflow: isDetail ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupedHeaderBaselineTestApp extends StatelessWidget {
  const _GroupedHeaderBaselineTestApp();

  static const title = 'Auxiliar de Cozinha';
  static const samples = [
    Duration(milliseconds: 43),
    Duration(milliseconds: 86),
    Duration(milliseconds: 129),
    Duration(milliseconds: 172),
    Duration(milliseconds: 215),
    Duration(milliseconds: 258),
    Duration(milliseconds: 301),
    Duration(milliseconds: 344),
    Duration(milliseconds: 387),
  ];

  static double titleBaseline(WidgetTester tester) {
    final element = find.text(title, skipOffstage: false).last.evaluate().single;
    final textWidget = element.widget as Text;
    final renderBox = element.renderObject! as RenderBox;
    final textPainter = TextPainter(
      text: TextSpan(text: textWidget.data, style: textWidget.style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: renderBox.size.width);
    final baseline = textPainter.computeLineMetrics().first.baseline;

    return renderBox.localToGlobal(Offset(0, baseline)).dy;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  const QuiHeroPage(builder: _GroupedHeaderBaselineTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 380, child: _GroupedHeaderBaselineHeader(isDetail: false)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(width: 380, child: _GroupedHeaderBaselineHeader(isDetail: true)),
        ),
      ),
    );
  }
}

class _GroupedHeaderBaselineHeader extends StatelessWidget {
  const _GroupedHeaderBaselineHeader({required this.isDetail});

  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'baseline-group',
          heroes: [
            QuiHero.text(
              text: _GroupedHeaderBaselineTestApp.title,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _SingleUntaggedTextHeroTestApp extends StatelessWidget {
  const _SingleUntaggedTextHeroTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push<void>(MaterialPageRoute<void>(builder: _SingleUntaggedTextHeroTestApp.buildDestination));
            },
            child: QuiHero.text(text: 'Hello'),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(body: QuiHero.text(text: 'Hello'));
  }
}

class _SingleUntaggedBoxHeroTestApp extends StatelessWidget {
  const _SingleUntaggedBoxHeroTestApp();

  static const Key sourceKey = ValueKey<String>('source-box');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: GestureDetector(
            key: sourceKey,
            onTap: () {
              Navigator.of(
                context,
              ).push<void>(MaterialPageRoute<void>(builder: _SingleUntaggedBoxHeroTestApp.buildDestination));
            },
            child: SizedBox(
              width: 100,
              height: 100,
              child: QuiHero.box(decoration: const BoxDecoration(color: Colors.red)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: 200,
        height: 200,
        child: QuiHero.box(decoration: const BoxDecoration(color: Colors.red)),
      ),
    );
  }
}

class _SingleUntaggedGroupHeroTestApp extends StatelessWidget {
  const _SingleUntaggedGroupHeroTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push<void>(MaterialPageRoute<void>(builder: _SingleUntaggedGroupHeroTestApp.buildDestination));
                },
                child: QuiHero.group(
                  heroes: [
                    QuiHero.text(text: 'Hello', padding: const EdgeInsets.only(bottom: 4)),
                    QuiHero.text(text: 'Hola'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          QuiHero.group(
            heroes: [
              QuiHero.text(text: 'Hello', padding: const EdgeInsets.only(bottom: 8)),
              QuiHero.text(text: 'Hola'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MixedUntaggedHeroVariantsTestApp extends StatelessWidget {
  const _MixedUntaggedHeroVariantsTestApp();

  static const Key sourceKey = ValueKey<String>('mixed-source');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: GestureDetector(
            key: sourceKey,
            onTap: () {
              Navigator.of(
                context,
              ).push<void>(MaterialPageRoute<void>(builder: _MixedUntaggedHeroVariantsTestApp.buildDestination));
            },
            child: Column(
              children: [
                QuiHero.text(text: 'Hello'),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: QuiHero.box(decoration: const BoxDecoration(color: Colors.red)),
                ),
                QuiHero.group(
                  heroes: [
                    QuiHero.text(text: 'Bom dia', padding: const EdgeInsets.only(bottom: 4)),
                    QuiHero.text(text: 'Boa tarde'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          QuiHero.text(text: 'Hello'),
          SizedBox(
            width: 120,
            height: 120,
            child: QuiHero.box(decoration: const BoxDecoration(color: Colors.blue)),
          ),
          QuiHero.group(
            heroes: [
              QuiHero.text(text: 'Bom dia', padding: const EdgeInsets.only(bottom: 8)),
              QuiHero.text(text: 'Boa tarde'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MultipleUntaggedTextHeroesTestApp extends StatelessWidget {
  const _MultipleUntaggedTextHeroesTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push<void>(MaterialPageRoute<void>(builder: _MultipleUntaggedTextHeroesTestApp.buildDestination));
                },
                child: QuiHero.text(text: 'Hello'),
              ),
              QuiHero.text(text: 'Hola'),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(body: QuiHero.text(text: 'Hello'));
  }
}

class _MultipleUntaggedGroupHeroesTestApp extends StatelessWidget {
  const _MultipleUntaggedGroupHeroesTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push<void>(MaterialPageRoute<void>(builder: _MultipleUntaggedGroupHeroesTestApp.buildDestination));
                },
                child: QuiHero.group(heroes: [QuiHero.text(text: 'Hello')]),
              ),
              QuiHero.group(heroes: [QuiHero.text(text: 'Hola')]),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          QuiHero.group(heroes: [QuiHero.text(text: 'Hello')]),
        ],
      ),
    );
  }
}

class _TypeMismatchGroupTestApp extends StatelessWidget {
  const _TypeMismatchGroupTestApp();

  static const Key sourceKey = ValueKey<String>('type-mismatch-source');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              GestureDetector(
                key: sourceKey,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push<void>(MaterialPageRoute<void>(builder: _TypeMismatchGroupTestApp.buildDestination));
                },
                child: QuiHero.group(
                  tag: 'group',
                  heroes: [
                    QuiHero.text(text: 'Hello'),
                    QuiHero.text(text: 'World'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          QuiHero.group(
            tag: 'group',
            heroes: [
              QuiHero.text(text: 'Hello'),
              QuiHero.box(decoration: const BoxDecoration(color: Colors.red), width: 100, height: 100),
            ],
          ),
        ],
      ),
    );
  }
}

class _MultipleExplicitTextHeroesTestApp extends StatelessWidget {
  const _MultipleExplicitTextHeroesTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push<void>(MaterialPageRoute<void>(builder: _MultipleExplicitTextHeroesTestApp.buildDestination));
                },
                child: QuiHero.text(tag: 'hello', text: 'Hello'),
              ),
              QuiHero.text(tag: 'hola', text: 'Hola'),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDestination(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          QuiHero.text(tag: 'hello', text: 'Hello'),
          QuiHero.text(tag: 'hola', text: 'Hola'),
        ],
      ),
    );
  }
}
