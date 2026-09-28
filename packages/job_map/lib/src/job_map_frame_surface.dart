part of 'job_map_frame.dart';

class _JobMapFrameSurface extends StatefulWidget {
  const _JobMapFrameSurface({
    required this.scene,
    required this.frame,
    required this.coordinator,
    required this.animateChanges,
    super.key,
  });

  final JobMapScene scene;
  final MapFrame? frame;
  final MapFrameCoordinator coordinator;
  final bool animateChanges;

  @override
  State<_JobMapFrameSurface> createState() => _JobMapFrameSurfaceState();
}

class _JobMapFrameSurfaceState extends State<_JobMapFrameSurface> with TickerProviderStateMixin {
  static const _fadeCurve = Curves.easeInOut;

  late final AnimationController _mapRevealAnimationController = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 280),
  );
  late final AnimationController _mapDetailAnimationController = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 320),
  )..addStatusListener(_onFadeStatusChanged);
  late final Animation<double> _mapRevealOpacity = _mapRevealAnimationController.drive(CurveTween(curve: _fadeCurve));
  late final Animation<double> _mapDetailOpacity = _mapDetailAnimationController.drive(CurveTween(curve: _fadeCurve));
  MapFrame? _previousFrame;
  bool _animate = true;

  void _releaseAfterPaint(MapFrame frame) {
    final coordinator = widget.coordinator;
    WidgetsBinding.instance.addPostFrameCallback((_) => coordinator.releaseFrame(frame));
    WidgetsBinding.instance.scheduleFrame();
  }

  void _clearPreviousFrame() {
    final previous = _previousFrame;
    _previousFrame = null;
    if (previous != null) _releaseAfterPaint(previous);
  }

  void _onFadeStatusChanged(AnimationStatus status) {
    if (status != .completed || _previousFrame == null) return;
    setState(_clearPreviousFrame);
  }

  @override
  void initState() {
    super.initState();
    final frame = widget.frame;
    if (frame != null) widget.coordinator.retainFrame(frame);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context) && TickerMode.valuesOf(context).enabled;
    if (_animate) return;
    _clearPreviousFrame();
    _mapRevealAnimationController.value = 1;
    _mapDetailAnimationController.value = 1;
  }

  @override
  void didUpdateWidget(_JobMapFrameSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final frame = widget.frame;
    final oldFrame = oldWidget.frame;
    if (frame?.textureId == oldFrame?.textureId) return;
    if (frame != null) widget.coordinator.retainFrame(frame);
    if (!_animate || !widget.animateChanges || frame == null) {
      _clearPreviousFrame();
      if (oldFrame != null) _releaseAfterPaint(oldFrame);
      _mapRevealAnimationController.value = 1;
      _mapDetailAnimationController.value = 1;
      return;
    }
    if (oldFrame == null) {
      _mapRevealAnimationController.forward(from: 0);
      return;
    }
    if (frame.scene.sharesBasemapWith(oldFrame.scene) &&
        frame.scene.widthPx > oldFrame.scene.widthPx &&
        frame.scene.heightPx > oldFrame.scene.heightPx) {
      _clearPreviousFrame();
      _releaseAfterPaint(oldFrame);
      _mapDetailAnimationController.value = 1;
      return;
    }
    if (_mapDetailAnimationController.isAnimating) {
      // A newer refinement shares the ongoing reveal instead of replaying it.
      _releaseAfterPaint(oldFrame);
      return;
    }
    _clearPreviousFrame();
    _previousFrame = oldFrame;
    _mapDetailAnimationController.forward(from: 0);
  }

  @override
  void dispose() {
    _mapRevealAnimationController.dispose();
    _mapDetailAnimationController.dispose();
    _clearPreviousFrame();
    final frame = widget.frame;
    if (frame != null) _releaseAfterPaint(frame);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceOverride = JobMapFrameSurfaceOverride.maybeOf(context);
    final frame = widget.frame;
    final previous = _previousFrame;
    final Widget surface;
    if (frame == null) {
      surface = surfaceOverride?.builder(context, widget.scene, null) ?? const SizedBox.expand();
    } else {
      surface = FadeTransition(
        opacity: _mapRevealOpacity,
        child: Stack(
          fit: .expand,
          children: [
            if (previous != null) _buildFrame(context, previous, surfaceOverride),
            FadeTransition(opacity: _mapDetailOpacity, child: _buildFrame(context, frame, surfaceOverride)),
          ],
        ),
      );
    }
    return ColoredBox(
      color: Color(widget.scene.backgroundColorArgb),
      child: CustomPaint(
        foregroundPainter: surfaceOverride == null
            ? JobMapLocationArea(
                scene: widget.scene,
                attributionScale: frame?.scene.nativeScale ?? widget.scene.nativeScale,
              )
            : null,
        child: surface,
      ),
    );
  }

  Widget _buildFrame(BuildContext context, MapFrame frame, JobMapFrameSurfaceOverride? surfaceOverride) =>
      surfaceOverride?.builder(context, widget.scene, frame) ?? Texture(textureId: frame.textureId);
}
