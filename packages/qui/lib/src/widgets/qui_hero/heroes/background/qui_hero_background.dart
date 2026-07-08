library;

import 'package:flutter/material.dart';
import 'package:qui/src/widgets/qui_edge_fade/qui_edge_fade.dart' show QuiEdgeFade, QuiEdgeFadePosition;
import 'package:qui/src/widgets/qui_hero/heroes/group/qui_hero_group.dart';
import 'package:qui/src/widgets/qui_hero/heroes/text/qui_hero_text.dart';
import 'package:qui/src/widgets/qui_hero/qui_hero.dart';
import 'package:qui/src/widgets/qui_hero/qui_hero_extension/qui_hero_extension.dart';

part '_qui_hero_background_edge_fade.dart';
part '_qui_hero_background_flight.dart';
part '_qui_hero_background_scope.dart';

final class QuiHeroBackground extends QuiHero {
  const QuiHeroBackground({
    Object? tag,
    this.extensions = const [],
    super.onStart,
    super.onEnd,
    super.onReceived,
    super.key,
    this.decoration,
    this.width,
    this.height,
    this.padding,
    this.edgeFade,
    this.child,
  }) : super(tag: tag ?? QuiHeroDefaultTag.box, flightShuttleBuilder: _buildFlightShuttle);

  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final QuiHeroEdgeFade? edgeFade;
  final List<QuiHeroExtension> extensions;
  final Widget? child;

  static QuiHeroBackgroundFlight _lerpBoxFlight({
    required QuiHeroBackgroundFlight from,
    required QuiHeroBackgroundFlight to,
    required double value,
  }) {
    return QuiHeroBackgroundFlight(decoration: BoxDecoration.lerp(from.decoration, to.decoration, value));
  }

  static Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
    Widget fromHeroChild,
    Widget toHeroChild,
  ) {
    final fromBox = fromHeroChild as QuiHeroBackgroundFlight;
    final toBox = toHeroChild as QuiHeroBackgroundFlight;
    final begin = flightDirection == HeroFlightDirection.push ? fromBox : toBox;
    final end = flightDirection == HeroFlightDirection.push ? toBox : fromBox;

    if (begin.decoration == end.decoration) {
      return RepaintBoundary(child: begin);
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return _lerpBoxFlight(from: begin, to: end, value: Curves.easeOutCubic.transform(animation.value));
        },
      ),
    );
  }

  static Widget _buildEdgeFadeFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromHero = (fromHeroContext.widget as Hero).child as QuiHeroBackgroundEdgeFade;
    final toHero = (toHeroContext.widget as Hero).child as QuiHeroBackgroundEdgeFade;
    final fromHeroChild = fromHero.edgeFade;
    final toHeroChild = toHero.edgeFade;
    final fromRadius = fromHero.borderRadius;
    final toRadius = toHero.borderRadius;

    final sourceFade = fromHeroChild;
    final destinationFade = toHeroChild;
    final sourceRadius = fromRadius;
    final destinationRadius = toRadius;

    final resolvedSource = sourceFade?.resolve(flightContext) ?? const QuiHeroEdgeFade().resolve(flightContext);
    final resolvedDestination =
        destinationFade?.resolve(flightContext) ?? const QuiHeroEdgeFade().resolve(flightContext);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final animationValue = flightDirection == HeroFlightDirection.push ? animation.value : 1 - animation.value;
          final edgeFadeProgress = resolvedSource.switchThreshold >= 1.0
              ? Curves.easeOutCubic.transform(animationValue)
              : animationValue;
          final radiusProgress = Curves.easeOutCubic.transform(animationValue);
          final lerpedFade = QuiHeroEdgeFade.lerp(resolvedSource, resolvedDestination, edgeFadeProgress);
          final lerpedRadius =
              BorderRadiusGeometry.lerp(sourceRadius, destinationRadius, radiusProgress) as BorderRadius?;
          return IgnorePointer(
            child: QuiHeroBackgroundEdgeFade(edgeFade: lerpedFade, borderRadius: lerpedRadius),
          );
        },
      ),
    );
  }

  static double? _tryLerpDouble(double? begin, double? end, double value) {
    if (begin == null && end == null) return null;

    final beginValue = begin ?? 0;
    return beginValue + ((end ?? 0) - beginValue) * value;
  }

  @override
  Widget buildFlightChild(BuildContext context) {
    return QuiHeroBackgroundFlight(decoration: decoration);
  }

  @override
  Widget build(BuildContext context) {
    if (QuiHeroGroupScope.maybeOf(context) != null) {
      return _buildSizedContent(flightChild: buildFlightChild(context), context: context);
    }

    return _wrapWithExtensions(
      context: context,
      child: _buildSizedContent(flightChild: _buildHero(context), boxContext: context, context: context),
    );
  }

  @override
  QuiHeroBackground buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
    QuiHeroTextFlightMetrics? flightMetrics,
  }) {
    final endBox = end as QuiHeroBackground;
    final lerpValue = flightDirection == HeroFlightDirection.push ? value : (1 - value);

    final lerpedBox = _lerpBoxFlight(
      from: QuiHeroBackgroundFlight(decoration: decoration),
      to: QuiHeroBackgroundFlight(decoration: endBox.decoration),
      value: lerpValue,
    );

    return QuiHeroBackground(
      tag: null,
      decoration: lerpedBox.decoration,
      width: _tryLerpDouble(width, endBox.width, lerpValue),
      height: _tryLerpDouble(height, endBox.height, lerpValue),
      padding: EdgeInsetsGeometry.lerp(padding, endBox.padding, lerpValue),
      edgeFade: lerpValue < 0.5 ? edgeFade : endBox.edgeFade,
      extensions: const [],
      onStart: null,
      onEnd: null,
      onReceived: null,
      child: lerpValue < 0.5 ? child : endBox.child,
    );
  }

  Widget _buildEdgeFadeHero(BuildContext context, BorderRadiusGeometry? borderRadius) {
    final edgeFadeTag = ValueKey((tag, QuiHeroDefaultTag.edgeFade));

    return Hero(
      tag: edgeFadeTag,
      createRectTween: QuiHero.createRectTween,
      flightShuttleBuilder: _buildEdgeFadeFlightShuttle,
      transitionOnUserGestures: true,
      child: QuiHeroBackgroundEdgeFade(edgeFade: edgeFade, borderRadius: borderRadius),
    );
  }

  Widget _buildHero(BuildContext context) {
    final heroTag = tag;
    return Hero(
      tag: heroTag,
      createRectTween: QuiHero.createRectTween,
      flightShuttleBuilder: buildLifecycleFlightShuttle,
      transitionOnUserGestures: true,
      child: buildLifecycleEndpoint(context),
    );
  }

  Widget _buildSizedContent({required Widget flightChild, required BuildContext context, BuildContext? boxContext}) {
    final child = this.child;
    var result = flightChild;

    if (child != null) {
      var content = child;
      if (padding != null) content = Padding(padding: padding!, child: content);
      if (boxContext != null) {
        content = QuiHeroBackgroundScope(context: boxContext, child: content);
      }

      final borderRadius = decoration?.borderRadius?.resolve(Directionality.of(context));
      result = Stack(
        children: [
          Positioned.fill(child: result),
          content,
          Positioned.fill(child: _buildEdgeFadeHero(context, borderRadius)),
        ],
      );
    }

    if (width != null || height != null) result = SizedBox(width: width, height: height, child: result);

    return result;
  }

  Widget _wrapWithExtensions({required BuildContext context, required Widget child}) {
    var result = child;

    for (final extension in extensions.reversed) {
      result = extension.wrap(context: context, child: result);
    }

    return result;
  }
}
