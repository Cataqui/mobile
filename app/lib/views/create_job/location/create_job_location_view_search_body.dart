part of 'create_job_location_view.dart';

class _CreateJobLocationViewSearchBody extends ConsumerWidget {
  const _CreateJobLocationViewSearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    ref.listen<bool>(createJobLocationStateProvider.select((locationData) => locationData.addressSearch.isLoading), (
      wasLoading,
      isLoading,
    ) {
      if ((wasLoading ?? true) || !isLoading) return;

      final scrollPosition = Scrollable.maybeOf(context)?.position;
      if (scrollPosition == null || !scrollPosition.hasPixels) return;

      scrollPosition.animateTo(
        scrollPosition.minScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
    final addressSearch = ref.watch(
      createJobLocationStateProvider.select((locationData) => locationData.addressSearch),
    );

    return Padding(
      key: const ValueKey('create_job_location_search_content'),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 70),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        reverseDuration: const Duration(milliseconds: 30),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (currentChild, previousChildren) {
          if (previousChildren.isNotEmpty) return previousChildren.last;
          return currentChild ?? const SizedBox.shrink();
        },
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: addressSearch.when(
          data: (response) {
            if (response == null || response.suggestions.isEmpty) {
              return _buildEmptySearchMessage(context, message: i18n.createJob.location.search.empty);
            }

            return Column(
              key: const ValueKey('create_job_location_search_suggestions'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final suggestion in response.suggestions)
                  MateoTap(
                    animation: MateoTapAnimationType.scale,
                    onPressed: (_) async => ref
                        .read(createJobLocationStateProvider.notifier)
                        .selectAddress(addressId: suggestion.addressId),
                    child: _buildSuggestionRow(
                      context,
                      key: ValueKey('create_job_location_suggestion_${suggestion.addressId}'),
                      iconBackgroundColor: suggestion.category.color(palette: context.mateo.palette),
                      icon: suggestion.category.icon(size: 20, color: context.mateo.palette.neutral[1]),
                      primaryText: suggestion.primaryText,
                      secondaryText: suggestion.secondaryText,
                    ),
                  ),
              ],
            );
          },
          error: (error, _) {
            if (error.isOfflineConnectionDioException) {
              return _buildOfflineSearchMessage(context, message: i18n.createJob.location.search.offlineError);
            }

            return _buildErrorSearchMessage(context, message: i18n.createJob.location.search.error);
          },
          loading: () => Skeleton(
            key: const ValueKey('create_job_location_search_skeleton'),
            semanticsLabel: i18n.createJob.location.search.loadingSemanticLabel,
            style: SkeletonStyle(
              color: context.mateo.colorScheme.skeleton.bone,
              effect: const SkeletonFadeEffect(),
              radius: const Radius.circular(999),
            ),
            child: Column(
              children: [
                for (var index = 0; index < 4; ++index)
                  _buildSuggestionRow(
                    context,
                    key: ValueKey('create_job_location_search_skeleton_row_$index'),
                    iconBackgroundColor: context.mateo.palette.neutral[12],
                    icon: MateoIcon.mapPin(width: 22, height: 22, color: context.mateo.palette.neutral[1]),
                    primaryText: index.isEven ? 'Avenida Paulista' : 'Parque Ibirapuera',
                    secondaryText: index.isEven ? 'Bela Vista, São Paulo' : 'Vila Mariana, São Paulo',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionRow(
    BuildContext context, {
    required Key key,
    required Color iconBackgroundColor,
    required Widget icon,
    required String primaryText,
    required String? secondaryText,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: iconBackgroundColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  primaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.mateo.colorScheme.text.primary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (secondaryText != null)
                  Text(
                    secondaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.mateo.colorScheme.text.tertiary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSearchMessage(BuildContext context, {required String message}) {
    final animationColor = switch (Theme.brightnessOf(context)) {
      Brightness.light => context.mateo.palette.neutral[7],
      Brightness.dark => throw UnimplementedError('Dark mode not implemented'),
    };

    return Center(
      key: const ValueKey('create_job_location_search_error_transition'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: $Lotties.doubleCross(
                key: const ValueKey('create_job_location_search_error_animation'),
                width: 56,
                height: 56,
                delay: const Duration(milliseconds: 230),
                duration: const Duration(milliseconds: 1100),
                playback: LottiePlayback.once,
                overrides: DoubleCrossOverrides(
                  leftCrossTopDownSlashColor: animationColor,
                  leftCrossBottomUpSlashColor: animationColor,
                  rightCrossTopDownSlashColor: animationColor,
                  rightCrossBottomUpSlashColor: animationColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildSearchMessageText(context, message: message),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchMessage(BuildContext context, {required String message}) {
    return Center(
      key: const ValueKey('create_job_location_search_empty_transition'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: MateoIcon.magnifyingGlassSadFace(
                key: const ValueKey('create_job_location_search_empty_icon'),
                width: 46,
                height: 46,
                color: switch (Theme.brightnessOf(context)) {
                  Brightness.light => context.mateo.palette.neutral[7],
                  Brightness.dark => throw UnsupportedError('CreateJobLocationView does not support dark mode.'),
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchMessageText(context, message: message),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineSearchMessage(BuildContext context, {required String message}) {
    final animationColor = switch (Theme.brightnessOf(context)) {
      Brightness.light => context.mateo.palette.neutral[7],
      Brightness.dark => throw UnimplementedError('Dark mode not implemented'),
    };

    return Center(
      key: const ValueKey('create_job_location_search_offline_error_transition'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: $Lotties.wifiSignalPop(
                key: const ValueKey('create_job_location_search_offline_animation'),
                width: 56,
                height: 56,
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 1100),
                playback: LottiePlayback.once,
                overrides: WifiSignalPopOverrides(
                  topSignalArcColor: animationColor,
                  middleSignalArcColor: animationColor,
                  bottomSignalMarkColor: animationColor,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildSearchMessageText(context, message: message),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchMessageText(BuildContext context, {required String message}) {
    return Motion.list(
      effects: const [
        MoveMotionEffect(
          curve: Curves.easeOutCubic,
          duration: Duration(milliseconds: 400),
          begin: Offset(0, -12),
          end: Offset.zero,
        ),
        FadeInMotionEffect(curve: Curves.easeOutCubic, duration: Duration(milliseconds: 400)),
      ],
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.mateo.colorScheme.text.tertiary, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
