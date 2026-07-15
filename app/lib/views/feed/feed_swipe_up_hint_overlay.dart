part of 'feed_view.dart';

class _FeedSwipeUpHintOverlay extends ConsumerStatefulWidget {
  const _FeedSwipeUpHintOverlay({required this.feedController, required this.isHintActiveNotifier});

  final QuiTikTokFeedController feedController;
  final ValueNotifier<bool> isHintActiveNotifier;

  @override
  ConsumerState<_FeedSwipeUpHintOverlay> createState() => _FeedSwipeUpHintOverlayState();
}

class _FeedSwipeUpHintOverlayState extends ConsumerState<_FeedSwipeUpHintOverlay> {
  final QuiAppearController _appearController = QuiAppearController();

  @override
  void initState() {
    super.initState();

    final hasSeenHint = ref.read(appStorageStateProvider.select((s) => s.value?.hasSeenSwipeFeedHint));
    if (hasSeenHint ?? false) return;

    widget.feedController.addNotificationListener(_onFeedNotification);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appearController.appear();
    });
  }

  @override
  void dispose() {
    widget.feedController.removeNotificationListener(_onFeedNotification);
    super.dispose();
  }

  void _onFeedNotification(QuiTikTokFeedNotification notification) {
    if (notification == QuiTikTokFeedNotification.nextItem) {
      widget.isHintActiveNotifier.value = false;

      _appearController.destroy();
      widget.feedController.removeNotificationListener(_onFeedNotification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSeenHint = ref.watch(appStorageStateProvider.select((s) => s.value?.hasSeenSwipeFeedHint));
    if (hasSeenHint ?? false) return const SizedBox.shrink();

    final colorScheme = context.qui.colorScheme;
    final i18n = ref.watch(translationProvider);

    return QuiAppear(
      controller: _appearController,
      destroyDuration: const Duration(milliseconds: 400),
      appearDuration: const Duration(milliseconds: 600),
      unmount: true,
      onAppear: (animation) async {
        await animation;
        if (mounted) widget.isHintActiveNotifier.value = false;
      },
      onDestroy: (animation) async {
        await animation;
        unawaited(ref.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true));
      },
      child: ColoredBox(
        color: colorScheme.overlay.scrim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: QuiSwipeUpHint(
                    height: 120,
                    accentColor: context.qui.palette.primary[1],
                    phoneColor: context.qui.palette.neutral[11],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FractionallySizedBox(
                widthFactor: .6,
                child: Text(
                  i18n.feed.swipeUpHint.caption,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.qui.palette.neutral[1]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
