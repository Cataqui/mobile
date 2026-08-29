part of 'create_job_location_view.dart';

class _CreateJobLocationViewInitialBody extends ConsumerStatefulWidget {
  const _CreateJobLocationViewInitialBody({required this.searchTextController});

  final MateoTextController searchTextController;

  @override
  ConsumerState<_CreateJobLocationViewInitialBody> createState() => _CreateJobLocationViewInitialBodyState();
}

class _CreateJobLocationViewInitialBodyState extends ConsumerState<_CreateJobLocationViewInitialBody> {
  final VisibilityController _searchGuidanceVisibilityController = VisibilityController();
  bool? _isSearchGuidanceVisible;

  void _updateSearchGuidanceVisibility() {
    final shouldShow = !widget.searchTextController.hasFocus && widget.searchTextController.text.trim().isEmpty;
    if (_isSearchGuidanceVisible == shouldShow) return;

    _isSearchGuidanceVisible = shouldShow;
    if (shouldShow) {
      _searchGuidanceVisibilityController.show();
      return;
    }

    _searchGuidanceVisibilityController.hide();
  }

  @override
  void initState() {
    super.initState();
    widget.searchTextController.addListener(_updateSearchGuidanceVisibility);
    _updateSearchGuidanceVisibility();
  }

  @override
  void didUpdateWidget(covariant _CreateJobLocationViewInitialBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchTextController == widget.searchTextController) return;

    oldWidget.searchTextController.removeListener(_updateSearchGuidanceVisibility);
    widget.searchTextController.addListener(_updateSearchGuidanceVisibility);
    _isSearchGuidanceVisible = null;
    _updateSearchGuidanceVisibility();
  }

  @override
  void dispose() {
    widget.searchTextController.removeListener(_updateSearchGuidanceVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final curvedArrowColor = switch (Theme.of(context).brightness) {
      Brightness.light => context.mateo.palette.neutral[5],
      Brightness.dark => throw UnsupportedError('CreateJobLocationView does not support dark mode.'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        key: const ValueKey('create_job_location_view_content'),
        children: [
          const SizedBox(height: 20),
          UseCurrentLocationButton(
            key: const ValueKey('create_job_current_location_button'),
            onRequestedToUse: (address) {
              ref
                  .read(createJobStateProvider.notifier)
                  .setLocation(latitude: address.coordinates.latitude, longitude: address.coordinates.longitude);
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ControlledVisibility(
              key: const ValueKey('create_job_location_empty_guidance_visibility'),
              controller: _searchGuidanceVisibilityController,
              hideDuration: const Duration(milliseconds: 60),
              hideTransition: (child, animation) => FadeTransition(opacity: animation, child: child),
              unmount: true,
              child: Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Motion.list(
                        effects: const [
                          MoveMotionEffect(
                            begin: Offset(0, 30),
                            end: Offset.zero,
                            curve: Curves.easeOutCubic,
                            delay: Duration.zero,
                          ),
                          FadeInMotionEffect(curve: Curves.easeOutCubic, delay: Duration(milliseconds: 300)),
                        ],
                        child: Text(
                          i18n.createJob.location.emptyGuidance,
                          key: const ValueKey('create_job_location_empty_guidance'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.mateo.colorScheme.text.tertiary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 42),
                      ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: $Lotties.curvedArrowDraw(
                            key: const ValueKey('create_job_location_curved_arrow'),
                            height: 124,
                            duration: const Duration(milliseconds: 900),
                            playback: LottiePlayback.once,
                            delay: const Duration(milliseconds: 200),
                            overrides: CurvedArrowDrawOverrides(
                              rightArrowheadColor: curvedArrowColor,
                              leftArrowheadColor: curvedArrowColor,
                              continuousMainPathColor: curvedArrowColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
