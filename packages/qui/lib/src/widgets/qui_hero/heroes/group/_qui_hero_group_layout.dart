part of 'qui_hero_group.dart';

class QuiHeroGroupLayout {
  const QuiHeroGroupLayout.flex({
    required this.direction,
    required this.mainAxisAlignment,
    required this.mainAxisSize,
    required this.crossAxisAlignment,
    required this.textDirection,
    required this.verticalDirection,
    required this.textBaseline,
    required this.spacing,
  }) : type = QuiHeroGroupLayoutType.flex,
       alignment = null,
       stackFit = null,
       clipBehavior = Clip.none;

  const QuiHeroGroupLayout.stack({
    required this.alignment,
    required this.textDirection,
    required this.stackFit,
    required this.clipBehavior,
  }) : type = QuiHeroGroupLayoutType.stack,
       direction = Axis.vertical,
       mainAxisAlignment = MainAxisAlignment.start,
       mainAxisSize = MainAxisSize.max,
       crossAxisAlignment = CrossAxisAlignment.center,
       verticalDirection = VerticalDirection.down,
       textBaseline = null,
       spacing = 0;

  factory QuiHeroGroupLayout.fromContext(BuildContext context) {
    QuiHeroGroupLayout? result;

    context.visitAncestorElements((element) {
      final widget = element.widget;

      if (widget is Flex) {
        result = QuiHeroGroupLayout.flex(
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
        result = QuiHeroGroupLayout.stack(
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
        const QuiHeroGroupLayout.flex(
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

  final QuiHeroGroupLayoutType type;
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

  bool get shouldReserveBoundedWidth {
    switch (type) {
      case QuiHeroGroupLayoutType.flex:
        return direction == Axis.vertical;
      case QuiHeroGroupLayoutType.stack:
        return true;
    }
  }

  Widget build({required List<Widget> children}) {
    switch (type) {
      case QuiHeroGroupLayoutType.flex:
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
      case QuiHeroGroupLayoutType.stack:
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
