library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/qui.dart' show QuiHeroExtension, QuiHeroPage, QuiHeroSwipeToPopExtension;
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_data.dart';
import 'package:qui/src/widgets/qui_edge_fade/qui_edge_fade.dart'
    show QuiEdgeFade, QuiEdgeFadePosition, QuiEdgeFadeStyle;
import 'package:qui/src/widgets/qui_hero/heroes/background/qui_hero_background.dart';
import 'package:qui/src/widgets/qui_hero/heroes/text/qui_hero_text.dart';

import 'heroes/background/qui_hero_background.dart' show QuiHeroBackground;
import 'heroes/group/qui_hero_group.dart' show QuiHeroGroup;
import 'heroes/text/qui_hero_text.dart' show QuiHeroText, QuiHeroTextFlightMetrics;

part 'qui_hero_edge_fade.dart';
part 'qui_hero_enums.dart';
part 'qui_hero_lifecycle/_qui_hero_lifecycle_endpoint.dart';
part 'qui_hero_lifecycle/_qui_hero_lifecycle_flight_shuttle.dart';

/// A hero widget that animates a shared element across screens with pre-built,
/// device-safe flight animations.
///
/// ## How it works
///
/// Place a [QuiHero] on the source screen and another with the same [tag] on
/// the destination screen. During navigation — triggered by pushing a
/// [QuiHeroPage] — the source element "flies" across to the destination
/// position while its appearance morphs between configurations. The source
/// route stays composited underneath so the flight is visible against the
/// previous screen.
///
/// ## Variants
///
/// Use one of the concrete hero classes directly instead of factory
/// constructors:
///
///  * [QuiHeroText] — animates a text block
///  * [QuiHeroBackground] — animates a [BoxDecoration]
///  * [QuiHeroGroup] — moves several [QuiHero] as one shared element
///
/// Variants can use a [tag] to pair source and destination explicitly. When
/// [tag] is omitted, QUI uses a private default tag for that variant. This
/// keeps simple routes lightweight: one tagless [QuiHeroText], one tagless
/// [QuiHeroBackground], etc. can coexist and animate to the matching variant
/// on the destination route. If a route has multiple active heroes of the same
/// tagless variant, Flutter asserts at navigation time; pass explicit tags for
/// those cases.
///
/// ## Performance on low-end devices
///
/// Flight shuttles are wrapped in [RepaintBoundary] to isolate repaint work.
/// Decoration and text interpolation use [Curves.easeOutCubic] — a
/// cost-effective easing curve that performs well on low-end GPUs
///
/// ```dart
/// // Source — a rounded box with title
/// QuiHeroBackground(
///   tag: 'card-1',
///   decoration: BoxDecoration(
///     color: surfaceColor,
///     borderRadius: BorderRadius.circular(38),
///   ),
///   child: QuiHeroText(
///     tag: 'card-1-title',
///     text: 'Garçom para Fim de Semana',
///     style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
///   ),
/// )
///
/// // Destination — same tags trigger the shared-element transition
/// QuiHeroBackground(
///   tag: 'card-1',
///   decoration: BoxDecoration(color: bgColor),
///   child: QuiHeroText(
///     tag: 'card-1-title',
///     text: 'Garçom para Fim de Semana',
///     style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
///   ),
/// )
/// ```
///
/// See also:
///  * [QuiHeroPage], the destination [Page] that enables transparent route
///    compositing and reduced-motion support.
///  * [QuiHeroExtension], the base class for reusable behaviors attached to
///    hero variants.
///  * [QuiHeroSwipeToPopExtension], a built-in extension that adds
///    swipe-to-pop gestures to hero destinations.
///  * Flutter's [Hero], the underlying widget that [QuiHero] wraps.
abstract class QuiHero extends StatelessWidget {
  /// Creates a QUI hero with the given shared animation configuration.
  ///
  /// Rather than calling this constructor directly, use one of the concrete
  /// subclasses: [QuiHeroText], [QuiHeroBackground], or [QuiHeroGroup].
  const QuiHero({required this.tag, required this.flightShuttleBuilder, this.onStart, this.onEnd, super.key});

  /// The identifier that pairs source and destination heroes.
  ///
  /// This [tag] must be identical on both the source and destination
  /// instances of the same shared element. It must be unique among all
  /// heroes in the same scope.
  ///
  /// Concrete subclasses supply a variant-specific default when the user
  /// does not pass one explicitly.
  final Object tag;

  final Widget Function(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
    Widget fromHeroChild,
    Widget toHeroChild,
  )
  flightShuttleBuilder;

  final VoidCallback? onStart;

  final VoidCallback? onEnd;

  Widget buildFlightChild(BuildContext context);

  static RectTween createRectTween(Rect? begin, Rect? end) {
    return RectTween(begin: begin, end: end);
  }

  List<VoidCallback> lifecycleStartCallbacks(BuildContext context) {
    final onStart = this.onStart;
    if (onStart == null) return const [];

    return [onStart];
  }

  List<VoidCallback> lifecycleEndCallbacks(BuildContext context) {
    final onEnd = this.onEnd;
    if (onEnd == null) return const [];

    return [onEnd];
  }

  Widget buildLifecycleEndpoint(BuildContext context) {
    return _QuiHeroLifecycleEndpoint(
      onStartCallbacks: lifecycleStartCallbacks(context),
      onEndCallbacks: lifecycleEndCallbacks(context),
      child: buildFlightChild(context),
    );
  }

  Widget buildLifecycleFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromEndpoint = _QuiHeroLifecycleEndpoint.fromHeroContext(fromHeroContext);
    final toEndpoint = _QuiHeroLifecycleEndpoint.fromHeroContext(toHeroContext);
    final originEndpoint = fromEndpoint;

    return _QuiHeroLifecycleFlightShuttle(
      animation: animation,
      flightDirection: flightDirection,
      onStartCallbacks: originEndpoint.onStartCallbacks,
      onEndCallbacks: originEndpoint.onEndCallbacks,
      child: flightShuttleBuilder(
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
        fromEndpoint.child,
        toEndpoint.child,
      ),
    );
  }

  QuiHero buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
    QuiHeroTextFlightMetrics? flightMetrics,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      createRectTween: createRectTween,
      flightShuttleBuilder: buildLifecycleFlightShuttle,
      transitionOnUserGestures: true,
      child: buildLifecycleEndpoint(context),
    );
  }
}

@Preview(name: 'QuiHero', group: 'Hero')
Widget quiHeroPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: const Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 100,
              child: QuiHeroBackground(
                tag: 'preview-box',
                extensions: [],
                decoration: BoxDecoration(
                  color: Color(0xFFFF4A4B),
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: Center(
                  child: Text(
                    'Preview Text',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 260,
              child: QuiHeroText(
                'Preview Title',
                tag: 'preview-text',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
