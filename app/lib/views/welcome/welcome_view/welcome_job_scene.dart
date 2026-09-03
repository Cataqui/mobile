part of 'welcome_view.dart';

class _WelcomeJobScene extends StatefulWidget {
  const _WelcomeJobScene({
    required this.jobs,
    required this.accessibilityLabel,
    required this.floatingStartDelay,
    required this.initialRevealDelay,
    super.key,
  }) : assert(jobs.length > 1, 'The welcome scene requires at least two jobs.');

  static const sceneSize = Size(_WelcomeJobCard.width + _cardHorizontalInset * 2, _referenceCanvasHeight - _topTrim);

  static Future<void> precacheArtwork(BuildContext context, {required _WelcomeJobArtwork artwork}) async {
    for (final slot in WelcomeArtworkSlot.values) {
      if (!context.mounted) return;
      final illustration = _illustrationFor(slot: slot, artwork: artwork);
      await illustration.precache(context, width: illustration.width, height: illustration.height);
    }
  }

  static const _jobChangeInterval = Duration(seconds: 3);
  static const _returnDuration = Duration(milliseconds: 350);
  static const _revealDuration = Duration(milliseconds: 600);
  static final _idleDuration = _jobChangeInterval - _revealDuration - _returnDuration;
  static const _referenceCanvasHeight = 396.0;
  static const _topTrim = 24.0;
  static const _artworkSurfaceSize = 60.0;
  static const _cardHorizontalInset = 28.0;
  static const _cardLeft = _cardHorizontalInset;
  static const _cardTop = 113.0 - _topTrim;
  static const _artworkOrigin = Offset(_cardLeft + _WelcomeJobCard.width / 2, _cardTop + 90);

  static _WelcomeJobIllustration _illustrationFor({
    required WelcomeArtworkSlot slot,
    required _WelcomeJobArtwork artwork,
  }) {
    return switch (slot) {
      WelcomeArtworkSlot.top => artwork.top,
      WelcomeArtworkSlot.rightTopCorner => artwork.right,
      WelcomeArtworkSlot.leftBottomCorner => artwork.left,
      WelcomeArtworkSlot.bottom => artwork.bottom,
      WelcomeArtworkSlot.rightBottomCorner => artwork.corner,
    };
  }

  final List<_WelcomeJob> jobs;
  final String accessibilityLabel;
  final Duration floatingStartDelay;
  final Duration initialRevealDelay;

  @override
  State<_WelcomeJobScene> createState() => _WelcomeJobSceneState();
}

class _WelcomeJobSceneState extends State<_WelcomeJobScene> with SingleTickerProviderStateMixin {
  final MotionController _transitionController = MotionController();
  final MotionController _floatingController = MotionController();
  late final AnimationController _artworkColorController;
  late final List<FloatingMotionEffect> _artworkFloatingEffects;
  late final FloatingMotionEffect _cardFloatingEffect;
  late final List<List<MotionEffect>> _artworkRevealEffects;
  late final List<List<MotionEffect>> _artworkReturnEffects;
  late final ScaleInMotionEffect _initialCardRevealEffect;
  late final ScaleInMotionEffect _cardRevealEffect;
  late final ScaleOutMotionEffect _cardReturnEffect;
  Timer? _initialFloatingTimer;
  Timer? _initialRevealTimer;
  Timer? _nextJobTimer;
  WelcomeScenePhase _phase = WelcomeScenePhase.initial;
  int _currentJobIndex = 0;
  int _previousJobIndex = 0;
  bool _animationsDisabled = false;
  bool _floatingStarted = false;
  bool _hasRotatedJobs = false;

  bool get _isReturning => _phase == WelcomeScenePhase.returning;

  Offset _artworkOriginOffset(WelcomeArtworkSlot slot) {
    final left = slot.resolveLeft(
      sceneWidth: _WelcomeJobScene.sceneSize.width,
      surfaceSize: _WelcomeJobScene._artworkSurfaceSize,
    );
    final top = slot.resolveTop(
      sceneHeight: _WelcomeJobScene.sceneSize.height,
      surfaceSize: _WelcomeJobScene._artworkSurfaceSize,
      topTrim: _WelcomeJobScene._topTrim,
    );
    return _WelcomeJobScene._artworkOrigin -
        Offset(left + _WelcomeJobScene._artworkSurfaceSize / 2, top + _WelcomeJobScene._artworkSurfaceSize / 2);
  }

  void _scheduleInitialFloating() {
    if (_floatingStarted || _animationsDisabled || _initialFloatingTimer != null) return;
    _initialFloatingTimer = Timer(widget.floatingStartDelay, _startFloating);
  }

  void _startFloating() {
    _initialFloatingTimer = null;
    if (!mounted || _floatingStarted || _animationsDisabled) return;
    _floatingStarted = true;
    _floatingController.play();
  }

  void _scheduleInitialReveal() {
    if (_phase != WelcomeScenePhase.initial) return;
    if (_animationsDisabled) {
      _initialRevealTimer?.cancel();
      _initialRevealTimer = null;
      _phase = WelcomeScenePhase.idle;
      _transitionController.play();
      _precacheNextJob();
      _scheduleNextJobTransition();
      return;
    }
    if (_initialRevealTimer != null) return;

    _initialRevealTimer = Timer(widget.initialRevealDelay, _startInitialReveal);
  }

  void _startInitialReveal() {
    _initialRevealTimer = null;
    if (!mounted || _phase != WelcomeScenePhase.initial) return;

    setState(() => _phase = WelcomeScenePhase.revealing);
    _transitionController.play();
  }

  void _scheduleNextJobTransition({Duration? delay}) {
    _nextJobTimer?.cancel();
    _nextJobTimer = Timer(
      delay ?? (_animationsDisabled ? _WelcomeJobScene._jobChangeInterval : _WelcomeJobScene._idleDuration),
      _startJobTransition,
    );
  }

  void _startJobTransition() {
    _nextJobTimer = null;
    if (!mounted) return;
    if (_animationsDisabled) {
      setState(() {
        _previousJobIndex = _currentJobIndex;
        _currentJobIndex = (_currentJobIndex + 1) % widget.jobs.length;
        _hasRotatedJobs = true;
        _phase = WelcomeScenePhase.idle;
      });
      _artworkColorController.value = 1;
      _precacheNextJob();
      _scheduleNextJobTransition();
      return;
    }
    if (_phase != WelcomeScenePhase.idle) return;

    setState(() => _phase = WelcomeScenePhase.returning);
    _transitionController.play();
  }

  void _precacheNextJob() {
    unawaited(
      _WelcomeJobScene.precacheArtwork(
        context,
        artwork: widget.jobs[(_currentJobIndex + 1) % widget.jobs.length].artwork,
      ),
    );
  }

  void _finishTransition() {
    if (!mounted) return;

    switch (_phase) {
      case WelcomeScenePhase.initial:
      case WelcomeScenePhase.idle:
        return;
      case WelcomeScenePhase.revealing:
        _phase = WelcomeScenePhase.idle;
        _precacheNextJob();
        _scheduleNextJobTransition();
        return;
      case WelcomeScenePhase.returning:
        setState(() {
          _previousJobIndex = _currentJobIndex;
          _currentJobIndex = (_currentJobIndex + 1) % widget.jobs.length;
          _hasRotatedJobs = true;
          _phase = WelcomeScenePhase.revealing;
        });
        _artworkColorController.forward(from: 0);
        _transitionController.play();
        return;
    }
  }

  @override
  void initState() {
    super.initState();
    _artworkColorController = AnimationController(duration: _WelcomeJobScene._revealDuration, value: 1, vsync: this);
    _artworkFloatingEffects = [
      for (final slot in WelcomeArtworkSlot.values)
        FloatingMotionEffect(
          distance: slot.floatingDistance,
          delay: slot.floatingDelay,
          duration: slot.floatingDuration,
        ),
    ];
    _cardFloatingEffect = const FloatingMotionEffect(
      distance: 4,
      delay: Duration(milliseconds: 180),
      duration: Duration(milliseconds: 2800),
    );
    _artworkRevealEffects = [
      for (final slot in WelcomeArtworkSlot.values)
        [
          const ScaleInMotionEffect(
            scale: 0.65,
            duration: _WelcomeJobScene._revealDuration,
            curve: Curves.easeOutQuint,
          ),
          MoveMotionEffect(
            begin: _artworkOriginOffset(slot),
            end: Offset.zero,
            duration: _WelcomeJobScene._revealDuration,
            curve: Curves.easeOutQuint,
          ),
        ],
    ];
    _artworkReturnEffects = [
      for (final slot in WelcomeArtworkSlot.values)
        [
          const ScaleOutMotionEffect(scale: 0.65, duration: _WelcomeJobScene._returnDuration, curve: Curves.easeInBack),
          MoveMotionEffect(
            begin: Offset.zero,
            end: _artworkOriginOffset(slot),
            duration: _WelcomeJobScene._returnDuration,
            curve: Curves.easeInBack,
          ),
        ],
    ];
    _initialCardRevealEffect = ScaleInMotionEffect(
      scale: 1,
      duration: _WelcomeJobScene._revealDuration,
      curve: Curves.easeOutQuint,
      onEnd: _finishTransition,
    );
    _cardRevealEffect = ScaleInMotionEffect(
      scale: 0.9,
      duration: _WelcomeJobScene._revealDuration,
      curve: Curves.easeOutQuint,
      onEnd: _finishTransition,
    );
    _cardReturnEffect = ScaleOutMotionEffect(
      scale: 0.9,
      duration: _WelcomeJobScene._returnDuration,
      curve: Curves.easeInBack,
      onEnd: _finishTransition,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final animationsPreferenceChanged = animationsDisabled != _animationsDisabled;
    _animationsDisabled = animationsDisabled;
    if (_animationsDisabled) {
      _initialFloatingTimer?.cancel();
      _initialFloatingTimer = null;
      _artworkColorController.value = 1;
    } else if (_phase == WelcomeScenePhase.idle) {
      _startFloating();
    } else {
      _scheduleInitialFloating();
    }
    _scheduleInitialReveal();
    if (!animationsPreferenceChanged || _phase != WelcomeScenePhase.idle) return;

    _scheduleNextJobTransition(
      delay: _animationsDisabled
          ? _WelcomeJobScene._jobChangeInterval
          : _WelcomeJobScene._jobChangeInterval - _WelcomeJobScene._returnDuration,
    );
  }

  @override
  void didUpdateWidget(covariant _WelcomeJobScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floatingStartDelay == widget.floatingStartDelay) return;
    if (_floatingStarted) return;
    _initialFloatingTimer?.cancel();
    _initialFloatingTimer = null;
    _scheduleInitialFloating();
  }

  @override
  void dispose() {
    _initialFloatingTimer?.cancel();
    _initialRevealTimer?.cancel();
    _nextJobTimer?.cancel();
    _artworkColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('welcome_job_scene'),
      container: true,
      image: true,
      label: widget.accessibilityLabel,
      child: ExcludeSemantics(
        child: SizedBox.fromSize(
          size: _WelcomeJobScene.sceneSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final slot in WelcomeArtworkSlot.values)
                _buildArtworkSlot(
                  context: context,
                  slot: slot,
                  illustration: _WelcomeJobScene._illustrationFor(
                    slot: slot,
                    artwork: widget.jobs[_currentJobIndex].artwork,
                  ),
                ),
              _buildCard(job: widget.jobs[_currentJobIndex]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkSlot({
    required BuildContext context,
    required WelcomeArtworkSlot slot,
    required _WelcomeJobIllustration illustration,
  }) {
    return Positioned(
      left: slot.resolveLeft(
        sceneWidth: _WelcomeJobScene.sceneSize.width,
        surfaceSize: _WelcomeJobScene._artworkSurfaceSize,
      ),
      top: slot.resolveTop(
        sceneHeight: _WelcomeJobScene.sceneSize.height,
        surfaceSize: _WelcomeJobScene._artworkSurfaceSize,
        topTrim: _WelcomeJobScene._topTrim,
      ),
      child: _buildFloating(
        key: ValueKey('welcome_artwork_${slot.name}'),
        effect: _artworkFloatingEffects[slot.index],
        child: Motion.list(
          key: ValueKey('welcome_artwork_transition_${slot.name}'),
          controller: _transitionController,
          startup: _animationsDisabled ? MotionStartup.skip : MotionStartup.hold,
          effects: _isReturning ? _artworkReturnEffects[slot.index] : _artworkRevealEffects[slot.index],
          child: _buildArtworkSurface(context: context, slot: slot, illustration: illustration),
        ),
      ),
    );
  }

  Widget _buildArtworkSurface({
    required BuildContext context,
    required WelcomeArtworkSlot slot,
    required _WelcomeJobIllustration illustration,
  }) {
    final previousIllustration = _WelcomeJobScene._illustrationFor(
      slot: slot,
      artwork: widget.jobs[_previousJobIndex].artwork,
    );
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: _WelcomeJobScene._artworkSurfaceSize,
        child: DecoratedBox(
          key: ValueKey('welcome_artwork_circle_${slot.name}'),
          decoration: _WelcomeArtworkBackgroundDecoration(
            beginColor: previousIllustration.backgroundColor(context.mateo.palette),
            endColor: illustration.backgroundColor(context.mateo.palette),
            colorAnimation: _artworkColorController,
          ),
          child: Center(
            child: KeyedSubtree(
              key: ValueKey('welcome_artwork_content_${_currentJobIndex}_${slot.name}'),
              child: illustration.builder(
                width: illustration.width,
                height: illustration.height,
                color: illustration.illustrationColor?.call(context.mateo.palette),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required _WelcomeJob job}) {
    final MotionEffect cardTransitionEffect;
    if (_isReturning) {
      cardTransitionEffect = _cardReturnEffect;
    } else if (_phase == WelcomeScenePhase.revealing && !_hasRotatedJobs) {
      cardTransitionEffect = _initialCardRevealEffect;
    } else {
      cardTransitionEffect = _cardRevealEffect;
    }

    return Positioned(
      left: _WelcomeJobScene._cardLeft,
      top: _WelcomeJobScene._cardTop,
      child: _buildFloating(
        key: const ValueKey('welcome_card_float'),
        effect: _cardFloatingEffect,
        child: Motion(
          key: const ValueKey('welcome_card_transition'),
          controller: _transitionController,
          startup: MotionStartup.skip,
          effect: cardTransitionEffect,
          child: RepaintBoundary(
            child: _WelcomeJobCard(key: const ValueKey('welcome_job_card'), job: job),
          ),
        ),
      ),
    );
  }

  Widget _buildFloating({required Key key, required MotionEffect effect, required Widget child}) {
    return RepaintBoundary(
      child: Motion(
        key: key,
        controller: _floatingController,
        startup: _animationsDisabled ? MotionStartup.skip : MotionStartup.hold,
        effect: effect,
        child: child,
      ),
    );
  }
}
