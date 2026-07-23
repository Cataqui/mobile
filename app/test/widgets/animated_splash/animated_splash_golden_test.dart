import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/widgets/app_animated_splash/app_animated_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class _AnimatedSplashGoldenHarness extends StatelessWidget {
  const _AnimatedSplashGoldenHarness({this.freezeAnimation = false});

  final bool freezeAnimation;

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = const MediaQueryData(
      size: Size(390, 780),
      devicePixelRatio: 1,
    ).copyWith(disableAnimations: false);

    return SizedBox(
      width: 390,
      height: 780,
      child: MediaQuery(
        data: mediaQueryData,
        child: TickerMode(
          enabled: !freezeAnimation,
          child: AppAnimatedSplash(
            child: Scaffold(
              body: Center(
                child: Text(
                  'Oportunidades perto de você',
                  style: TextStyle(
                    color: context.mateo.colorScheme.text.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _AnimatedSplashGoldenPump {
  static Future<void> settleStartupFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  static Future<void> startReveal(WidgetTester tester) async {
    await tester.pump(AppAnimatedSplash.anticipationDuration);
    await tester.pump();
  }
}

void main() {
  group('CataquiAnimatedSplash Golden Tests', () {
    goldenTest(
      'when the native splash hands off, it should show the centered white logo on the brand background',
      fileName: 'animated_splash_waiting',
      builder: () => const _AnimatedSplashGoldenHarness(freezeAnimation: true),
    );

    goldenTest(
      'when the reveal is waiting to begin, it should keep the native-scale logo on the brand background',
      fileName: 'animated_splash_anticipation',
      pumpBeforeTest: pumpOnce,
      whilePerforming: (tester) async {
        await _AnimatedSplashGoldenPump.settleStartupFrames(tester);
        await tester.pump(AppAnimatedSplash.anticipationDuration ~/ 2);
        return null;
      },
      builder: _AnimatedSplashGoldenHarness.new,
    );

    goldenTest(
      'when the logo zooms forward, it should show the app only through the expanding centered opening',
      fileName: 'animated_splash_reveal',
      pumpBeforeTest: pumpOnce,
      whilePerforming: (tester) async {
        await _AnimatedSplashGoldenPump.settleStartupFrames(tester);
        await _AnimatedSplashGoldenPump.startReveal(tester);
        await tester.pump(AppAnimatedSplash.revealDuration ~/ 2);
        return null;
      },
      builder: _AnimatedSplashGoldenHarness.new,
    );
  });
}
