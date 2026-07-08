library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qui/src/widgets/qui_hero/heroes/group/qui_hero_group.dart';
import 'package:qui/src/widgets/qui_hero/qui_hero.dart';

part '_qui_hero_text_flight.dart';
part '_qui_hero_text_flight_metrics.dart';
part '_qui_hero_text_scaled_metrics.dart';

/// A hero widget that animates a text block between source and destination
/// routes.
///
/// [QuiHeroText] pairs with another [QuiHeroText] on the destination route
/// using the same [tag]. During the shared-element transition Flutter renders
/// a "flight" — an interpolated copy that morphs [TextStyle], text content,
/// alignment, overflow behavior, layout constraints ([maxLines]), and padding.
///
///
/// ## Flight progress and easing
///
/// Style interpolation uses [Curves.easeOutCubic] — a lightweight easing
/// curve that performs well on low-end GPUs while producing smooth,
/// natural-looking motion.
final class QuiHeroText extends QuiHero {
  /// Creates a text hero with the given [tag], [text], and optional style
  /// configuration.
  const QuiHeroText(
    this.text, {
    Object? tag,
    super.onStart,
    super.onEnd,
    super.onReceived,
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.overflow,
    this.maxLines,
    this.padding,
    this.switchThreshold = 0.5,
  }) : assert(switchThreshold >= 0.0 && switchThreshold <= 1.0, 'switchThreshold must be between 0.0 and 1.0.'),
       _flight = null,
       super(tag: tag ?? QuiHeroDefaultTag.text, flightShuttleBuilder: _buildFlightShuttle);

  QuiHeroText._fromFlight(QuiHeroTextFlight flight)
    : text = flight.text,
      style = flight.style,
      textAlign = flight.textAlign,
      overflow = flight.overflow,
      maxLines = flight.maxLines,
      padding = flight.padding,
      switchThreshold = flight.switchThreshold,
      _flight = flight,
      super(tag: QuiHeroDefaultTag.text, flightShuttleBuilder: _buildFlightShuttle, onStart: null, onEnd: null, onReceived: null);

  QuiHeroText buildWithResolvedStyle(BuildContext context) {
    return QuiHeroText(
      text,
      tag: tag,
      style: _resolvedStyle(context),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      padding: padding,
      switchThreshold: switchThreshold,
      onStart: onStart,
      onEnd: onEnd,
      onReceived: onReceived,
      key: key,
    );
  }

  static QuiHeroTextFlight _lerpTextFlight({
    required QuiHeroTextFlight from,
    required QuiHeroTextFlight to,
    required double value,
    required HeroFlightDirection flightDirection,
    QuiHeroTextFlightMetrics? flightMetrics,
  }) {
    final lerpValue = flightDirection == HeroFlightDirection.push ? value : (1 - value);
    final showBegin = lerpValue < from.switchThreshold;
    final lerpedStyle = TextStyle.lerp(from.style, to.style, lerpValue)!;
    final progressiveClampMaxLines = _progressiveClampMaxLinesHelper(from: from, to: to, showBegin: showBegin);
    return QuiHeroTextFlight(
      text: showBegin ? from.text : to.text,
      style: lerpedStyle,
      flightBeginStyle: from.style,
      flightEndStyle: to.style,
      flightProgress: lerpValue,
      maxLines: showBegin ? from.maxLines : to.maxLines,
      overflow: showBegin ? from.overflow : to.overflow,
      textAlign: showBegin ? from.textAlign : to.textAlign,
      padding: EdgeInsetsGeometry.lerp(from.padding, to.padding, lerpValue),
      switchThreshold: from.switchThreshold,
      shortenToBounds: true,
      progressiveClampMaxLines: progressiveClampMaxLines,
      progressiveClampProgress: _progressiveClampProgressHelper(
        lerpValue: lerpValue,
        switchThreshold: from.switchThreshold,
        progressiveClampMaxLines: progressiveClampMaxLines,
      ),
      flightMetrics: flightMetrics,
    );
  }

  static int? _progressiveClampMaxLinesHelper({
    required QuiHeroTextFlight from,
    required QuiHeroTextFlight to,
    required bool showBegin,
  }) {
    if (!showBegin) return null;
    if (to.maxLines == null) return null;
    if (from.maxLines != null && from.maxLines! <= to.maxLines!) return null;

    return to.maxLines;
  }

  static double _progressiveClampProgressHelper({
    required double lerpValue,
    required double switchThreshold,
    required int? progressiveClampMaxLines,
  }) {
    if (progressiveClampMaxLines == null) return 0;
    if (switchThreshold <= 0) return 1;

    return (lerpValue / switchThreshold).clamp(0.0, 1.0);
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
    final fromText = fromHeroChild as QuiHeroTextFlight;
    final toText = toHeroChild as QuiHeroTextFlight;

    if (_hasSamePresentation(begin: fromText, end: toText)) {
      return RepaintBoundary(child: fromText.copyWith(shortenToBounds: true));
    }

    final flightMetrics = QuiHeroTextFlightMetrics.precompute(context: flightContext, from: fromText, to: toText);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return _lerpTextFlight(
            from: fromText,
            to: toText,
            value: Curves.easeOutCubic.transform(animation.value),
            flightDirection: flightDirection,
            flightMetrics: flightMetrics,
          );
        },
      ),
    );
  }

  static bool _hasSamePresentation({required QuiHeroTextFlight begin, required QuiHeroTextFlight end}) {
    return begin.text == end.text &&
        begin.style == end.style &&
        begin.textAlign == end.textAlign &&
        begin.overflow == end.overflow &&
        begin.maxLines == end.maxLines &&
        begin.padding == end.padding;
  }

  /// The text content rendered by this hero.
  final String text;

  /// The optional [TextStyle] applied to the text.
  ///
  /// When null, [DefaultTextStyle.of] is used at build time.
  final TextStyle? style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// The maximum number of lines for the text.
  final int? maxLines;

  /// Optional padding around the text.
  final EdgeInsetsGeometry? padding;

  /// The flight progress threshold (0.0–1.0) at which text string switches
  /// from the source string to the destination string.
  final double switchThreshold;

  final QuiHeroTextFlight? _flight;

  ({QuiHeroText hero, double? estimatedHeight}) buildWithEndpointMetricsAndEstimatedHeight({
    required BuildContext context,
    required double width,
    required Size beginSize,
    required Size endSize,
    required double beginLayoutWidth,
    required double endLayoutWidth,
  }) {
    final flight = _flight;
    if (flight == null) return (hero: this, estimatedHeight: null);

    if (flight.flightMetrics != null) {
      final measuredFlight = flight.copyWith(
        endpointMaxLines: flight.flightMetrics!.endpointMaxLines,
        endpointReservedLayoutWidth: flight._endpointReservedLayoutWidthFor(
          beginLayoutWidth: beginLayoutWidth,
          endLayoutWidth: endLayoutWidth,
        ),
      );
      return (
        hero: QuiHeroText._fromFlight(measuredFlight),
        estimatedHeight: measuredFlight._estimatedHeightForWidth(context: context, width: width),
      );
    }

    final endpointMaxLines = flight._endpointMaxLinesFor(context: context, beginSize: beginSize, endSize: endSize);
    final measuredFlight = flight.copyWith(
      endpointMaxLines: endpointMaxLines,
      endpointReservedLayoutWidth: flight._endpointReservedLayoutWidthFor(
        beginLayoutWidth: beginLayoutWidth,
        endLayoutWidth: endLayoutWidth,
      ),
    );

    return (
      hero: QuiHeroText._fromFlight(measuredFlight),
      estimatedHeight: measuredFlight._estimatedHeightForWidth(context: context, width: width),
    );
  }

  @override
  Widget buildFlightChild(BuildContext context) {
    return QuiHeroTextFlight(
      text: text,
      style: _resolvedStyle(context),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      padding: padding,
      switchThreshold: switchThreshold,
    );
  }

  @override
  QuiHeroText buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
    dynamic flightMetrics,
  }) {
    final endText = end as QuiHeroText;

    return QuiHeroText._fromFlight(
      _lerpTextFlight(
        from: QuiHeroTextFlight(
          text: text,
          style: style ?? const TextStyle(),
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          padding: padding,
          switchThreshold: switchThreshold,
          shortenToBounds: true,
        ),
        to: QuiHeroTextFlight(
          text: endText.text,
          style: endText.style ?? const TextStyle(),
          textAlign: endText.textAlign,
          overflow: endText.overflow,
          maxLines: endText.maxLines,
          padding: endText.padding,
          switchThreshold: endText.switchThreshold,
        ),
        value: value,
        flightDirection: flightDirection,
        flightMetrics: flightMetrics as QuiHeroTextFlightMetrics?,
      ),
    );
  }

  TextStyle _resolvedStyle(BuildContext context) => DefaultTextStyle.of(context).style.merge(style);

  @override
  Widget build(BuildContext context) {
    if (QuiHeroGroupScope.maybeOf(context) != null) {
      if (_flight != null) return _flight;

      Widget result = Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
      if (padding != null) result = Padding(padding: padding!, child: result);
      return result;
    }

    return super.build(context);
  }
}
