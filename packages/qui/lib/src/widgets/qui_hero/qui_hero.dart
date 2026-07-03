library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';

import 'qui_hero_extension/qui_hero_drag_to_close_extension/qui_hero_drag_to_close_extension.dart';
import 'qui_hero_extension/qui_hero_extension.dart';
import 'qui_hero_page/qui_hero_page.dart';

part 'qui_hero_box/_qui_hero_box.dart';
part 'qui_hero_box/qui_hero_box_flight/_qui_hero_box_flight.dart';
part 'qui_hero_enums.dart';
part 'qui_hero_group/_qui_hero_group.dart';
part 'qui_hero_group/_qui_hero_group_content.dart';
part 'qui_hero_group/_qui_hero_group_layout.dart';
part 'qui_hero_group/_qui_hero_group_scope.dart';
part 'qui_hero_group/qui_hero_group_enums.dart';
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
/// [QuiHero] exposes typed factory constructors:
///
///  * [QuiHero.text] — animates a text block. The [TextStyle] is smoothly
///    interpolated via [TextStyle.lerp] throughout the flight. Text content,
///    wrapping (`maxLines`, `overflow`) and text alignment switch from source
///    to destination at the point defined by [QuiHero.text.switchThreshold]
///  * [QuiHero.box] — animates a [BoxDecoration]. Color, border radius,
///    shadows, gradients, and border are interpolated via
///    [Decoration.lerp]. The `child` renders natively on each screen but is
///    **not** carried into the flight overlay — only the decoration morphs.
///    Nest other [QuiHero] variants inside `child` to animate inner elements
///    independently alongside the box.
///
/// Variants can use a [tag] to pair source and destination explicitly. When
/// [tag] is omitted, QUI uses a private default tag for that variant. This
/// keeps simple routes lightweight: one tagless [QuiHero.text], one tagless
/// [QuiHero.box], etc. can coexist and animate to
/// the matching variant on the destination route. If a route has multiple
/// active heroes of the same tagless variant, Flutter asserts at navigation
/// time; pass explicit tags for those cases.
///
/// ## Performance on low-end devices
///
/// Flight shuttles are wrapped in [RepaintBoundary] to isolate repaint work.
/// Decoration and text interpolation use [Curves.easeOutCubic] — a
/// cost-effective easing curve that performs well on low-end GPUs
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
sealed class QuiHero extends StatelessWidget {
  /// Creates a text hero that animates [TextStyle], content, and wrapping
  /// behavior between source and destination.
  ///
  /// The [TextStyle] is interpolated via [TextStyle.lerp] across the full
  /// flight. Text content and layout constraints ([maxLines], [overflow])
  /// switch from the source configuration to the destination configuration
  /// at the exact midpoint (50 %) of the flight animation. The optional
  /// [padding] is applied around the text and is interpolated during flight.
  ///
  /// [switchThreshold] controls when text content, wrapping constraints, and
  /// alignment switch from the source to the destination during the flight.
  /// The origin's [switchThreshold] governs the push direction; the
  /// destination's [switchThreshold] governs the pop direction. A higher
  /// value delays the switch; a lower value triggers it earlier. Must be
  /// between `0.0` and `1.0`
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
    required String text,
    Object? tag,
    TextStyle? style,
    TextAlign textAlign = TextAlign.left,
    TextOverflow? overflow,
    int? maxLines,
    EdgeInsetsGeometry? padding,
    double switchThreshold = 0.5,
    Key? key,
  }) => _QuiHeroText(
    tag: tag,
    text: text,
    style: style,
    textAlign: textAlign,
    overflow: overflow,
    maxLines: maxLines,
    padding: padding,
    switchThreshold: switchThreshold,
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
    Object? tag,
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

  /// Creates a grouped hero that moves several [heroes] as one shared element.
  ///
  /// The optional [tag] identifies the whole group. When omitted, the group
  /// pairs with the single tagless group on the destination route. The inner
  /// [heroes] must be tagless [QuiHero] variants such as [QuiHero.text] or
  /// [QuiHero.box]. The group captures the closest supported parent layout
  /// ([Column], [Row], [Flex], or [Stack]) and reuses that layout during the
  /// shared-element flight.
  factory QuiHero.group({required List<QuiHero> heroes, Object? tag, Key? key}) =>
      _QuiHeroGroup(tag: tag, heroes: heroes, key: key);

  const QuiHero._({required this.tag, required this._defaultTag, required this._flightShuttleBuilder, super.key});

  /// The optional identifier that pairs source and destination heroes.
  ///
  /// This [tag] must be identical on both the source and destination
  /// instances of the same shared element. It must be unique among all
  /// heroes in the same scope.
  ///
  /// When [tag] is omitted, QUI uses a private default tag for this hero
  /// variant. This is intended for the unambiguous case where a route has only
  /// one active hero of that variant. If there are multiple heroes of the same
  /// tagless variant in the same route, pass explicit tags.
  final Object? tag;

  final Object _defaultTag;

  final HeroFlightShuttleBuilder _flightShuttleBuilder;

  Widget _buildFlightChild(BuildContext context);

  static RectTween _createRectTween(Rect? begin, Rect? end) {
    return RectTween(begin: begin, end: end);
  }

  QuiHero _buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag ?? _defaultTag,
      createRectTween: _createRectTween,
      flightShuttleBuilder: _flightShuttleBuilder,
      transitionOnUserGestures: true,
      child: _buildFlightChild(context),
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
