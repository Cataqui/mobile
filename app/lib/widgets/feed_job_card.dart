import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qui/qui.dart';

class FeedJobCard extends ConsumerWidget {
  const FeedJobCard({required this.feedJob, required this.onTap, super.key});

  final FeedJobDto feedJob;
  final AsyncCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.qui.colors;
    final i18n = ref.watch(translationProvider);
    final now = clock.now();

    return QuiTapAnimation(
      animation: QuiTapAnimationType.scale,
      onPressed: (animation) async {
        await animation;
        await onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(38)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedJob.formatCreatedAtAgo(i18n, now: now),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.placeholder),
                ),

                const SizedBox(height: 6),
                Text(
                  feedJob.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22, height: 1.15),
                ),
                const SizedBox(height: 4),
                Text(
                  feedJob.payment.formatPayment(i18n),
                  style: TextStyle(fontSize: 25, color: colors.money, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  feedJob.descriptionSummary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: colors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
