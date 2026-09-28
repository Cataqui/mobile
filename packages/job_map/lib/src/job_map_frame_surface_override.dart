import 'package:flutter/widgets.dart';
import 'package:job_map/src/job_map_scene.dart';
import 'package:job_map/src/map_frame.dart';

class JobMapFrameSurfaceOverride extends InheritedWidget {
  const JobMapFrameSurfaceOverride({required this.builder, required super.child, super.key});

  final Widget Function(BuildContext context, JobMapScene scene, MapFrame? frame) builder;

  static JobMapFrameSurfaceOverride? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<JobMapFrameSurfaceOverride>();

  @override
  bool updateShouldNotify(JobMapFrameSurfaceOverride oldWidget) => !identical(builder, oldWidget.builder);
}
