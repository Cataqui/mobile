import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

final class JobSurfaceEdgeFadeMorphPainter extends CustomPainter {
  JobSurfaceEdgeFadeMorphPainter({
    required this.animation,
    required this.sourceBorderRadius,
    required this.destinationBorderRadius,
    required this.sourceTopColor,
    required this.destinationTopColor,
    required this.sourceTopMainAxisExtent,
    required this.destinationTopMainAxisExtent,
    required this.sourceBottomColor,
    required this.destinationBottomColor,
    required this.sourceBottomMainAxisExtent,
    required this.destinationBottomMainAxisExtent,
    required this.switchThreshold,
  }) : _topGradient = sourceTopColor == destinationTopColor
           ? _gradient(color: sourceTopColor, position: MateoEdgeFadePosition.top)
           : null,
       _bottomGradient = sourceBottomColor == destinationBottomColor
           ? _gradient(color: sourceBottomColor, position: MateoEdgeFadePosition.bottom)
           : null,
       super(repaint: animation);

  final Animation<double> animation;
  final BorderRadius sourceBorderRadius;
  final BorderRadius destinationBorderRadius;
  final Color sourceTopColor;
  final Color destinationTopColor;
  final double sourceTopMainAxisExtent;
  final double destinationTopMainAxisExtent;
  final Color sourceBottomColor;
  final Color destinationBottomColor;
  final double sourceBottomMainAxisExtent;
  final double destinationBottomMainAxisExtent;
  final double switchThreshold;

  static const int _curveSegmentCount = 32;
  static final List<double> _gradientStops = List<double>.unmodifiable([
    for (var index = 0; index <= _curveSegmentCount; index++) index / _curveSegmentCount,
  ]);

  static double _smoothFadeOpacity(double progress) {
    final progressSquared = progress * progress;
    final progressCubed = progressSquared * progress;
    final smootherStep = progressCubed * (progress * (progress * 6 - 15) + 10);
    final midpointDistance = smootherStep - 0.5;
    final interiorStrengthBias = 0.4 * smootherStep * (1 - smootherStep) * midpointDistance * midpointDistance;
    final passingContentVisibility = smootherStep * (0.12 + 0.88 * smootherStep) - interiorStrengthBias;

    return 1 - passingContentVisibility;
  }

  static LinearGradient _gradient({required Color color, required MateoEdgeFadePosition position}) {
    final (begin, end) = switch (position) {
      MateoEdgeFadePosition.top => (Alignment.topCenter, Alignment.bottomCenter),
      MateoEdgeFadePosition.bottom => (Alignment.bottomCenter, Alignment.topCenter),
      MateoEdgeFadePosition.left => (Alignment.centerLeft, Alignment.centerRight),
      MateoEdgeFadePosition.right => (Alignment.centerRight, Alignment.centerLeft),
    };
    return LinearGradient(
      begin: begin,
      end: end,
      stops: _gradientStops,
      colors: <Color>[
        color,
        for (var index = 1; index <= _curveSegmentCount; index++)
          color.withValues(alpha: color.a * _smoothFadeOpacity(index / _curveSegmentCount)),
      ],
    );
  }

  final LinearGradient? _topGradient;
  final LinearGradient? _bottomGradient;
  final Paint _fadePaint = Paint();

  double _fadeProgress(double progress) {
    if (switchThreshold <= 0) return 1;
    return (progress / switchThreshold).clamp(0, 1);
  }

  Color _interpolateColor(Color source, Color destination, double progress) {
    if (source == destination) return source;
    return Color.lerp(source, destination, progress)!;
  }

  void _paintFade({
    required Canvas canvas,
    required Rect bounds,
    required MateoEdgeFadePosition position,
    required double mainAxisExtent,
    required Color color,
    required LinearGradient? retainedGradient,
  }) {
    if (mainAxisExtent <= 0) return;
    final fadeBounds = switch (position) {
      MateoEdgeFadePosition.top => Rect.fromLTWH(bounds.left, bounds.top, bounds.width, mainAxisExtent),
      MateoEdgeFadePosition.bottom => Rect.fromLTWH(
        bounds.left,
        bounds.bottom - mainAxisExtent,
        bounds.width,
        mainAxisExtent,
      ),
      MateoEdgeFadePosition.left => Rect.fromLTWH(bounds.left, bounds.top, mainAxisExtent, bounds.height),
      MateoEdgeFadePosition.right => Rect.fromLTWH(
        bounds.right - mainAxisExtent,
        bounds.top,
        mainAxisExtent,
        bounds.height,
      ),
    };
    final gradient = retainedGradient ?? _gradient(color: color, position: position);
    _fadePaint.shader = gradient.createShader(fadeBounds);
    canvas.drawRect(fadeBounds, _fadePaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final fadeProgress = _fadeProgress(progress);
    final bounds = Offset.zero & size;
    final borderRadius = BorderRadius.lerp(sourceBorderRadius, destinationBorderRadius, progress)!;
    canvas
      ..save()
      ..clipRRect(borderRadius.toRRect(bounds), doAntiAlias: true);
    _paintFade(
      canvas: canvas,
      bounds: bounds,
      position: MateoEdgeFadePosition.top,
      mainAxisExtent: ui.lerpDouble(sourceTopMainAxisExtent, destinationTopMainAxisExtent, fadeProgress)!,
      color: _interpolateColor(sourceTopColor, destinationTopColor, fadeProgress),
      retainedGradient: _topGradient,
    );
    _paintFade(
      canvas: canvas,
      bounds: bounds,
      position: MateoEdgeFadePosition.bottom,
      mainAxisExtent: ui.lerpDouble(sourceBottomMainAxisExtent, destinationBottomMainAxisExtent, fadeProgress)!,
      color: _interpolateColor(sourceBottomColor, destinationBottomColor, fadeProgress),
      retainedGradient: _bottomGradient,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant JobSurfaceEdgeFadeMorphPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.sourceBorderRadius != sourceBorderRadius ||
        oldDelegate.destinationBorderRadius != destinationBorderRadius ||
        oldDelegate.sourceTopColor != sourceTopColor ||
        oldDelegate.destinationTopColor != destinationTopColor ||
        oldDelegate.sourceTopMainAxisExtent != sourceTopMainAxisExtent ||
        oldDelegate.destinationTopMainAxisExtent != destinationTopMainAxisExtent ||
        oldDelegate.sourceBottomColor != sourceBottomColor ||
        oldDelegate.destinationBottomColor != destinationBottomColor ||
        oldDelegate.sourceBottomMainAxisExtent != sourceBottomMainAxisExtent ||
        oldDelegate.destinationBottomMainAxisExtent != destinationBottomMainAxisExtent ||
        oldDelegate.switchThreshold != switchThreshold;
  }
}
