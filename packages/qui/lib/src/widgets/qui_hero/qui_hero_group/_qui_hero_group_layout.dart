part of '../qui_hero.dart';

class _QuiHeroGroupLayout {
  const _QuiHeroGroupLayout.flex({
    required this.direction,
    required this.mainAxisAlignment,
    required this.mainAxisSize,
    required this.crossAxisAlignment,
    required this.textDirection,
    required this.verticalDirection,
    required this.textBaseline,
    required this.spacing,
  }) : type = _QuiHeroGroupLayoutType.flex,
       alignment = null,
       stackFit = null,
       clipBehavior = Clip.none;

  const _QuiHeroGroupLayout.stack({
    required this.alignment,
    required this.textDirection,
    required this.stackFit,
    required this.clipBehavior,
  }) : type = _QuiHeroGroupLayoutType.stack,
       direction = Axis.vertical,
       mainAxisAlignment = MainAxisAlignment.start,
       mainAxisSize = MainAxisSize.max,
       crossAxisAlignment = CrossAxisAlignment.center,
       verticalDirection = VerticalDirection.down,
       textBaseline = null,
       spacing = 0;

  factory _QuiHeroGroupLayout.fromContext(BuildContext context) {
    _QuiHeroGroupLayout? result;

    context.visitAncestorElements((element) {
      final widget = element.widget;

      if (widget is Flex) {
        result = _QuiHeroGroupLayout.flex(
          direction: widget.direction,
          mainAxisAlignment: widget.mainAxisAlignment,
          mainAxisSize: widget.mainAxisSize,
          crossAxisAlignment: widget.crossAxisAlignment,
          textDirection: widget.textDirection,
          verticalDirection: widget.verticalDirection,
          textBaseline: widget.textBaseline,
          spacing: widget.spacing,
        );
        return false;
      }

      if (widget is Stack) {
        result = _QuiHeroGroupLayout.stack(
          alignment: widget.alignment,
          textDirection: widget.textDirection,
          stackFit: widget.fit,
          clipBehavior: widget.clipBehavior,
        );
        return false;
      }

      return true;
    });

    assert(
      result != null,
      'QuiHero.group must be placed under a Column, Row, Flex, or Stack so it can mirror the parent layout.',
    );

    return result ??
        const _QuiHeroGroupLayout.flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: null,
          verticalDirection: VerticalDirection.down,
          textBaseline: null,
          spacing: 0,
        );
  }

  final _QuiHeroGroupLayoutType type;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final double spacing;
  final AlignmentGeometry? alignment;
  final StackFit? stackFit;
  final Clip clipBehavior;

  Widget build({required List<Widget> children}) {
    switch (type) {
      case _QuiHeroGroupLayoutType.flex:
        return Flex(
          direction: direction,
          mainAxisAlignment: mainAxisAlignment,
          mainAxisSize: mainAxisSize,
          crossAxisAlignment: crossAxisAlignment,
          textDirection: textDirection,
          verticalDirection: verticalDirection,
          textBaseline: textBaseline,
          spacing: spacing,
          children: children,
        );
      case _QuiHeroGroupLayoutType.stack:
        return Stack(
          alignment: alignment!,
          textDirection: textDirection,
          fit: stackFit!,
          clipBehavior: clipBehavior,
          children: children,
        );
    }
  }
}
