import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

final class JobSurfaceEdgeFade extends StatelessWidget {
  const JobSurfaceEdgeFade({
    required this.borderRadius,
    required this.absentStyle,
    super.key,
    this.topStyle,
    this.bottomStyle,
  });

  final BorderRadiusGeometry borderRadius;
  final MateoEdgeFadeStyle absentStyle;
  final MateoEdgeFadeStyle? topStyle;
  final MateoEdgeFadeStyle? bottomStyle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVisible(topStyle))
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MateoEdgeFade(position: MateoEdgeFadePosition.top, style: topStyle!),
              ),
            if (_isVisible(bottomStyle))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MateoEdgeFade(position: MateoEdgeFadePosition.bottom, style: bottomStyle!),
              ),
          ],
        ),
      ),
    );
  }

  bool _isVisible(MateoEdgeFadeStyle? style) {
    if (style == null) return false;

    final mainAxisExtent = style.mainAxisExtent;
    return mainAxisExtent == null || mainAxisExtent > 0;
  }
}
