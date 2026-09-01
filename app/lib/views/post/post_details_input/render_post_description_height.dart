part of 'post_details_input.dart';

class _RenderPostDescriptionHeight extends RenderProxyBox {
  _RenderPostDescriptionHeight({
    required TickerProvider vsync,
    required Duration duration,
    required Curve curve,
    required this._animationsDisabled,
    RenderBox? child,
  }) : _vsync = vsync,
       super(child) {
    _heightAnimationController = AnimationController(vsync: vsync, duration: duration)
      ..addListener(_handleAnimationTick);
    _heightAnimation = CurvedAnimation(parent: _heightAnimationController, curve: curve);
  }
  late final AnimationController _heightAnimationController;
  late final CurvedAnimation _heightAnimation;
  TickerProvider _vsync;
  bool _animationsDisabled;
  BoxConstraints? _naturalConstraints;
  Size? _naturalChildSize;
  double? _targetHeight;
  double? _animationBeginHeight;
  double? _animationEndHeight;
  bool _naturalSizeIsDirty = true;
  bool _isStartingHeightAnimationDuringLayout = false;
  bool _isAnimatingHeight = false;

  Duration get duration => _heightAnimationController.duration!;
  set duration(Duration value) {
    if (value == duration) return;
    _heightAnimationController.duration = value;
    if (value != Duration.zero) return;
    _heightAnimationController.stop();
    _animationBeginHeight = null;
    _animationEndHeight = null;
    _isAnimatingHeight = false;
    markNeedsLayout();
  }

  Curve get curve => _heightAnimation.curve;
  set curve(Curve value) {
    if (value == curve) return;
    _heightAnimation.curve = value;
  }

  TickerProvider get vsync => _vsync;
  set vsync(TickerProvider value) {
    if (value == vsync) return;
    _vsync = value;
    _heightAnimationController.resync(value);
  }

  bool get animationsDisabled => _animationsDisabled;
  set animationsDisabled(bool value) {
    if (value == animationsDisabled) return;
    _animationsDisabled = value;
    if (value) {
      _heightAnimationController.stop();
      _animationBeginHeight = null;
      _animationEndHeight = null;
      _isAnimatingHeight = false;
    }
    markNeedsLayout();
  }

  double get _currentHeight {
    final animationBeginHeight = _animationBeginHeight;
    final animationEndHeight = _animationEndHeight;
    if (animationBeginHeight == null || animationEndHeight == null) return _targetHeight!;

    return animationBeginHeight + (animationEndHeight - animationBeginHeight) * _heightAnimation.value;
  }

  void _handleAnimationTick() {
    if (_isStartingHeightAnimationDuringLayout) return;
    super.markNeedsLayout();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_isAnimatingHeight) return;
    _isAnimatingHeight = false;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _heightAnimationController.addStatusListener(_handleAnimationStatus);
    if (!_isAnimatingHeight || _animationsDisabled) return;
    super.markNeedsLayout();
    _heightAnimationController.forward();
  }

  @override
  void detach() {
    _heightAnimationController.stop();
    _heightAnimationController.removeStatusListener(_handleAnimationStatus);
    super.detach();
  }

  @override
  void markNeedsLayout() {
    _naturalSizeIsDirty = true;
    super.markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    final naturalConstraints = constraints.copyWith(minHeight: 0, maxHeight: double.infinity);
    final shouldMeasureNaturalSize =
        _naturalChildSize == null || _naturalConstraints != naturalConstraints || _naturalSizeIsDirty;
    if (shouldMeasureNaturalSize) {
      _naturalConstraints = naturalConstraints;
      _naturalChildSize = child.getDryLayout(naturalConstraints);
      _naturalSizeIsDirty = false;
    }

    final naturalChildSize = constraints.constrain(_naturalChildSize!);
    final targetHeight = naturalChildSize.height;
    final previousTargetHeight = _targetHeight;
    if (previousTargetHeight == null) {
      _targetHeight = targetHeight;
    } else if (targetHeight != previousTargetHeight) {
      final currentHeight = _currentHeight;
      _targetHeight = targetHeight;
      if (_animationsDisabled || duration == Duration.zero) {
        _heightAnimationController.stop();
        _animationBeginHeight = null;
        _animationEndHeight = null;
        _isAnimatingHeight = false;
      } else {
        _animationBeginHeight = currentHeight;
        _animationEndHeight = targetHeight;
        _isAnimatingHeight = true;
        _isStartingHeightAnimationDuringLayout = true;
        _heightAnimationController.forward(from: 0);
        _isStartingHeightAnimationDuringLayout = false;
      }
    }

    final currentHeight = _currentHeight;
    child.layout(BoxConstraints.tight(naturalChildSize), parentUsesSize: true);
    size = constraints.constrain(Size(child.size.width, currentHeight));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;

    final childSize = child.getDryLayout(constraints.copyWith(minHeight: 0, maxHeight: double.infinity));
    final targetHeight = constraints.constrain(childSize).height;
    if (_animationsDisabled || duration == Duration.zero) {
      return constraints.constrain(Size(childSize.width, targetHeight));
    }
    final currentHeight = _targetHeight == null ? targetHeight : _currentHeight;
    return constraints.constrain(Size(childSize.width, currentHeight));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (!_animationsDisabled &&
        duration != Duration.zero &&
        _targetHeight != null &&
        _naturalChildSize?.width == width) {
      return _currentHeight;
    }
    return child?.getMinIntrinsicHeight(width) ?? 0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (!_animationsDisabled &&
        duration != Duration.zero &&
        _targetHeight != null &&
        _naturalChildSize?.width == width) {
      return _currentHeight;
    }
    return child?.getMaxIntrinsicHeight(width) ?? 0;
  }

  @override
  void dispose() {
    _heightAnimation.dispose();
    _heightAnimationController.dispose();
    super.dispose();
  }
}
