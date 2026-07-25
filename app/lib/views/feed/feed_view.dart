import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/three_d.g.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'feed_swipe_up_hint_overlay.dart';
part 'feed_view_body.dart';

class FeedView extends ConsumerStatefulWidget {
  const FeedView({super.key});

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> {
  final MateoYSnapListController _feedController = MateoYSnapListController();
  final _cardBorderRadius = BorderRadius.circular(44);
  final _feedInCurve = CurveTween(curve: Curves.easeOutCubic);
  late final ValueNotifier<bool> _isHintActiveNotifier;

  void _showLocationAvailabilitySheet() {
    final i18n = ref.read(translationProvider);
    final colorScheme = context.mateo.colorScheme;

    unawaited(
      MateoBottomSheet.show<void>(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            ExcludeSemantics(child: $ThreeD.comingSoonPlatePortuguese(fit: BoxFit.contain, height: 130)),
            const SizedBox(height: 18),
            Text(
              'Só em São Paulo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.text.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              i18n.feed.locationAvailability.message,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.text.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: MateoButton(
                label: i18n.feed.locationAvailability.closeButtonTitle,
                variant: MateoButtonVariant.primary,
                fit: MateoButtonFit.expand,
                padding: const EdgeInsetsGeometry.symmetric(vertical: 16, horizontal: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final hasSeenHint = ref.read(appStorageStateProvider.select((s) => s.value?.hasSeenSwipeFeedHint));
    _isHintActiveNotifier = ValueNotifier<bool>(!(hasSeenHint ?? false));
  }

  @override
  void dispose() {
    _isHintActiveNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.mateo.colorScheme;
    final i18n = ref.watch(translationProvider);
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
                isHintActiveNotifier: _isHintActiveNotifier,
                onAdjustAreaPressed: _showLocationAvailabilitySheet,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MateoEdgeFade(
              position: MateoEdgeFadePosition.top,
              style: MateoEdgeFadeStyle(color: colorScheme.background),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MateoEdgeFade(
              position: MateoEdgeFadePosition.bottom,
              style: MateoEdgeFadeStyle(color: colorScheme.background),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: SafeArea(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                      child: Align(
                        alignment: AlignmentGeometry.topStart,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: MateoTextButton(
                            text: i18n.feed.locationAvailability.cityLabel,
                            leadingIconBuilder: (state) {
                              return MateoIcon.mapPin(height: 14, width: 14, color: context.mateo.palette.primary[9]);
                            },
                            leadingIconSpacing: 10,
                            trailingIconSpacing: 10,
                            trailingIconBuilder: (state) {
                              return MateoIcon.chevronDown(height: 14, width: 14, color: state.recommendedIconColor);
                            },
                            onPressed: _showLocationAvailabilitySheet,
                          ),
                        ),
                      ),
                    ),
                    // Align(
                    //   alignment: AlignmentGeometry.bottomCenter,
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 28).copyWith(bottom: 5),
                    //     child: const MateoSearchBarButton(placeholder: 'Buscar oportunidades'),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
          if (hasJobs)
            Positioned.fill(
              child: IgnorePointer(
                child: _FeedSwipeUpHintOverlay(
                  feedController: _feedController,
                  isHintActiveNotifier: _isHintActiveNotifier,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
