part of 'job_location_image.dart';

class _JobLocationImageFeedback extends ConsumerStatefulWidget {
  const _JobLocationImageFeedback({required this.state, required this.color, required this.onRetry, super.key});

  final JobLocationImageFeedbackState state;
  final Color color;
  final VoidCallback onRetry;

  @override
  ConsumerState<_JobLocationImageFeedback> createState() => _JobLocationImageFeedbackState();
}

class _JobLocationImageFeedbackState extends ConsumerState<_JobLocationImageFeedback> {
  static const _buttonSize = MateoButtonSize.standard;

  Timer? _loadingTimer;
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();
    _showLoading = widget.state == .error;
    if (!_showLoading) {
      _loadingTimer = Timer(const Duration(seconds: 1), () => setState(() => _showLoading = true));
    }
  }

  @override
  void didUpdateWidget(covariant _JobLocationImageFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == .error) {
      _loadingTimer?.cancel();
      _showLoading = true;
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider).jobLocationImage;
    return Align(
      alignment: .bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SizedBox.square(
          dimension: _buttonSize.height,
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 280),
            switchInCurve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
            switchOutCurve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: Tween<double>(begin: 0.8, end: 1).animate(animation), child: child),
            ),
            child: switch (widget.state) {
              .error => MateoButton(
                key: const ValueKey(JobLocationImageFeedbackState.error),
                presentation: .icon(
                  icon: const MateoIcon(.arrowRotateClockwise),
                  variant: .tertiary,
                  size: _buttonSize,
                  semanticLabel: i18n.retry,
                ),
                onPressed: widget.onRetry,
              ),
              .loading =>
                _showLoading
                    ? Center(
                        key: const ValueKey(JobLocationImageFeedbackState.loading),
                        child: Semantics(
                          label: i18n.loading,
                          liveRegion: true,
                          child: ExcludeSemantics(
                            child: RepaintBoundary(
                              child: Motion(
                                effect: const MoveMotionEffect(
                                  begin: Offset.zero,
                                  end: Offset(0, -12),
                                  duration: Duration(milliseconds: 800),
                                  curve: _JobLocationImageLoadingBounceCurve(),
                                  playback: .loop,
                                ),
                                child: SizedBox.square(
                                  dimension: 18,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(shape: .circle, color: widget.color),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('waiting')),
            },
          ),
        ),
      ),
    );
  }
}
