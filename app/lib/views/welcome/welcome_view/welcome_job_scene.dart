part of 'welcome_view.dart';

class _WelcomeJobScene extends StatefulWidget {
  const _WelcomeJobScene({
    required this.jobs,
    required this.accessibilityLabel,
    required this.initialRevealDelay,
    super.key,
  }) : assert(jobs.length > 1, 'The welcome scene requires at least two jobs.');

  static const sceneSize = Size(_WelcomeJobCard.width + _cardHorizontalInset * 2, _referenceCanvasHeight - _topTrim);

  static Future<void> precacheJob(BuildContext context, {required _WelcomeJob job}) async {
    await Future.wait(
      [job.artwork.top, job.artwork.right, job.artwork.left, job.artwork.bottom, job.artwork.corner].map((
        illustration,
      ) {
        return illustration.precache(context, width: illustration.width, height: illustration.height);
      }),
    );
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

  final List<_WelcomeJob> jobs;
  final String accessibilityLabel;
  final Duration initialRevealDelay;

  @override
  State<_WelcomeJobScene> createState() => _WelcomeJobSceneState();
}

class _WelcomeJobSceneState extends State<_WelcomeJobScene> {
  final MotionController _transitionController = MotionController();
  Timer? _initialRevealTimer;
  Timer? _nextJobTimer;
  WelcomeScenePhase _phase = WelcomeScenePhase.initial;
  int _currentJobIndex = 0;
  bool _animationsDisabled = false;
  bool _hasRotatedJobs = false;

  bool get _isReturning => _phase == WelcomeScenePhase.returning;

  Duration get _transitionDuration =>
      _isReturning ? _WelcomeJobScene._returnDuration : _WelcomeJobScene._revealDuration;

  Curve get _transitionCurve => _isReturning ? Curves.easeInBack : Curves.easeOutQuint;

  _WelcomeJobIllustration _illustrationFor({required WelcomeArtworkSlot slot, required _WelcomeJobArtwork artwork}) {
    return switch (slot) {
      WelcomeArtworkSlot.top => artwork.top,
      WelcomeArtworkSlot.rightTopCorner => artwork.right,
      WelcomeArtworkSlot.leftBottomCorner => artwork.left,
      WelcomeArtworkSlot.bottom => artwork.bottom,
      WelcomeArtworkSlot.rightBottomCorner => artwork.corner,
    };
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
        _currentJobIndex = (_currentJobIndex + 1) % widget.jobs.length;
        _hasRotatedJobs = true;
        _phase = WelcomeScenePhase.idle;
      });
      _precacheNextJob();
      _scheduleNextJobTransition();
      return;
    }
    if (_phase != WelcomeScenePhase.idle) return;

    setState(() => _phase = WelcomeScenePhase.returning);
    _transitionController.play();
  }

  void _precacheNextJob() {
    unawaited(_WelcomeJobScene.precacheJob(context, job: widget.jobs[(_currentJobIndex + 1) % widget.jobs.length]));
  }

  void _finishTransition() {
    if (!mounted) return;

    switch (_phase) {
      case WelcomeScenePhase.initial:
      case WelcomeScenePhase.idle:
        return;
      case WelcomeScenePhase.revealing:
        setState(() => _phase = WelcomeScenePhase.idle);
        _precacheNextJob();
        _scheduleNextJobTransition();
        return;
      case WelcomeScenePhase.returning:
        setState(() {
          _currentJobIndex = (_currentJobIndex + 1) % widget.jobs.length;
          _hasRotatedJobs = true;
          _phase = WelcomeScenePhase.revealing;
        });
        _transitionController.play();
        return;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final animationsPreferenceChanged = animationsDisabled != _animationsDisabled;
    _animationsDisabled = animationsDisabled;
    _scheduleInitialReveal();
    if (!animationsPreferenceChanged || _phase != WelcomeScenePhase.idle) return;

    _scheduleNextJobTransition(
      delay: _animationsDisabled
          ? _WelcomeJobScene._jobChangeInterval
          : _WelcomeJobScene._jobChangeInterval - _WelcomeJobScene._returnDuration,
    );
  }

  @override
  void dispose() {
    _initialRevealTimer?.cancel();
    _nextJobTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('welcome_job_scene'),
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
                  illustration: _illustrationFor(slot: slot, artwork: widget.jobs[_currentJobIndex].artwork),
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
    final left = slot.resolveLeft(
      sceneWidth: _WelcomeJobScene.sceneSize.width,
      surfaceSize: _WelcomeJobScene._artworkSurfaceSize,
    );
    final top = slot.resolveTop(
      sceneHeight: _WelcomeJobScene.sceneSize.height,
      surfaceSize: _WelcomeJobScene._artworkSurfaceSize,
      topTrim: _WelcomeJobScene._topTrim,
    );
    final originOffset =
        _WelcomeJobScene._artworkOrigin -
        Offset(left + _WelcomeJobScene._artworkSurfaceSize / 2, top + _WelcomeJobScene._artworkSurfaceSize / 2);

    return Positioned(
      left: left,
      top: top,
      child: _buildFloating(
        key: ValueKey('welcome_artwork_${slot.name}'),
        delay: slot.floatingDelay,
        duration: slot.floatingDuration,
        distance: slot.floatingDistance,
        child: Motion.list(
          key: ValueKey('welcome_artwork_transition_${slot.name}'),
          controller: _transitionController,
          startup: _animationsDisabled ? MotionStartup.skip : MotionStartup.hold,
          effects: [
            if (_isReturning)
              ScaleOutMotionEffect(scale: 0.65, duration: _transitionDuration, curve: _transitionCurve)
            else
              ScaleInMotionEffect(scale: 0.65, duration: _transitionDuration, curve: _transitionCurve),
            if (_isReturning)
              MoveMotionEffect(
                begin: Offset.zero,
                end: originOffset,
                duration: _transitionDuration,
                curve: _transitionCurve,
              )
            else
              MoveMotionEffect(
                begin: originOffset,
                end: Offset.zero,
                duration: _transitionDuration,
                curve: _transitionCurve,
              ),
          ],
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
    return RepaintBoundary(
      child: AnimatedContainer(
        key: ValueKey('welcome_artwork_circle_${slot.name}'),
        width: _WelcomeJobScene._artworkSurfaceSize,
        height: _WelcomeJobScene._artworkSurfaceSize,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : _WelcomeJobScene._revealDuration,
        curve: Curves.easeOutQuint,
        decoration: BoxDecoration(color: illustration.backgroundColor(context.mateo.palette), shape: BoxShape.circle),
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
    );
  }

  Widget _buildCard({required _WelcomeJob job}) {
    return Positioned(
      left: _WelcomeJobScene._cardLeft,
      top: _WelcomeJobScene._cardTop,
      child: _buildFloating(
        key: const ValueKey('welcome_card_float'),
        delay: const Duration(milliseconds: 180),
        duration: const Duration(milliseconds: 2800),
        distance: 4,
        child: Motion(
          key: const ValueKey('welcome_card_transition'),
          controller: _transitionController,
          startup: MotionStartup.skip,
          effect: _isReturning
              ? ScaleOutMotionEffect(
                  scale: 0.9,
                  duration: _transitionDuration,
                  curve: _transitionCurve,
                  onEnd: _finishTransition,
                )
              : ScaleInMotionEffect(
                  scale: _phase == WelcomeScenePhase.revealing && !_hasRotatedJobs ? 1 : 0.9,
                  duration: _transitionDuration,
                  curve: _transitionCurve,
                  onEnd: _finishTransition,
                ),
          child: RepaintBoundary(
            child: _WelcomeJobCard(key: ValueKey('welcome_job_$_currentJobIndex'), job: job),
          ),
        ),
      ),
    );
  }

  Widget _buildFloating({
    required Key key,
    required Duration delay,
    required Duration duration,
    required double distance,
    required Widget child,
  }) {
    return RepaintBoundary(
      child: Motion(
        key: key,
        effect: FloatingMotionEffect(distance: distance, delay: delay, duration: duration),
        child: child,
      ),
    );
  }
}
