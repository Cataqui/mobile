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

    testWidgets('when source and destination hero counts do not match, it should assert during flight', (tester) async {
      await tester.pumpWidget(const _MismatchedGroupTestApp());
      await tester.tap(find.text('Hello'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(tester.takeException(), isAssertionError);
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
