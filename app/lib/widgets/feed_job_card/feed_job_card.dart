import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qui/qui.dart';

class FeedJobCard extends ConsumerWidget {
  const FeedJobCard({required this.feedJob, super.key});

  final FeedJobDto feedJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.qui.colors;
    final i18n = ref.watch(translationProvider);
    final now = clock.now();

    return QuiTapAnimation(
      animation: QuiTapAnimationType.scale,
      fireHapticFeedback: false,
      onPressed: (animation) async => unawaited(JobRoute(jobId: feedJob.jobId, $extra: feedJob).push(context)),
      child: QuiHeroBackground(
        tag: 'job-${feedJob.jobId}-surface',
        width: double.infinity,
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(38)),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            QuiHeroGroup(
              tag: 'job-${feedJob.jobId}-header',
              heroes: [
                QuiHeroText(
                  feedJob.formatCreatedAtAgo(i18n, now: now),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.placeholder),
                  padding: const EdgeInsets.only(bottom: 6),
                ),
                QuiHeroText(
                  feedJob.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  onStart: HapticFeedback.successNotification,
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 22),
                ),
                QuiHeroText(
                  feedJob.payment.formatPayment(i18n),
                  style: TextStyle(fontSize: 25, color: colors.money, fontWeight: FontWeight.w600),
                ),
                QuiHeroText(
                  feedJob.descriptionSummary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  switchThreshold: 0.8,
                  padding: const EdgeInsets.only(top: 4),
                  style: TextStyle(fontSize: 16, color: colors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
