import 'package:cataqui_app/views/job/widgets/job_surface/job_surface_edge_fade.dart';
import 'package:cataqui_app/views/job/widgets/job_surface/job_surface_edge_fade_morph_flight_delegate_types.dart';
import 'package:cataqui_app/views/job/widgets/job_surface/job_surface_edge_fade_morph_painter.dart';
import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

final class JobSurfaceEdgeFadeMorphFlightDelegate extends MorphFlightDelegate<JobSurfaceEdgeFadeMorphProperties> {
  const JobSurfaceEdgeFadeMorphFlightDelegate({this.switchThreshold = 1})
    : assert(switchThreshold >= 0 && switchThreshold <= 1, 'switchThreshold must be between 0 and 1.');

  final double switchThreshold;

  @override
  JobSurfaceEdgeFadeMorphProperties properties(MorphEndpointContext endpoint) {
    final child = endpoint.child;
    if (child is! JobSurfaceEdgeFade) {
      throw ArgumentError.value(child, 'endpoint.child', 'A JobSurfaceEdgeFade is required.');
    }

    final resolvedAbsentStyle = child.absentStyle.resolve(endpoint.context, position: MateoEdgeFadePosition.top);
    final zeroExtentStyle = resolvedAbsentStyle.copyWith(mainAxisExtent: 0);
    final handoff = MateoSwipeToPopSurface.maybeHandoffStateOf(endpoint.context);
    final borderRadius = (handoff?.borderRadius ?? child.borderRadius).resolve(Directionality.of(endpoint.context));

    return (
      borderRadius: borderRadius,
      topStyle: child.topStyle?.resolve(endpoint.context, position: MateoEdgeFadePosition.top) ?? zeroExtentStyle,
      bottomStyle:
          child.bottomStyle?.resolve(endpoint.context, position: MateoEdgeFadePosition.bottom) ?? zeroExtentStyle,
      switchThreshold: switchThreshold,
    );
  }

  @override
  JobSurfaceEdgeFadeMorphProperties lerp(
    JobSurfaceEdgeFadeMorphProperties source,
    JobSurfaceEdgeFadeMorphProperties destination,
    double progress,
  ) {
    final fadeProgress = source.switchThreshold <= 0 ? 1.0 : (progress / source.switchThreshold).clamp(0.0, 1.0);

    return (
      borderRadius: BorderRadius.lerp(source.borderRadius, destination.borderRadius, progress)!,
      topStyle: MateoEdgeFadeStyle.lerp(source.topStyle, destination.topStyle, fadeProgress)!,
      bottomStyle: MateoEdgeFadeStyle.lerp(source.bottomStyle, destination.bottomStyle, fadeProgress)!,
      switchThreshold: source.switchThreshold,
    );
  }

  @override
  Widget buildFlight(BuildContext context, MorphFlight<JobSurfaceEdgeFadeMorphProperties> flight) {
    final source = flight.source.properties;
    final destination = flight.destination.properties;
    return CustomPaint(
      painter: JobSurfaceEdgeFadeMorphPainter(
        animation: flight.animation,
        sourceBorderRadius: source.borderRadius,
        destinationBorderRadius: destination.borderRadius,
        sourceTopColor: source.topStyle.color!,
        destinationTopColor: destination.topStyle.color!,
        sourceTopMainAxisExtent: source.topStyle.mainAxisExtent!,
        destinationTopMainAxisExtent: destination.topStyle.mainAxisExtent!,
        sourceBottomColor: source.bottomStyle.color!,
        destinationBottomColor: destination.bottomStyle.color!,
        sourceBottomMainAxisExtent: source.bottomStyle.mainAxisExtent!,
        destinationBottomMainAxisExtent: destination.bottomStyle.mainAxisExtent!,
        switchThreshold: source.switchThreshold,
      ),
    );
  }
}
