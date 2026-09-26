import 'dart:ui' show lerpDouble;

import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_surface.dart';
import 'package:flutter/material.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class MyPostHeaderFlightDelegate extends MorphFlightDelegate<MyPostHeaderFlightProperties> {
  const MyPostHeaderFlightDelegate();

  @override
  MyPostHeaderFlightProperties properties(MorphEndpointContext endpoint) {
    final header = endpoint.child as MyPostHeaderSurface;
    return MyPostHeaderFlightProperties(
      summary: header.summary,
      timeAgo: header.timeAgo,
      payment: header.payment,
      expansion: header.expansion,
      description: header.description,
      descriptionOpacity: header.description == null ? 0 : 1,
    );
  }

  @override
  MyPostHeaderFlightProperties lerpProperties(
    MyPostHeaderFlightProperties source,
    MyPostHeaderFlightProperties destination,
    MorphFlightProgress progress,
  ) {
    final fraction = progress.uncurvedProgress.clamp(0.0, 1.0);
    final descriptionOpacity = source.description == null
        ? Curves.easeOutCubic.transform(((fraction - .3) / .35).clamp(0.0, 1.0))
        : 1 - Curves.easeOutCubic.transform((fraction / .45).clamp(0.0, 1.0));
    return MyPostHeaderFlightProperties(
      summary: source.summary,
      timeAgo: source.timeAgo,
      payment: source.payment,
      expansion: lerpDouble(source.expansion, destination.expansion, progress.curvedProgress)!,
      description: source.description ?? destination.description,
      descriptionOpacity: descriptionOpacity,
    );
  }

  @override
  Widget buildFlight(BuildContext context, MorphFlight<MyPostHeaderFlightProperties> flight) {
    return AnimatedBuilder(
      animation: flight.uncurvedAnimation,
      builder: (context, _) {
        final properties = flight.properties;
        return MyPostHeaderSurface(
          summary: properties.summary,
          timeAgo: properties.timeAgo,
          payment: properties.payment,
          expansion: properties.expansion,
          description: properties.description,
          descriptionOpacity: properties.descriptionOpacity,
        );
      },
    );
  }
}

class MyPostHeaderFlightProperties {
  const MyPostHeaderFlightProperties({
    required this.summary,
    required this.timeAgo,
    required this.payment,
    required this.expansion,
    required this.description,
    required this.descriptionOpacity,
  });

  final UserJobSummaryDto summary;
  final String timeAgo;
  final String payment;
  final double expansion;
  final String? description;
  final double descriptionOpacity;
}
