import 'dart:math' as math;

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/widgets/feed_job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/qui.dart';

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

  Future<void> _openJobDetails() async {}

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final designColors = context.qui.colors;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _FeedViewBody(
                controller: _feedController,
                cardBorderRadius: _cardBorderRadius,
                feedInCurve: _feedInCurve,
                onOpenJobDetails: _openJobDetails,
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: QuiEdgeFade(
              position: QuiEdgeFadePosition.top,
              color: designColors.background,
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: QuiEdgeFade(
              position: QuiEdgeFadePosition.bottom,
              color: designColors.background,
            ),
          ),
          const Positioned.fill(
            child: RepaintBoundary(
              child: SafeArea(
                child: Stack(
                  children: [
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    //   child: Align(
                    //     alignment: AlignmentGeometry.topStart,
                    //     child: QuiTextButton(
                    //       text: 'São Paulo',
                    //       leadingIconBuilder: (state) => QuiIcons.mapPin.svg(
                    //         colorFilter: ColorFilter.mode(designColors.primary, BlendMode.srcIn),
                    //         height: 14,
                    //         width: 14,
                    //       ),
                    //       leadingIconSpacing: 10,
                    //       trailingIconSpacing: 10,
                    //       trailingIconBuilder: (state) => QuiIcons.chevronDown.svg(
                    //         colorFilter: ColorFilter.mode(state.recommendedIconColor, BlendMode.srcIn),
                    //         height: 8,
                    //       ),
                    //       onPressed: () {},
                    //     ),
                    //   ),
                    // ),
                    // Align(
                    //   alignment: AlignmentGeometry.bottomCenter,
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 28).copyWith(bottom: 5),
                    //     child: QuiSearchBarButton(placeholder: i18n.feed.searchPlaceholder),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
