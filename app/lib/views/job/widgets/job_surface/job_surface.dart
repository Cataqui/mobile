import 'package:cataqui_app/views/job/enums/job_view_morph_tag.dart';
import 'package:cataqui_app/views/job/widgets/job_surface/job_surface_edge_fade.dart';
import 'package:cataqui_app/views/job/widgets/job_surface/job_surface_edge_fade_morph_flight_delegate.dart';
import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class JobSurface extends StatelessWidget {
  const JobSurface({
    required this.jobId,
    required this.decoration,
    required this.child,
    super.key,
    this.width,
    this.padding = EdgeInsets.zero,
    this.edgeFadeStyle,
    this.fadeTop = false,
    this.fadeBottom = false,
  });

  static const Curve morphCurve = Curves.easeOutCubic;

  final String jobId;
  final BoxDecoration decoration;
  final double? width;
  final EdgeInsetsGeometry padding;
  final MateoEdgeFadeStyle? edgeFadeStyle;
  final bool fadeTop;
  final bool fadeBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolvedBorderRadius = decoration.borderRadius?.resolve(Directionality.of(context)) ?? BorderRadius.zero;
    final fadeStyle = edgeFadeStyle ?? MateoEdgeFadeStyle(color: decoration.color);
    final surfaceTag = JobViewMorphTag.surface.valueFor(jobId: jobId);
    final fadeTag = JobViewMorphTag.edgeFade.valueFor(jobId: jobId);
    final edgeFade = JobSurfaceEdgeFade(
      key: ValueKey(fadeTag),
      borderRadius: resolvedBorderRadius,
      absentStyle: fadeStyle,
      topStyle: fadeTop ? fadeStyle : null,
      bottomStyle: fadeBottom ? fadeStyle : null,
    );
    final edgeFadeLayer = Morph(
      tag: fadeTag,
      flightDelegate: const JobSurfaceEdgeFadeMorphFlightDelegate(),
      curve: morphCurve,
      child: edgeFade,
    );

    return Morph(
      tag: surfaceTag,
      curve: morphCurve,
      child: Container(
        key: ValueKey(surfaceTag),
        width: width,
        decoration: decoration,
        child: ClipRRect(
          borderRadius: resolvedBorderRadius,
          child: Stack(
            children: [
              Padding(padding: padding, child: child),
              Positioned.fill(child: edgeFadeLayer),
            ],
          ),
        ),
      ),
    );
  }
}
