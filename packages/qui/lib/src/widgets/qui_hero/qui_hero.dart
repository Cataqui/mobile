library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';

import 'qui_hero_extension/qui_hero_extension.dart';

part 'qui_hero_box/_qui_hero_box.dart';
part 'qui_hero_box/qui_hero_box_flight/_qui_hero_box_flight.dart';
part 'qui_hero_text/_qui_hero_text.dart';
part 'qui_hero_text/qui_hero_text_flight/_qui_hero_text_flight.dart';

/// A premium hero widget that animates a shared element between two screens.
///
/// Unlike Flutter's raw [Hero], [QuiHero] provides typed variants —
/// [QuiHero.text] and [QuiHero.box] — with pre-built flight animations
/// optimized for low-end devices.
///
/// Each variant's [tag] pairs source and destination widgets. Use the same
/// [tag] on both screens to trigger the hero transition.
///
/// ```dart
/// // Source screen
/// QuiHero.box(tag: 'card-1', decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(38)))
///
/// // Destination screen
/// QuiHero.box(tag: 'card-1', decoration: BoxDecoration(color: bgColor))
/// ```
///
/// See also:
///   * QuiHeroPage, the destination [Page] that enables hero compositing.
///   * QuiHeroExtension, for reusable behavior attached to a hero variant.
class QuiHero extends StatelessWidget {
  /// Text hero — animates [TextStyle], [maxLines], [overflow], and text
  /// content during the flight.
  ///
  /// At the 50 % mark of the flight animation the text content and
  /// [maxLines]/[overflow] switch from the source to the destination
  /// configuration. [TextStyle] is smoothly interpolated via
  /// [TextStyle.lerp] throughout.
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

  /// Box hero — animates a [BoxDecoration] during the flight.
  ///
  /// Behaves like a lightweight [Container]: the [decoration] (color, border
  /// radius, shadows, gradients, border) is interpolated via
  /// [Decoration.lerp] between source and destination. The [child] renders
  /// natively on each side but is not carried into the flight overlay — only
  /// the decoration morphs.
  ///
  /// To animate other elements inside the box (e.g. text, icons, images),
  /// place other [QuiHero] variants as descendants of
  /// [child]. Each shared element uses its own [tag] pair and flies
  /// independently alongside the box decoration.
  ///
  /// Sizing ([width], [height]) and [padding] are handled by the hero itself.
  /// [extensions] attach reusable behavior around the rendered hero content.
  ///
  /// ```dart
  /// QuiHero.box(
  ///   tag: 'card-1',
  ///   width: double.infinity,
  ///   decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(38)),
  ///   padding: EdgeInsets.all(24),
  ///   extensions: [
  ///     QuiHeroDragToCloseExtension(scrollController: scrollController),
  ///   ],
  ///   child: Column(children: [
  ///     QuiHero.text(tag: 'card-1-title', text: job.title, ...),
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

  /// Unique tag matching source and destination heroes.
  final Object tag;

  /// The widget rendered natively (not in the overlay) on each side.
  final Widget child;

  final CreateRectTween createRectTween;

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
