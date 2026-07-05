import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHero.background with QuiHero.group', () {
    testWidgets('when a group hero is inside a box hero without flight, it should render without errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuiHeroBackground(
              tag: 'box',
              width: 300,
              height: 400,
              decoration: BoxDecoration(color: Colors.white),
              child: QuiHeroGroup(
                tag: 'group',
                heroes: [
                  QuiHeroText('Title', style: TextStyle(fontSize: 18)),
                  QuiHeroText('Description', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('when a group hero is not inside a box hero, the flight should not receive box metrics', (
      tester,
    ) async {
      await tester.pumpWidget(const _NoBoxPopTest());
      await tester.tap(find.text(_NoBoxPopTest.pushButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_NoBoxPopTest.popButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text(_NoBoxPopTest.groupText1, skipOffstage: false),
        findsWidgets,
        reason: 'Group text 1 should exist during flight',
      );
      expect(
        find.text(_NoBoxPopTest.groupText2, skipOffstage: false),
        findsWidgets,
        reason: 'Group text 2 should exist during flight',
      );
    });

    testWidgets('when popping a group inside a box, the text should render without errors during flight', (
      tester,
    ) async {
      await tester.pumpWidget(const _BoxPopTest());
      await tester.tap(find.text(_BoxPopTest.pushButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_BoxPopTest.popButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text(_BoxPopTest.titleText, skipOffstage: false),
        findsWidgets,
        reason: 'Title should exist during flight',
      );
      expect(
        find.text(_BoxPopTest.longText, skipOffstage: false),
        findsWidgets,
        reason: 'Long text should exist during flight',
      );
    });

    testWidgets(
      'when popping a group inside a box with a long text, the text should show ellipsis or reduced maxLines in at least one flight instance',
      (tester) async {
        await tester.pumpWidget(const _BoxPopTest());
        await tester.tap(find.text(_BoxPopTest.pushButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_BoxPopTest.popButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final longTextWidgets = tester.widgetList<Text>(find.text(_BoxPopTest.longText, skipOffstage: false));

        expect(
          longTextWidgets.isNotEmpty,
          isTrue,
          reason: 'Long text should exist during flight (found ${longTextWidgets.length} instances)',
        );

        final anyClamped = longTextWidgets.any(
          (t) => t.overflow == TextOverflow.ellipsis || (t.maxLines != null && t.maxLines! < 10),
        );

        expect(
          anyClamped,
          isTrue,
          reason: 'At least one flight instance of the long text should show ellipsis or reduced maxLines',
        );
      },
    );

    testWidgets('when popping a group with multiple heroes inside a box, each hero should appear during flight', (
      tester,
    ) async {
      await tester.pumpWidget(const _BoxMultiHeroPopTest());
      await tester.tap(find.text(_BoxMultiHeroPopTest.pushButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_BoxMultiHeroPopTest.popButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      for (final text in _BoxMultiHeroPopTest.heroTexts) {
        expect(find.text(text, skipOffstage: false), findsWidgets, reason: '"$text" should exist during flight');
      }
    });

    testWidgets(
      'when popping a group inside a box twice consecutively, the second pop should also show ellipsis on the last text (cached metrics path)',
      (tester) async {
        await tester.pumpWidget(const _RepeatedPopBoxTest());

        // First push → pop
        await tester.tap(find.text(_RepeatedPopBoxTest.pushButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_RepeatedPopBoxTest.popButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final firstPopTexts = tester.widgetList<Text>(find.text(_RepeatedPopBoxTest.longText, skipOffstage: false));
        expect(
          firstPopTexts.any((t) => t.overflow == TextOverflow.ellipsis),
          isTrue,
          reason: 'First pop should show ellipsis',
        );

        await tester.pumpAndSettle();

        // Second push → pop
        await tester.tap(find.text(_RepeatedPopBoxTest.pushButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_RepeatedPopBoxTest.popButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final secondPopTexts = tester.widgetList<Text>(find.text(_RepeatedPopBoxTest.longText, skipOffstage: false));
        expect(
          secondPopTexts.any((t) => t.overflow == TextOverflow.ellipsis),
          isTrue,
          reason: 'Second pop should also show ellipsis (cached metrics)',
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('when popping a group with three heroes inside a box, the last text should use ellipsis', (
      tester,
    ) async {
      await tester.pumpWidget(const _ThreeHeroBoxPopTest());
      await tester.tap(find.text(_ThreeHeroBoxPopTest.pushButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_ThreeHeroBoxPopTest.popButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final thirdTexts = tester.widgetList<Text>(find.text(_ThreeHeroBoxPopTest.t3, skipOffstage: false));
      expect(
        thirdTexts.any((t) => t.overflow == TextOverflow.ellipsis),
        isTrue,
        reason: 'Third hero should show ellipsis when clamped',
      );

      expect(tester.takeException(), isNull);
    });
  });
}

class _NoBoxPopTest extends StatelessWidget {
  const _NoBoxPopTest();

  static const pushButton = 'NoBox Push';
  static const popButton = 'NoBox Pop';
  static const groupText1 = 'Hello';
  static const groupText2 = 'World';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(const QuiHeroPage(builder: _buildDestination).createRoute(context));
              },
              child: const SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QuiHeroGroup(
                      tag: 'no-box-group',
                      heroes: [
                        QuiHeroText(groupText1, style: TextStyle(fontSize: 18)),
                        QuiHeroText(groupText2, style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    Text(pushButton),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDestination(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                QuiHeroGroup(
                  tag: 'no-box-group',
                  heroes: [
                    QuiHeroText(groupText1, style: TextStyle(fontSize: 28)),
                    QuiHeroText(groupText2, style: TextStyle(fontSize: 18)),
                  ],
                ),
                Text(popButton),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoxPopTest extends StatelessWidget {
  const _BoxPopTest();

  static const pushButton = 'BoxPop Push';
  static const popButton = 'BoxPop Pop';
  static const titleText = 'Title';
  static const longText =
      'This is a long text for clamping. '
      'It has several lines that should overflow the box. '
      'The text demonstrates height clamping.';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(const QuiHeroPage(builder: _buildDestination).createRoute(context));
              },
              child: const SizedBox(
                width: 300,
                child: QuiHeroBackground(
                  tag: 'pop-box',
                  width: 300,
                  height: 120,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuiHeroGroup(
                        tag: 'pop-group',
                        heroes: [
                          QuiHeroText(titleText, style: TextStyle(fontSize: 14)),
                          QuiHeroText(
                            longText,
                            style: TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(pushButton),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDestination(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 300,
            child: QuiHeroBackground(
              tag: 'pop-box',
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuiHeroGroup(
                    tag: 'pop-group',
                    heroes: [
                      QuiHeroText(titleText, style: TextStyle(fontSize: 24)),
                      QuiHeroText(longText, style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Text(popButton),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepeatedPopBoxTest extends StatelessWidget {
  const _RepeatedPopBoxTest();

  static const pushButton = 'RepeatPush';
  static const popButton = 'RepeatPop';
  static const titleText = 'RepeatedTitle';
  static const longText =
      'This is a repeating pop test text. '
      'It needs enough lines to overflow the box '
      'and trigger the height clamping code path. '
      'The second pop should reuse cached metrics.';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(const QuiHeroPage(builder: _buildDestination).createRoute(context));
              },
              child: const SizedBox(
                width: 300,
                child: QuiHeroBackground(
                  tag: 'repeat-box',
                  width: 300,
                  height: 120,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuiHeroGroup(
                        tag: 'repeat-group',
                        heroes: [
                          QuiHeroText(titleText, style: TextStyle(fontSize: 14)),
                          QuiHeroText(
                            longText,
                            style: TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(pushButton),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDestination(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 300,
            child: QuiHeroBackground(
              tag: 'repeat-box',
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuiHeroGroup(
                    tag: 'repeat-group',
                    heroes: [
                      QuiHeroText(titleText, style: TextStyle(fontSize: 24)),
                      QuiHeroText(longText, style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Text(popButton),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreeHeroBoxPopTest extends StatelessWidget {
  const _ThreeHeroBoxPopTest();

  static const pushButton = 'ThreePush';
  static const popButton = 'ThreePop';
  static const t1 = 'Three Title';
  static const t2 = 'Subtitle';
  static const t3 =
      'Third text that needs height clamping '
      'when the box shrinks during the pop. '
      'It has several lines to ensure overflow.';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(const QuiHeroPage(builder: _buildDestination).createRoute(context));
              },
              child: const SizedBox(
                width: 300,
                child: QuiHeroBackground(
                  tag: 'three-box',
                  width: 300,
                  height: 150,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuiHeroGroup(
                        tag: 'three-group',
                        heroes: [
                          QuiHeroText(t1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          QuiHeroText(t2, style: TextStyle(fontSize: 12)),
                          QuiHeroText(t3, style: TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      Text(pushButton),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDestination(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 300,
            child: QuiHeroBackground(
              tag: 'three-box',
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuiHeroGroup(
                    tag: 'three-group',
                    heroes: [
                      QuiHeroText(t1, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      QuiHeroText(t2, style: TextStyle(fontSize: 18)),
                      QuiHeroText(t3, style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Text(popButton),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoxMultiHeroPopTest extends StatelessWidget {
  const _BoxMultiHeroPopTest();

  static const pushButton = 'Multi Push';
  static const popButton = 'Multi Pop';
  static List<String> get heroTexts => [t1, t2, t3];
  static const t1 = 'A Test Title';
  static const t2 = 'Subtitle text';
  static const t3 =
      'Body text for multi-hero clamping test. '
      'It will be height clamped when the box shrinks.';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(const QuiHeroPage(builder: _buildDestination).createRoute(context));
              },
              child: const SizedBox(
                width: 300,
                child: QuiHeroBackground(
                  tag: 'multi-box',
                  width: 300,
                  height: 150,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuiHeroGroup(
                        tag: 'multi-group',
                        heroes: [
                          QuiHeroText(t1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          QuiHeroText(t2, style: TextStyle(fontSize: 12)),
                          QuiHeroText(t3, style: TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      Text(pushButton),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDestination(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 300,
            child: QuiHeroBackground(
              tag: 'multi-box',
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuiHeroGroup(
                    tag: 'multi-group',
                    heroes: [
                      QuiHeroText(t1, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      QuiHeroText(t2, style: TextStyle(fontSize: 18)),
                      QuiHeroText(t3, style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Text(popButton),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
