part of 'feed_view.dart';

class _FeedSwipeUpHintOverlay extends ConsumerStatefulWidget {
  const _FeedSwipeUpHintOverlay({required this.feedController, required this.isHintActiveNotifier});

  final SnapListController feedController;
  final ValueNotifier<bool> isHintActiveNotifier;

  @override
  ConsumerState<_FeedSwipeUpHintOverlay> createState() => _FeedSwipeUpHintOverlayState();
}

class _FeedSwipeUpHintOverlayState extends ConsumerState<_FeedSwipeUpHintOverlay> {
  final VisibilityController _visibilityController = VisibilityController();

  @override
  void initState() {
    super.initState();

    final hasSeenHint = ref.read(appStorageStateProvider.select((s) => s.value?.hasSeenSwipeFeedHint));
    if (hasSeenHint ?? false) return;

    widget.feedController.addListener(_onFeedNotification);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityController.show();
    });
  }

  @override
  void dispose() {
    widget.feedController.removeListener(_onFeedNotification);
    super.dispose();
  }

  void _onFeedNotification() {
    if ((widget.feedController.position ?? 0) > 0) {
      widget.isHintActiveNotifier.value = false;

      _visibilityController.hide();
      widget.feedController.removeListener(_onFeedNotification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSeenHint = ref.watch(appStorageStateProvider.select((s) => s.value?.hasSeenSwipeFeedHint));
    if (hasSeenHint ?? false) return const SizedBox.shrink();

    final colorScheme = MateoTheme.of(context).colorScheme;
    final i18n = ref.watch(translationProvider);

    return ControlledVisibility(
      controller: _visibilityController,
      showDuration: const Duration(milliseconds: 600),
      hideDuration: const Duration(milliseconds: 400),
      showTransition: (child, animation) => FadeTransition(opacity: animation, child: child),
      hideTransition: (child, animation) => FadeTransition(opacity: animation, child: child),
      unmount: true,
      onShow: (transition) async {
        await transition;
        if (mounted) widget.isHintActiveNotifier.value = false;
      },
      onHide: (transition) async {
        await transition;
        if (!mounted) return;

        unawaited(ref.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true));
      },
      child: ColoredBox(
        color: colorScheme.sheet.scrim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: $Lotties.swipeUpPhoneAnimation(
                    height: 120,
                    overrides: SwipeUpPhoneAnimationOverrides(
                      phoneColor: MateoTheme.of(context).palette.neutral[11],
                      upArrowColor: MateoTheme.of(context).palette.accent[1],
                      pointerHandColor: MateoTheme.of(context).palette.accent[1],
                    ),
                    progress: MediaQuery.disableAnimationsOf(context) ? .3 : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FractionallySizedBox(
                widthFactor: .6,
                child: Text(
                  i18n.feed.swipeUpHint.caption,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MateoTheme.of(context).palette.neutral[1],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
