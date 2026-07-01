library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';

import 'qui_hero_extension/qui_hero_drag_to_close_extension/qui_hero_drag_to_close_extension.dart';
import 'qui_hero_extension/qui_hero_extension.dart';
import 'qui_hero_page/qui_hero_page.dart';

part 'qui_hero_box/_qui_hero_box.dart';
part 'qui_hero_box/qui_hero_box_flight/_qui_hero_box_flight.dart';
part 'qui_hero_text/_qui_hero_text.dart';
part 'qui_hero_text/qui_hero_text_flight/_qui_hero_text_flight.dart';

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
/// ## Choosing a variant
///
/// [QuiHero] exposes two typed factory constructors:
///
///  * [QuiHero.text] — animates a text block. The [TextStyle] is smoothly
///    interpolated via [TextStyle.lerp] throughout the flight. Text content
///    and wrapping (`maxLines`, `overflow`) switch from source to destination
///    at the 50 % mark of the animation.
///  * [QuiHero.box] — animates a [BoxDecoration]. Color, border radius,
///    shadows, gradients, and border are interpolated via
///    [Decoration.lerp]. The [child] renders natively on each screen but is
///    **not** carried into the flight overlay — only the decoration morphs.
///    Nest other [QuiHero] variants inside [child] to animate inner elements
///    independently alongside the box.
///
/// Both variants use a [tag] to pair source and destination. The [tag] must
/// be unique among all heroes in scope but identical on both sides of the
/// same shared element.
///
/// ## Performance on low-end devices
///
/// Flight shuttles are wrapped in [RepaintBoundary] to isolate repaint work.
/// Decoration and text interpolation use [Curves.easeOutCubic] — a
/// cost-effective easing curve that performs well on low-end GPUs common in
/// Latin America.
///
/// ```dart
/// // Source — a rounded box with title
/// QuiHero.box(
///   tag: 'card-1',
///   decoration: BoxDecoration(
///     color: surfaceColor,
///     borderRadius: BorderRadius.circular(38),
///   ),
///   child: QuiHero.text(
///     tag: 'card-1-title',
///     text: 'Garçom para Fim de Semana',
///     style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
///   ),
/// )
///
/// // Destination — same tags trigger the shared-element transition
/// QuiHero.box(
///   tag: 'card-1',
///   decoration: BoxDecoration(color: bgColor),
///   child: QuiHero.text(
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
///  * [QuiHeroDragToCloseExtension], a built-in extension that adds
///    drag-to-close gestures to hero destinations.
///  * Flutter's [Hero], the underlying widget that [QuiHero] wraps.
class QuiHero extends StatelessWidget {
  /// Creates a text hero that animates [TextStyle], content, and wrapping
  /// behavior between source and destination.
  ///
  /// The [TextStyle] is interpolated via [TextStyle.lerp] across the full
  /// flight. Text content and layout constraints ([maxLines], [overflow])
  /// switch from the source configuration to the destination configuration
  /// at the exact midpoint (50 %) of the flight animation.
  ///
  /// [textAlign] is **not** interpolated — the destination [textAlign] is
  /// used from the start. If the source and destination text alignments
  /// differ, the text jumps to the destination alignment immediately when
  /// the flight begins.
  ///
  /// ```dart
  /// // Source
  /// QuiHero.text(
  ///   tag: 'title',
  ///   text: 'Garçom para Fim de Semana',
  ///   style: TextStyle(fontSize: 18, color: textColor),
  ///   maxLines: 2,
  ///   overflow: TextOverflow.ellipsis,
  /// )
  ///
  /// // Destination
  /// QuiHero.text(
  ///   tag: 'title',
  ///   text: 'Garçom para Fim de Semana',
  ///   style: TextStyle(fontSize: 28, color: textColor),
  ///   maxLines: 4,
  /// )
  /// ```
  factory QuiHero.text({
    required Object tag,
    required String text,
    TextStyle? style,
    TextAlign textAlign = TextAlign.left,
    TextOverflow? overflow,
    int? maxLines,
    Key? key,
  }) => _QuiHeroText(
    tag: tag,
    text: text,
    style: style,
    textAlign: textAlign,
    overflow: overflow,
    maxLines: maxLines,
    key: key,
  );

  /// Creates a box hero that animates a [BoxDecoration] between source and
  /// destination.
  ///
  /// The [decoration] — color, border radius, shadows, gradients, and border —
  /// is interpolated via [Decoration.lerp]. Interpolation uses
  /// [Curves.easeOutCubic] for a natural feel at low GPU cost.
  ///
  /// The [child] renders natively on each screen but is **not** part of the
  /// flight overlay. To animate inner elements during the transition, nest
  /// [QuiHero.text] or other hero variants inside [child] with their own
  /// [tag] pairs. Each inner hero flies independently alongside the box.
  ///
  /// When [width] or [height] is set, the box is sized to those dimensions.
  /// When both are `null`, the box sizes itself to its [child]. [padding] is
  /// applied inside the box, outside the decoration.
  ///
  /// [extensions] attach reusable behaviors around the rendered hero tree.
  /// Multiple extensions are applied in declaration order: the first becomes
  /// the outermost wrapper.
  ///
  /// ```dart
  /// QuiHero.box(
  ///   tag: 'card-1',
  ///   width: double.infinity,
  ///   decoration: BoxDecoration(
  ///     color: surfaceColor,
  ///     borderRadius: BorderRadius.circular(38),
  ///   ),
  ///   padding: const EdgeInsets.all(24),
  ///   extensions: const [
  ///     QuiHeroDragToCloseExtension(scrollController: scrollController),
  ///   ],
  ///   child: Column(children: [
  ///     QuiHero.text(
  ///       tag: 'card-1-title',
  ///       text: job.title,
  ///       style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
  ///     ),
  ///   ]),
  /// )
  /// ```
  factory QuiHero.box({
    required Object tag,
    BoxDecoration? decoration,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    List<QuiHeroExtension> extensions = const [],
    Widget? child,
    Key? key,
  }) => _QuiHeroBox(
    tag: tag,
    decoration: decoration,
    width: width,
    height: height,
    padding: padding,
    extensions: extensions,
    key: key,
    userChild: child,
  );

  const QuiHero._({
    required this.tag,
    required this.child,
    required this.createRectTween,
    required this.flightShuttleBuilder,
    super.key,
  });

  /// The unique identifier that pairs source and destination heroes.
  ///
  /// This [tag] must be identical on both the source and destination
  /// instances of the same shared element. It must be unique among all
  /// heroes in the same scope.
  ///
  /// The [tag] is passed directly to Flutter's [Hero.tag].
  final Object tag;

  /// The widget rendered on each screen (not in the flight overlay).
  ///
  /// During the transition the source [child] and destination [child] are
  /// **not** visible — the [flightShuttleBuilder] produces the widget that
  /// appears in the overlay.
  final Widget child;

  /// The tween that animates the hero's bounding rectangle from the source
  /// position to the destination position.
  ///
  /// Each variant provides its own [CreateRectTween] implementation. The
  /// default uses a simple [RectTween] for linear position interpolation.
  final CreateRectTween createRectTween;

  /// Builds the widget that flies in the overlay during the transition.
  ///
  /// Each variant provides its own [HeroFlightShuttleBuilder] that handles
  /// decoration or text interpolation based on the current animation
  /// progress.
  final HeroFlightShuttleBuilder flightShuttleBuilder;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      createRectTween: createRectTween,
      flightShuttleBuilder: flightShuttleBuilder,
      transitionOnUserGestures: true,
      child: child,
    );
  }
}

@Preview(name: 'QuiHero', group: 'Hero')
Widget quiHeroPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 100,
              child: QuiHero.box(
                tag: 'preview-box',
                decoration: BoxDecoration(color: const Color(0xFFFF4A4B), borderRadius: BorderRadius.circular(24)),
                child: const Center(
                  child: Text(
                    'Cataquí',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 260,
              child: QuiHero.text(
                tag: 'preview-text',
                text: 'Cataquí Hero',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
