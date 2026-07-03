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
      'when the source width is narrower than the destination width, it should wrap text within the available flight width',
      (tester) async {
        await tester.pumpWidget(const _GroupedWidthWrapFlightTestApp());
        await tester.tap(find.text(_GroupedWidthWrapFlightTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(_GroupedWidthWrapFlightTestApp.hasTitleOverflow(tester), isFalse);
      },
    );

    testWidgets(
      'when popping to a narrower source width, it should keep the title on a single line while the flight width matches the destination width',
      (tester) async {
        await tester.pumpWidget(const _GroupedWidthUnwrapPopTestApp());
        await tester.tap(find.text(_GroupedWidthUnwrapPopTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.text(_GroupedWidthUnwrapPopTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(_GroupedWidthUnwrapPopTestApp.hasTwoLineFlightTitle(tester), isFalse);
      },
    );

    testWidgets(
      'when popping from a multi-line destination to a clamped source, it should progressively reduce visible lines during the reverse flight',
      (tester) async {
        await tester.pumpWidget(const _GroupedLineClampPopTestApp());
        await tester.tap(find.text(_GroupedLineClampPopTestApp.summary));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.text(_GroupedLineClampPopTestApp.description));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        final firstFrameMaxLines = _GroupedLineClampPopTestApp.flightDescriptionMaxLines(tester);

        await tester.pump(const Duration(milliseconds: 32));

        final secondFrameMaxLines = _GroupedLineClampPopTestApp.flightDescriptionMaxLines(tester);
        expect(
          secondFrameMaxLines < firstFrameMaxLines,
          isTrue,
          reason: 'firstFrameMaxLines=$firstFrameMaxLines secondFrameMaxLines=$secondFrameMaxLines',
        );
      },
    );

    testWidgets(
      "when the destination positions children lower than the source, each child's vertical offset should transition monotonically toward the destination position during the forward flight",
      (tester) async {
        await tester.pumpWidget(const _GroupedVerticalTransitionTestApp());

        final sourceTitleTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.title,
        );
        final sourcePaymentTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.payment,
        );

        await tester.tap(find.text(_GroupedVerticalTransitionTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final flightTitleTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.title,
        );
        final flightPaymentTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.payment,
        );

        await tester.pumpAndSettle();

        final destinationTitleTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.title,
        );
        final destinationPaymentTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.payment,
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
      "when popping to a source with higher child positions, each child's vertical offset should transition monotonically toward the source position",
      (tester) async {
        await tester.pumpWidget(const _GroupedVerticalTransitionTestApp());

        final sourceTitleTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.title,
        );
        final sourcePaymentTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.payment,
        );

        await tester.tap(find.text(_GroupedVerticalTransitionTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();

        final destinationTitleTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.title,
        );
        final destinationPaymentTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.payment,
        );

        await tester.tap(find.text(_GroupedVerticalTransitionTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final flightTitleTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.title,
        );
        final flightPaymentTop = _GroupedVerticalTransitionTestApp.textTop(
          tester,
          _GroupedVerticalTransitionTestApp.payment,
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
      'when popping to a source with greater width, it should rewrap the title from multiple lines to fewer lines during the reverse flight',
      (tester) async {
        await tester.pumpWidget(const _GroupedWidthWrapTransitionTestApp());
        await tester.tap(find.text(_GroupedWidthWrapTransitionTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.text(_GroupedWidthWrapTransitionTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 360));

        expect(_GroupedWidthWrapTransitionTestApp.flightTitleLineCount(tester), equals(1));
      },
    );

    testWidgets(
      "when a hero's line count increases during flight, it should reposition subsequent siblings downward proportionally to maintain vertical gap",
      (tester) async {
        await tester.pumpWidget(const _GroupedSiblingDisplacementTestApp());
        await tester.tap(find.text(_GroupedSiblingDisplacementTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));

        final sample = _GroupedSiblingDisplacementTestApp.flightSample(tester);

        expect(
          (sample.titleLineCount >= 2, sample.paymentTop >= sample.titleBottom - 6),
          equals((true, true)),
          reason: 'sample=$sample',
        );
      },
    );

    testWidgets(
      "when the source and destination have different line counts, it should never exceed the maximum of both endpoints' line counts nor inject ellipsis during the flight",
      (tester) async {
        await tester.pumpWidget(const _GroupedLineCeilingTestApp());
        await tester.tap(find.text(_GroupedLineCeilingTestApp.title));
        await tester.pump();

        final samples = <({bool hasEllipsis, int lineCount})>[];
        var elapsed = Duration.zero;

        for (final sample in _GroupedLineCeilingTestApp.samples) {
          await tester.pump(sample - elapsed);
          elapsed = sample;
          samples.add(_GroupedLineCeilingTestApp.titleFlightSample(tester));
        }

        expect(
          (samples.every((sample) => sample.lineCount <= 3), samples.every((sample) => !sample.hasEllipsis)),
          equals((true, true)),
          reason: 'samples=$samples',
        );
      },
    );

    testWidgets(
      'when text would overflow the flight width, it should wrap without ellipsis to avoid cropping mid-flight',
      (tester) async {
        await tester.pumpWidget(const _GroupedOverflowWrapTestApp());
        await tester.tap(find.text(_GroupedOverflowWrapTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));

        final sample = _GroupedOverflowWrapTestApp.titleFlightSample(tester);

        expect((sample.lineCount >= 2, sample.hasEllipsis), equals((true, false)), reason: 'sample=$sample');
      },
    );

    testWidgets(
      'when popping and the flight width is still narrower than single-line space, it should keep wrapping without ellipsis',
      (tester) async {
        await tester.pumpWidget(const _GroupedOverflowWrapTestApp());
        await tester.tap(find.text(_GroupedOverflowWrapTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.text(_GroupedOverflowWrapTestApp.title));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final sample = _GroupedOverflowWrapTestApp.titleFlightSample(tester);

        expect((sample.lineCount >= 2, sample.hasEllipsis), equals((true, false)), reason: 'sample=$sample');
      },
    );

    testWidgets(
      'when the reverse animation completes, the flight title height should match the settled source title height within tolerance',
      (tester) async {
        await tester.pumpWidget(const _GroupedWidthWrapTransitionTestApp());
        await tester.tap(find.text(_GroupedWidthWrapTransitionTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.text(_GroupedWidthWrapTransitionTestApp.title));
        await tester.pump();
        await tester.pump(QuiHeroPage.defaultReverseTransitionDuration - const Duration(milliseconds: 1));

        final flightHeight = _GroupedWidthWrapTransitionTestApp.titleHeight(tester);

        await tester.pumpAndSettle();

        final settledHeight = _GroupedWidthWrapTransitionTestApp.titleHeight(tester);

        expect((flightHeight - settledHeight).abs() < 2, isTrue);
      },
    );

    testWidgets(
      'when font size interpolates during the reverse flight, the painted baseline should move smoothly toward the source without sudden jumps',
      (tester) async {
        await tester.pumpWidget(const _GroupedBaselineSmoothnessTestApp());

        await tester.tap(find.text(_GroupedBaselineSmoothnessTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();

        final baselines = <double>[];
        var elapsed = Duration.zero;

        await tester.tap(find.text(_GroupedBaselineSmoothnessTestApp.title));
        await tester.pump();

        for (final sample in _GroupedBaselineSmoothnessTestApp.samples) {
          await tester.pump(sample - elapsed);
          elapsed = sample;
          baselines.add(_GroupedBaselineSmoothnessTestApp.titleBaseline(tester));
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
      },
    );
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

    testWidgets(
      "when popping, the payment text's top offset should move monotonically upward during the reverse flight without jumping",
      (tester) async {
        await tester.pumpWidget(const _GroupedTextEstimatedHeightRegressionTestApp());
        await tester.tap(find.text(_GroupedTextEstimatedHeightRegressionTestApp.title));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.text(_GroupedTextEstimatedHeightRegressionTestApp.title));
        await tester.pump();

        final samples = <({double paymentTop, double titleBottom})>[];
        var elapsed = Duration.zero;

        for (final sampleTime in _GroupedTextEstimatedHeightRegressionTestApp.samples) {
          await tester.pump(sampleTime - elapsed);
          elapsed = sampleTime;
          samples.add(_GroupedTextEstimatedHeightRegressionTestApp.flightSample(tester));
        }

        for (var i = 1; i < samples.length; i++) {
          expect(
            samples[i].paymentTop,
            lessThan(samples[i - 1].paymentTop),
            reason: 'Frame $i: payment jumped instead of moving up smoothly. samples=$samples',
          );
        }
      },
    );
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

class _GroupedWidthWrapFlightTestApp extends StatelessWidget {
  const _GroupedWidthWrapFlightTestApp();

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
                  const QuiHeroPage(builder: _GroupedWidthWrapFlightTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(
                width: 180,
                child: _GroupedWidthWrapFlightLayout(title: _GroupedWidthWrapFlightTestApp.title),
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
        child: SizedBox(width: 360, child: _GroupedWidthWrapFlightLayout(title: 'Detalhes da oportunidade')),
      ),
    );
  }
}

class _GroupedWidthWrapFlightLayout extends StatelessWidget {
  const _GroupedWidthWrapFlightLayout({required this.title});

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

class _GroupedWidthUnwrapPopTestApp extends StatelessWidget {
  const _GroupedWidthUnwrapPopTestApp();

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
                  const QuiHeroPage(builder: _GroupedWidthUnwrapPopTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 180, child: _GroupedWidthUnwrapPopLayout(width: 180, fontSize: 20)),
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
          child: const SizedBox(width: 360, child: _GroupedWidthUnwrapPopLayout(width: 360, fontSize: 20)),
        ),
      ),
    );
  }
}

class _GroupedWidthUnwrapPopLayout extends StatelessWidget {
  const _GroupedWidthUnwrapPopLayout({required this.width, required this.fontSize});

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
                text: _GroupedWidthUnwrapPopTestApp.title,
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

class _GroupedLineClampPopTestApp extends StatelessWidget {
  const _GroupedLineClampPopTestApp();

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
                  const QuiHeroPage(builder: _GroupedLineClampPopTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 300, child: _GroupedLineClampPopLayout(description: summary, maxLines: 3)),
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
          child: const SizedBox(width: 300, child: _GroupedLineClampPopLayout(description: description)),
        ),
      ),
    );
  }
}

class _GroupedLineClampPopLayout extends StatelessWidget {
  const _GroupedLineClampPopLayout({required this.description, this.maxLines});

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

class _GroupedVerticalTransitionTestApp extends StatelessWidget {
  const _GroupedVerticalTransitionTestApp();

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
                  const QuiHeroPage(builder: _GroupedVerticalTransitionTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 300, child: _GroupedVerticalTransitionLayout(isDetail: false)),
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
          child: const SizedBox(width: 300, child: _GroupedVerticalTransitionLayout(isDetail: true)),
        ),
      ),
    );
  }
}

class _GroupedVerticalTransitionLayout extends StatelessWidget {
  const _GroupedVerticalTransitionLayout({required this.isDetail});

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
              text: _GroupedVerticalTransitionTestApp.title,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
            QuiHero.text(
              text: _GroupedVerticalTransitionTestApp.payment,
              style: TextStyle(fontSize: isDetail ? 30 : 25, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupedWidthWrapTransitionTestApp extends StatelessWidget {
  const _GroupedWidthWrapTransitionTestApp();

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
                  const QuiHeroPage(builder: _GroupedWidthWrapTransitionTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 400, child: _GroupedWidthWrapTransitionLayout(isDetail: false)),
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
          child: const SizedBox(width: 400, child: _GroupedWidthWrapTransitionLayout(isDetail: true)),
        ),
      ),
    );
  }
}

class _GroupedWidthWrapTransitionLayout extends StatelessWidget {
  const _GroupedWidthWrapTransitionLayout({required this.isDetail});

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
              text: _GroupedWidthWrapTransitionTestApp.title,
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

class _GroupedSiblingDisplacementTestApp extends StatelessWidget {
  const _GroupedSiblingDisplacementTestApp();

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
                  const QuiHeroPage(builder: _GroupedSiblingDisplacementTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 300, child: _GroupedSiblingDisplacementLayout(isDetail: false)),
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
        child: SizedBox(width: 300, child: _GroupedSiblingDisplacementLayout(isDetail: true)),
      ),
    );
  }
}

class _GroupedSiblingDisplacementLayout extends StatelessWidget {
  const _GroupedSiblingDisplacementLayout({required this.isDetail});

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
              text: _GroupedSiblingDisplacementTestApp.title,
              maxLines: isDetail ? null : 2,
              overflow: isDetail ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
            QuiHero.text(
              text: _GroupedSiblingDisplacementTestApp.payment,
              style: TextStyle(fontSize: isDetail ? 30 : 25, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupedLineCeilingTestApp extends StatelessWidget {
  const _GroupedLineCeilingTestApp();

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
                  const QuiHeroPage(builder: _GroupedLineCeilingTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 280, child: _GroupedLineCeilingLayout(isDetail: false)),
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
        child: SizedBox(width: 560, child: _GroupedLineCeilingLayout(isDetail: true)),
      ),
    );
  }
}

class _GroupedLineCeilingLayout extends StatelessWidget {
  const _GroupedLineCeilingLayout({required this.isDetail});

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
              text: _GroupedLineCeilingTestApp.title,
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

class _GroupedOverflowWrapTestApp extends StatelessWidget {
  const _GroupedOverflowWrapTestApp();

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
                  const QuiHeroPage(builder: _GroupedOverflowWrapTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 300, child: _GroupedOverflowWrapLayout(isDetail: false)),
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
        child: SizedBox(width: 300, child: _GroupedOverflowWrapLayout(isDetail: true)),
      ),
    );
  }
}

class _GroupedOverflowWrapLayout extends StatelessWidget {
  const _GroupedOverflowWrapLayout({required this.isDetail});

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
              text: _GroupedOverflowWrapTestApp.title,
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

class _GroupedBaselineSmoothnessTestApp extends StatelessWidget {
  const _GroupedBaselineSmoothnessTestApp();

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
                  const QuiHeroPage(builder: _GroupedBaselineSmoothnessTestApp.buildDestination).createRoute(context),
                );
              },
              child: const SizedBox(width: 380, child: _GroupedBaselineSmoothnessLayout(isDetail: false)),
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
          child: const SizedBox(width: 380, child: _GroupedBaselineSmoothnessLayout(isDetail: true)),
        ),
      ),
    );
  }
}

class _GroupedBaselineSmoothnessLayout extends StatelessWidget {
  const _GroupedBaselineSmoothnessLayout({required this.isDetail});

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
              text: _GroupedBaselineSmoothnessTestApp.title,
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
              child: QuiHero.background(decoration: const BoxDecoration(color: Colors.red)),
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
        child: QuiHero.background(decoration: const BoxDecoration(color: Colors.red)),
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
                  child: QuiHero.background(decoration: const BoxDecoration(color: Colors.red)),
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
            child: QuiHero.background(decoration: const BoxDecoration(color: Colors.blue)),
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
              QuiHero.background(decoration: const BoxDecoration(color: Colors.red), width: 100, height: 100),
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

class _GroupedTextEstimatedHeightRegressionTestApp extends StatelessWidget {
  const _GroupedTextEstimatedHeightRegressionTestApp();

  static const title = 'Atendente de Relacionamento (Voz e Chat)';
  static const payment = r'R$1.766,99/mes';
  static const samples = [
    Duration(milliseconds: 80),
    Duration(milliseconds: 160),
    Duration(milliseconds: 240),
    Duration(milliseconds: 320),
    Duration(milliseconds: 400),
  ];

  static ({double paymentTop, double titleBottom}) flightSample(WidgetTester tester) {
    final titleElement = find
        .text(title, skipOffstage: false)
        .evaluate()
        .map((e) => e.renderObject)
        .whereType<RenderBox>()
        .firstWhere((box) => box.hasSize && box.size.width > 0);
    final titleTop = titleElement.localToGlobal(Offset.zero).dy;
    final titleBottom = titleTop + titleElement.size.height;
    final paymentTop = tester.getTopLeft(find.text(payment, skipOffstage: false).last).dy;
    return (paymentTop: paymentTop, titleBottom: titleBottom);
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
                Navigator.of(context).push<void>(const QuiHeroPage(builder: buildDestination).createRoute(context));
              },
              child: const SizedBox(width: 300, child: _GroupedEstimatedHeightRegressionLayout(isDetail: false)),
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
          onTap: () => Navigator.of(context).maybePop(),
          child: const SizedBox(width: 300, child: _GroupedEstimatedHeightRegressionLayout(isDetail: true)),
        ),
      ),
    );
  }
}

class _GroupedEstimatedHeightRegressionLayout extends StatelessWidget {
  const _GroupedEstimatedHeightRegressionLayout({required this.isDetail});

  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHero.group(
          tag: 'height-repro-group',
          heroes: [
            QuiHero.text(
              text: _GroupedTextEstimatedHeightRegressionTestApp.title,
              maxLines: isDetail ? null : 2,
              overflow: isDetail ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: isDetail ? 34 : 22, fontWeight: FontWeight.w600),
            ),
            QuiHero.text(
              text: _GroupedTextEstimatedHeightRegressionTestApp.payment,
              style: TextStyle(fontSize: isDetail ? 30 : 25, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
