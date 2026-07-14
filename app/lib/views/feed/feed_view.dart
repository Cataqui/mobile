import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/qui.dart';

part 'feed_swipe_up_hint_overlay.dart';
part 'feed_view_body.dart';

class FeedView extends ConsumerStatefulWidget {
  const FeedView({super.key});

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> {
  final QuiTikTokFeedController _feedController = QuiTikTokFeedController();
  final _cardBorderRadius = BorderRadius.circular(44);
  final _feedInCurve = CurveTween(curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.qui.colorScheme;
    final hasJobs = ref.watch(feedStateProvider.select((s) => s.value?.jobs.isNotEmpty ?? false));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _FeedViewBody(
                controller: _feedController,
                cardBorderRadius: _cardBorderRadius,
                feedInCurve: _feedInCurve,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: QuiEdgeFade(
              position: QuiEdgeFadePosition.top,
              style: QuiEdgeFadeStyle(color: colorScheme.background),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: QuiEdgeFade(
              position: QuiEdgeFadePosition.bottom,
              style: QuiEdgeFadeStyle(color: colorScheme.background),
            ),
          ),
          if (hasJobs)
            Positioned.fill(
              child: IgnorePointer(child: _FeedSwipeUpHintOverlay(feedController: _feedController)),
            ),
        ],
      ),
    );
  }
}
