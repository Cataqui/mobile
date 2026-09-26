import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_detail_content.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_flight_delegate.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_surface.dart';
import 'package:cataqui_app/views/me/my_post/my_post_morph_target.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class MyPostView extends ConsumerWidget {
  const MyPostView({required this.summary, super.key});

  final UserJobSummaryDto summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = MateoTheme.of(context);
    final i18n = ref.watch(translationProvider);
    final detailState = ref.watch(myPostStateProvider(summary.jobId));
    final detail = detailState.asData?.value;
    final displayedSummary = detail == null ? summary : summary.copyWith(status: detail.status);
    final routeAnimation = ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation<double>(1);

    final detailContent = Transform.translate(
      offset: const Offset(0, -MyPostHeaderSurface.detailBodyOverlap),
      child: MyPostDetailContent(
        jobId: summary.jobId,
        routeAnimation: routeAnimation,
        chipsWidth: MediaQuery.sizeOf(context).width,
      ),
    );
    return FadeTransition(
      opacity: MediaQuery.disableAnimationsOf(context) ? const AlwaysStoppedAnimation<double>(1) : routeAnimation,
      child: MateoView(
        key: const ValueKey('my_post_view'),
        avoidBottomInset: false,
        header: MateoViewHeader(
          trailing: MateoButton(
            key: const ValueKey('my_post_close_button'),
            presentation: const .icon(icon: MateoIcon(.cross)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        surface: .scrollable(
          color: theme.colorScheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 32),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Morph(
                targets: [ref.watch(myPostMorphTargetProvider(summary.jobId))],
                flightConfig: const .custom(MyPostHeaderFlightDelegate()),
                child: MyPostHeaderSurface(
                  summary: displayedSummary,
                  timeAgo: MyPostHeaderSurface.timeAgoFor(summary, i18n),
                  payment: summary.payment ?? i18n.jobPayment.paymentFlexible,
                  expansion: 1,
                ),
              ),
              if (detailState.hasError) Expanded(child: detailContent) else detailContent,
            ],
          ),
        ),
      ),
    );
  }
}
