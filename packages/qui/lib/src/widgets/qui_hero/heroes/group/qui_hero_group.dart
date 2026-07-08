library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qui/src/widgets/qui_hero/heroes/background/qui_hero_background.dart';
import 'package:qui/src/widgets/qui_hero/heroes/text/qui_hero_text.dart';
import 'package:qui/src/widgets/qui_hero/qui_hero.dart';

part '_qui_hero_group_background_flight_metrics.dart';
part '_qui_hero_group_content.dart';
part '_qui_hero_group_enums.dart';
part '_qui_hero_group_height_clamp_scope.dart';
part '_qui_hero_group_layout.dart';
part '_qui_hero_group_scope.dart';

/// A group hero that animates several tagless [QuiHero] children as a single
/// shared element across screens.
///
/// Unlike [QuiHeroText] or [QuiHeroBackground], which animate a single element,
/// [QuiHeroGroup] composites multiple heroes and flies them together. The group
/// captures the closest supported parent layout — [Column], [Row], [Flex], or
/// [Stack] — and mirrors that layout during the shared-element flight so each
/// child maintains its relative position.
///
/// ## Pairing rule
///
/// Heroes in a group are matched by **positional order** (not by tag). Source
/// and destination must have the same number of children. Each child hero at
/// index *i* on the source group flies to the child hero at index *i* on the
/// destination group.
///
/// Child heroes inside a group must be **tagless** — the group owns the shared
/// tag. If a route has multiple groups, assign them explicit [tag]s.
///
/// ## Nesting inside a background
///
/// When [QuiHeroGroup] is placed inside [QuiHeroBackground], the group flight
/// clamps its content to the background box's bounds so children stay visually
/// inside the background shape during the animation.
///
/// ## Lifecycle
///
/// The group aggregates lifecycle callbacks from all children. [onStart] fires
/// after all child [onStart] callbacks; [onEnd] fires after all child [onEnd]
/// callbacks.
///
/// ```dart
/// QuiHeroGroup(
///   heroes: [
///     QuiHeroText('1 dia atrás', style: TextStyle(fontSize: 14)),
///     QuiHeroText('Separador de Mercadorias', style: TextStyle(fontSize: 22)),
///     QuiHeroText(r'R\$2.200/mês', style: TextStyle(fontSize: 25, color: Color(0xFF00DD55))),
///   ],
/// )
/// ```
///
/// See also:
///  * [QuiHeroText], a hero that animates a single text element.
///  * [QuiHeroBackground], a hero that animates a [BoxDecoration].
final class QuiHeroGroup extends QuiHero {
  /// Creates a group hero that animates [heroes] as a single shared element.
  ///
  /// All [heroes] must be tagless — the group owns the shared tag. Pass an
  /// explicit [tag] when multiple groups coexist on the same route.
  ///
  /// See [QuiHeroGroup] for pairing rules and nesting constraints.
  const QuiHeroGroup({required this.heroes, Object? tag, super.onStart, super.onEnd, super.onReceived, super.key})
    : super(tag: tag ?? QuiHeroDefaultTag.group, flightShuttleBuilder: _buildFlightShuttle);

  static List<({double layoutWidth, Offset offset, Size size})>? _cachedEndChildMetrics;
  static QuiHeroGroupBackgroundFlightMetrics? _cachedEndBoxMetrics;

  /// The tagless child heroes that animate together.
  ///
  /// Every hero in this list must have no explicit [tag]. Source and
  /// destination groups must have the same length — heroes are paired by
  /// positional index.
  final List<QuiHero> heroes;

  static Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
    Widget fromHeroChild,
    Widget toHeroChild,
  ) {
    final fromGroup = fromHeroChild as _QuiHeroGroupContent;
    final toGroup = toHeroChild as _QuiHeroGroupContent;
    final beginChildMetrics = _captureFlexChildMetrics(fromHeroContext);

    final freshEndChildMetrics = _captureFlexChildMetrics(toHeroContext);
    if (freshEndChildMetrics != null) _cachedEndChildMetrics = freshEndChildMetrics;
    final endChildMetrics = freshEndChildMetrics ?? _cachedEndChildMetrics ?? beginChildMetrics;

    final beginBackgroundMetrics = _captureBackgroundMetrics(fromHeroContext);
    final freshEndBackgroundMetrics = _captureBackgroundMetrics(toHeroContext);

    if (freshEndBackgroundMetrics != null) _cachedEndBoxMetrics = freshEndBackgroundMetrics;
    final endBoxMetrics = freshEndBackgroundMetrics ?? _cachedEndBoxMetrics ?? beginBackgroundMetrics;

    final beginHeight = _metricsHeight(beginChildMetrics);
    final endHeight = _metricsHeight(endChildMetrics);

    final textMetrics = <QuiHeroTextFlightMetrics?>[];
    final count = math.min(fromGroup.heroes.length, toGroup.heroes.length);
    for (var i = 0; i < count; i++) {
      final fromHero = fromGroup.heroes[i];
      final toHero = toGroup.heroes[i];

      if (fromHero is QuiHeroText && toHero is QuiHeroText) {
        final fromText = fromHero.buildFlightChild(flightContext) as QuiHeroTextFlight;
        final toText = toHero.buildFlightChild(flightContext) as QuiHeroTextFlight;

        final beginSize = (beginChildMetrics != null && i < beginChildMetrics.length)
            ? beginChildMetrics[i].size as Size?
            : null;

        final endSize = (endChildMetrics != null && i < endChildMetrics.length)
            ? endChildMetrics[i].size as Size?
            : null;

        final beginLayoutWidth = (beginChildMetrics != null && i < beginChildMetrics.length)
            ? beginChildMetrics[i].layoutWidth as double?
            : null;

        final endLayoutWidth = (endChildMetrics != null && i < endChildMetrics.length)
            ? endChildMetrics[i].layoutWidth as double?
            : null;

        textMetrics.add(
          QuiHeroTextFlightMetrics.precompute(
            context: flightContext,
            from: fromText,
            to: toText,
            beginSize: beginSize,
            endSize: endSize,
            beginLayoutWidth: beginLayoutWidth,
            endLayoutWidth: endLayoutWidth,
          ),
        );
      } else {
        textMetrics.add(null);
      }
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final animationValue = flightDirection == HeroFlightDirection.push ? animation.value : 1 - animation.value;
          final value = Curves.easeOutCubic.transform(animationValue);

          final availableHeight = _computeAvailableHeight(
            beginBoxMetrics: beginBackgroundMetrics,
            endBoxMetrics: endBoxMetrics,
            progress: value,
          );

          return _QuiHeroGroupContent(
            layout: toGroup.layout,
            heroes: _lerpHeroes(
              begin: fromGroup.heroes,
              end: toGroup.heroes,
              value: value,
              flightDirection: HeroFlightDirection.push,
              textMetrics: textMetrics,
            ),
            allowsFlightOverflow: true,
            beginChildMetrics: beginChildMetrics,
            endChildMetrics: endChildMetrics,
            flightValue: value,
            maxAvailableHeight: availableHeight,
            beginHeight: beginHeight,
            endHeight: endHeight,
          );
        },
      ),
    );
  }

  static List<({double layoutWidth, Offset offset, Size size})>? _captureFlexChildMetrics(BuildContext context) {
    final groupBox = context.findRenderObject();
    if (groupBox is! RenderBox || !groupBox.hasSize) return null;

    final flex = _findRenderFlex(groupBox);
    if (flex == null || !flex.hasSize || flex.direction != Axis.vertical) return null;

    final groupOrigin = groupBox.localToGlobal(Offset.zero);
    final metrics = <({double layoutWidth, Offset offset, Size size})>[];
    var child = flex.firstChild;

    while (child != null) {
      final parentData = child.parentData;
      if (parentData is! FlexParentData || !child.hasSize) return null;

      metrics.add((
        layoutWidth: _layoutWidthForChild(child: child, fallbackWidth: flex.size.width),
        offset: flex.localToGlobal(parentData.offset) - groupOrigin,
        size: child.size,
      ));
      child = parentData.nextSibling;
    }

    return metrics;
  }

  static double _layoutWidthForChild({required RenderBox child, required double fallbackWidth}) {
    final paragraphWidth = _paragraphLayoutWidth(child);
    if (paragraphWidth != null) return paragraphWidth;

    return fallbackWidth;
  }

  static double? _paragraphLayoutWidth(RenderObject root) {
    if (root is RenderParagraph && root.constraints.hasBoundedWidth) return root.constraints.maxWidth;

    double? result;

    void visit(RenderObject child) {
      if (result != null) return;
      result = _paragraphLayoutWidth(child);
    }

    root.visitChildren(visit);
    return result;
  }

  static RenderFlex? _findRenderFlex(RenderObject root) {
    RenderFlex? result;

    void visit(RenderObject child) {
      if (result != null) return;

      if (child is RenderFlex) {
        result = child;
        return;
      }

      child.visitChildren(visit);
    }

    root.visitChildren(visit);
    return result;
  }

  static List<QuiHero> _lerpHeroes({
    required List<QuiHero> begin,
    required List<QuiHero> end,
    required double value,
    required HeroFlightDirection flightDirection,
    List<QuiHeroTextFlightMetrics?>? textMetrics,
  }) {
    final count = math.min(begin.length, end.length);
    return List<QuiHero>.generate(count, (index) {
      final beginHero = begin[index];
      final endHero = end[index];
      final metrics = (textMetrics != null && index < textMetrics.length) ? textMetrics[index] : null;

      return beginHero.buildForGroupFlight(
        end: endHero,
        value: value,
        flightDirection: flightDirection,
        flightMetrics: metrics,
      );
    });
  }

  static QuiHeroGroupBackgroundFlightMetrics? _captureBackgroundMetrics(BuildContext heroContext) {
    final boxScope = QuiHeroBackgroundScope.maybeOf(heroContext);
    if (boxScope == null) return null;

    final boxRenderObject = boxScope.boxRenderObject;
    if (boxRenderObject == null || !boxRenderObject.hasSize) return null;

    final groupRenderObject = heroContext.findRenderObject();
    if (groupRenderObject is! RenderBox || !groupRenderObject.hasSize) return null;

    final boxOrigin = boxRenderObject.localToGlobal(Offset.zero);
    final groupOrigin = groupRenderObject.localToGlobal(Offset.zero);
    final groupOffsetInBox = groupOrigin - boxOrigin;

    return QuiHeroGroupBackgroundFlightMetrics(size: boxRenderObject.size, groupOffsetInBox: groupOffsetInBox);
  }

  static double? _computeAvailableHeight({
    required QuiHeroGroupBackgroundFlightMetrics? beginBoxMetrics,
    required QuiHeroGroupBackgroundFlightMetrics? endBoxMetrics,
    required double progress,
  }) {
    if (beginBoxMetrics == null || endBoxMetrics == null) return null;

    final beginBoxHeight = beginBoxMetrics.size.height;
    final endBoxHeight = endBoxMetrics.size.height;
    final currentBoxHeight = beginBoxHeight + (endBoxHeight - beginBoxHeight) * progress;

    final beginGroupOffset = beginBoxMetrics.groupOffsetInBox.dy;
    final endGroupOffset = endBoxMetrics.groupOffsetInBox.dy;
    final currentGroupOffset = beginGroupOffset + (endGroupOffset - beginGroupOffset) * progress;

    final available = currentBoxHeight - currentGroupOffset;
    return available > 0 ? available : 0.0;
  }

  static double _metricsHeight(List<({double layoutWidth, Offset offset, Size size})>? metrics) {
    if (metrics == null || metrics.isEmpty) return 0;

    var height = 0.0;

    for (final metric in metrics) {
      height = math.max(height, metric.offset.dy + metric.size.height);
    }

    return height;
  }

  static List<QuiHero> _resolveEndpointHeroes({required BuildContext context, required List<QuiHero> heroes}) {
    return [
      for (final hero in heroes)
        if (hero is QuiHeroText) hero.buildWithResolvedStyle(context) else hero,
    ];
  }

  @override
  List<VoidCallback> lifecycleStartCallbacks(BuildContext context) {
    return [
      ...super.lifecycleStartCallbacks(context),
      for (final hero in heroes) ...hero.lifecycleStartCallbacks(context),
    ];
  }

  @override
  List<VoidCallback> lifecycleEndCallbacks(BuildContext context) {
    return [...super.lifecycleEndCallbacks(context), for (final hero in heroes) ...hero.lifecycleEndCallbacks(context)];
  }

  @override
  List<VoidCallback> lifecycleReceivedCallbacks(BuildContext context) {
    return [
      ...super.lifecycleReceivedCallbacks(context),
      for (final hero in heroes) ...hero.lifecycleReceivedCallbacks(context),
    ];
  }

  @override
  QuiHero buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
    QuiHeroTextFlightMetrics? flightMetrics,
  }) {
    assert(false, 'Nested QuiHero.group is not supported.');
    return value < 0.5 ? this : end;
  }

  @override
  Widget buildFlightChild(BuildContext context) {
    return _QuiHeroGroupContent(
      layout: QuiHeroGroupLayout.fromContext(context),
      heroes: _resolveEndpointHeroes(context: context, heroes: heroes),
    );
  }
}
