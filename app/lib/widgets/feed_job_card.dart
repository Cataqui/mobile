import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
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

    return QuiTapAnimation(
      animation: QuiTapAnimationType.scale,
      onPressed: (animation) async {
        await animation;
        await onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(38)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feedJob.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22, height: 1.15)),
            const SizedBox(height: 4),
            Text(
              feedJob.payment.formatPayment(i18n),
              style: TextStyle(fontSize: 25, color: colors.money, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              feedJob.descriptionSummary,
              style: TextStyle(fontSize: 15.7, color: colors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
