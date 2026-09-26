import 'dart:ui' show lerpDouble;

import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/me/widgets/post_status_dot.dart';
import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class MyPostHeaderSurface extends StatelessWidget {
  const MyPostHeaderSurface({
    required this.summary,
    required this.timeAgo,
    required this.payment,
    required this.expansion,
    this.description,
    this.descriptionOpacity = 1,
    super.key,
  });

  static const detailBottomSpacing = 24.0;
  static const detailBodyOverlap = 12.0;
  static const detailRadius = 36.0;

  static String timeAgoFor(UserJobSummaryDto job, Translations i18n) => job.createdAt.timeAgo(
    onNow: () => i18n.feedJob.timeAgo.now,
    onMinutesAgo: (count) => i18n.feedJob.timeAgo.minutes(count: count),
    onHoursAgo: (count) => i18n.feedJob.timeAgo.hours(count: count),
    onDaysAgo: (count) => i18n.feedJob.timeAgo.days(count: count),
    onMonthsAgo: (count) => i18n.feedJob.timeAgo.months(count: count),
    fallback: TimeAgoFallback.finer,
  );

  final UserJobSummaryDto summary;
  final String timeAgo;
  final String payment;
  final double expansion;
  final String? description;
  final double descriptionOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = MateoTheme.of(context);
    final content = Stack(
      children: [
        Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Text(
              timeAgo,
              style: TextStyle(fontSize: 14, fontWeight: .w500, color: theme.colorScheme.text.tertiary, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              summary.title,
              maxLines: 2,
              overflow: .ellipsis,
              style: TextStyle(fontSize: 22, fontWeight: .w600, color: theme.colorScheme.text.primary, height: 1.2),
            ),
            Text(
              payment,
              style: TextStyle(fontSize: 24, fontWeight: .w600, color: theme.colorScheme.text.profit, height: 1.15),
            ),
            if (description != null) ...[
              SizedBox(height: lerpDouble(2 * descriptionOpacity, 0, expansion)),
              Flexible(
                fit: .loose,
                child: ClipRect(
                  child: Align(
                    alignment: .topLeft,
                    heightFactor: descriptionOpacity,
                    child: Opacity(
                      opacity: descriptionOpacity,
                      child: Text(
                        description!,
                        maxLines: 3,
                        overflow: .ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: .w500,
                          color: theme.colorScheme.text.secondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: TickerMode(
            enabled: expansion < 1,
            child: MyPostStatusDot(status: summary.status),
          ),
        ),
      ],
    );
    final radius = lerpDouble(33, detailRadius, expansion)!;
    final cardContent = Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, lerpDouble(24, radius + detailBottomSpacing, expansion)!),
      child: content,
    );
    final card = MateoSurface(
      key: const ValueKey('my_post_header_card'),
      color: theme.colorScheme.background,
      width: const .fill(),
      shape: .rounded(radius: radius),
      elevation: .new(level: 1),
      child: cardContent,
    );
    // The flight's interpolated height can be shorter than a wrapped title.
    // Let the card grow naturally so payment stays below the title.
    if (expansion > 0 && expansion < 1) {
      return OverflowBox(alignment: .topCenter, maxHeight: double.infinity, child: card);
    }
    return card;
  }
}
