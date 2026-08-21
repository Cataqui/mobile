part of 'flexible_payment_values_wheel.dart';

class FlexiblePaymentValuesWheelRenderBox extends RenderBox with RelayoutWhenSystemFontsChangeMixin {
  FlexiblePaymentValuesWheelRenderBox({
    required Animation<double> initialAnimation,
    required List<String> initialAmounts,
    required String initialSemanticLabel,
    required Color initialAdjacentColor,
    required Color initialCenteredColor,
    required Color initialBackgroundColor,
    required double initialDevicePixelRatio,
    required Locale initialLocale,
    required TextDirection initialTextDirection,
    required TextScaler initialTextScaler,
    required TextStyle initialTextStyle,
    required ui.TextHeightBehavior? initialTextHeightBehavior,
    required TextWidthBasis initialTextWidthBasis,
  }) : assert(initialBackgroundColor.a == 1, 'The paint-only edge fade requires an opaque background color.'),
       _animation = initialAnimation,
       _amounts = List<String>.unmodifiable(initialAmounts),
       _semanticLabel = initialSemanticLabel,
       _adjacentColor = initialAdjacentColor,
       _centeredColor = initialCenteredColor,
       _backgroundColor = initialBackgroundColor,
       _devicePixelRatio = initialDevicePixelRatio,
       _locale = initialLocale,
       _textDirection = initialTextDirection,
       _textScaler = initialTextScaler,
       _textStyle = initialTextStyle,
       _textHeightBehavior = initialTextHeightBehavior,
       _textWidthBasis = initialTextWidthBasis {
    _adjacentColorValue = initialAdjacentColor.toARGB32();
    _centeredColorValue = initialCenteredColor.toARGB32();
    _painterCache = _createPainterCache();
  }

  final Paint _edgeFadePaint = Paint();
  final Float32List _restingRects = Float32List(12);
  final Float32List _restingTransforms = Float32List(12);
  final Int32List _restingColors = Int32List(3);
  final Int32List _restingAmountIndices = Int32List(3);
  final Float32List _movingRects = Float32List(16);
  final Float32List _movingTransforms = Float32List(16);
  final Int32List _movingColors = Int32List(4);
  final Int32List _movingAmountIndices = Int32List(4);
  final Float32List _amountScales = Float32List(4);
  final Float32List _amountCenterYs = Float32List(4);
  late _FlexiblePaymentValuesWheelPainterCache _painterCache;
  Animation<double> _animation;
  List<String> _amounts;
  String _semanticLabel;
  Color _adjacentColor;
  Color _centeredColor;
  Color _backgroundColor;
  double _devicePixelRatio;
  Locale _locale;
  TextDirection _textDirection;
  TextScaler _textScaler;
  TextStyle _textStyle;
  ui.TextHeightBehavior? _textHeightBehavior;
  TextWidthBasis _textWidthBasis;
  late int _adjacentColorValue;
  late int _centeredColorValue;
  int _restingRectsCenteredIndex = -1;
  int _movingRectsCenteredIndex = -1;
  Rect _cullRect = Rect.zero;
  Rect _topFadeRect = Rect.zero;
  Rect _bottomFadeRect = Rect.zero;
  ui.Shader? _edgeFadeShader;
  double _centerX = 0;
  double _centerY = 0;

  @visibleForTesting
  ({String amount, Offset center, double scale, Color color}) debugAmountAt({required int relativeIndex}) {
    final sequenceProgress = _animation.value * _amounts.length;
    final centeredIndex = sequenceProgress.floor() % _amounts.length;
    final stepProgress = sequenceProgress - sequenceProgress.floor();
    final stepMotion =
        stepProgress -
        FlexiblePaymentValuesWheel._stepMotionStrength * math.sin(stepProgress * math.pi * 2) / (math.pi * 2);
    final centeredProgress = (1 + math.cos(stepMotion.abs().clamp(0, 1) * math.pi)) / 2;
    final nextProgress = 1 - centeredProgress;
    final progress = switch (relativeIndex) {
      0 => centeredProgress,
      1 => nextProgress,
      _ => 0.0,
    };
    final amountIndex = (centeredIndex + relativeIndex) % _amounts.length;
    final amountScale =
        FlexiblePaymentValuesWheel._adjacentAmountScale +
        progress * (1 - FlexiblePaymentValuesWheel._adjacentAmountScale);

    return (
      amount: _amounts[amountIndex],
      center: Offset(
        size.width / 2,
        size.height / 2 + (relativeIndex - stepMotion) * FlexiblePaymentValuesWheel._slotExtent,
      ),
      scale: amountScale,
      color: Color(_lerpedColorValue(progress) & 0xFFFFFFFF),
    );
  }

  @visibleForTesting
  int get debugVisibleAmountCount {
    final sequenceProgress = _animation.value * _amounts.length;
    final stepProgress = sequenceProgress - sequenceProgress.floor();
    final stepMotion =
        stepProgress -
        FlexiblePaymentValuesWheel._stepMotionStrength * math.sin(stepProgress * math.pi * 2) / (math.pi * 2);
    return stepMotion == 0 ? 3 : 4;
  }

  @visibleForTesting
  double get debugFontSize => _textStyle.fontSize!;

  @visibleForTesting
  TextStyle get debugTextStyle => _textStyle;

  @visibleForTesting
  bool get debugIsAtlasReady => _painterCache.isAtlasReady;

  @visibleForTesting
  int get debugDirectPainterCount => _painterCache.directPainterCount;

  void updateConfiguration({
    required Animation<double> animation,
    required List<String> amounts,
    required String semanticLabel,
    required Color adjacentColor,
    required Color centeredColor,
    required Color backgroundColor,
    required double devicePixelRatio,
    required Locale locale,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required TextStyle textStyle,
    required ui.TextHeightBehavior? textHeightBehavior,
    required TextWidthBasis textWidthBasis,
  }) {
    assert(backgroundColor.a == 1, 'The paint-only edge fade requires an opaque background color.');
    final animationChanged = _animation != animation;
    final textResourcesChanged =
        !listEquals(_amounts, amounts) ||
        _devicePixelRatio != devicePixelRatio ||
        _locale != locale ||
        _textDirection != textDirection ||
        _textScaler != textScaler ||
        _textStyle != textStyle ||
        _textHeightBehavior != textHeightBehavior ||
        _textWidthBasis != textWidthBasis;
    final colorsChanged = _adjacentColor != adjacentColor || _centeredColor != centeredColor;
    final fadeChanged = _backgroundColor != backgroundColor || _devicePixelRatio != devicePixelRatio;
    final semanticsChanged = _semanticLabel != semanticLabel || _textDirection != textDirection;

    if (animationChanged && attached) _animation.removeListener(_handleAnimationTick);
    _animation = animation;
    if (animationChanged && attached) _animation.addListener(_handleAnimationTick);
    if (!listEquals(_amounts, amounts)) _amounts = List<String>.unmodifiable(amounts);
    _semanticLabel = semanticLabel;
    _adjacentColor = adjacentColor;
    _centeredColor = centeredColor;
    _backgroundColor = backgroundColor;
    _devicePixelRatio = devicePixelRatio;
    _locale = locale;
    _textDirection = textDirection;
    _textScaler = textScaler;
    _textStyle = textStyle;
    _textHeightBehavior = textHeightBehavior;
    _textWidthBasis = textWidthBasis;

    if (colorsChanged) {
      _adjacentColorValue = adjacentColor.toARGB32();
      _centeredColorValue = centeredColor.toARGB32();
      _painterCache.clearDirectPainters();
    }
    if (fadeChanged) _edgeFadeShader = null;
    if (semanticsChanged) markNeedsSemanticsUpdate();
    if (textResourcesChanged) {
      _replaceTextResources();
      _restingRectsCenteredIndex = -1;
      _movingRectsCenteredIndex = -1;
      markNeedsLayout();
    }
    if (animationChanged || textResourcesChanged || colorsChanged || fadeChanged) markNeedsPaint();
  }

  void _handleAnimationTick() {
    markNeedsPaint();
  }

  _FlexiblePaymentValuesWheelPainterCache _createPainterCache() {
    return _FlexiblePaymentValuesWheelPainterCache(
      amounts: _amounts,
      textStyle: _textStyle,
      textDirection: _textDirection,
      locale: _locale,
      textScaler: _textScaler,
      devicePixelRatio: _devicePixelRatio,
      textHeightBehavior: _textHeightBehavior,
      textWidthBasis: _textWidthBasis,
      onAtlasReady: _handleAtlasReady,
    );
  }

  void _handleAtlasReady() {
    markNeedsPaint();
  }

  void _replaceTextResources() {
    _painterCache.dispose();
    _painterCache = _createPainterCache();
  }

  int _lerpedColorValue(double progress) {
    if (progress <= 0) return _adjacentColorValue.toSigned(32);
    if (progress >= 1) return _centeredColorValue.toSigned(32);

    final alpha =
        ((_adjacentColorValue >> 24 & 0xFF) +
                ((_centeredColorValue >> 24 & 0xFF) - (_adjacentColorValue >> 24 & 0xFF)) * progress)
            .round();
    final red =
        ((_adjacentColorValue >> 16 & 0xFF) +
                ((_centeredColorValue >> 16 & 0xFF) - (_adjacentColorValue >> 16 & 0xFF)) * progress)
            .round();
    final green =
        ((_adjacentColorValue >> 8 & 0xFF) +
                ((_centeredColorValue >> 8 & 0xFF) - (_adjacentColorValue >> 8 & 0xFF)) * progress)
            .round();
    final blue =
        ((_adjacentColorValue & 0xFF) + ((_centeredColorValue & 0xFF) - (_adjacentColorValue & 0xFF)) * progress)
            .round();
    return (alpha << 24 | red << 16 | green << 8 | blue).toSigned(32);
  }

  void _prepareSpriteRects({
    required int centeredIndex,
    required int amountCount,
    required Float32List rects,
    required Int32List amountIndices,
  }) {
    for (var index = 0; index < amountCount; index += 1) {
      final amountIndex = (centeredIndex + index - 1) % _amounts.length;
      amountIndices[index] = amountIndex;
      _painterCache.writeSpriteRect(amountIndex: amountIndex, rects: rects, outputIndex: index * 4);
    }
  }

  void _writeSpriteGeometry({
    required double stepMotion,
    required double centeredProgress,
    required int amountCount,
    required Float32List transforms,
    required Int32List colors,
    required Int32List amountIndices,
  }) {
    for (var index = 0; index < amountCount; index += 1) {
      final progress = switch (index) {
        1 => centeredProgress,
        2 => 1 - centeredProgress,
        _ => 0.0,
      };
      final amountIndex = amountIndices[index];
      final motionScale =
          FlexiblePaymentValuesWheel._adjacentAmountScale +
          progress * (1 - FlexiblePaymentValuesWheel._adjacentAmountScale);
      final scale = motionScale * _painterCache.amountFitScale(amountIndex);
      final centerY = _centerY + (index - 1 - stepMotion) * FlexiblePaymentValuesWheel._slotExtent;
      _amountScales[index] = scale;
      _amountCenterYs[index] = centerY;
      colors[index] = _lerpedColorValue(progress);
      _painterCache.writeSpriteTransform(
        amountIndex: amountIndex,
        motionScale: motionScale,
        centerX: _centerX,
        centerY: centerY,
        transforms: transforms,
        outputIndex: index * 4,
      );
    }
  }

  void _paintAmounts({
    required Canvas canvas,
    required double stepMotion,
    required double centeredProgress,
    required int centeredIndex,
  }) {
    final moving = stepMotion != 0;
    final amountCount = moving ? 4 : 3;
    final rects = moving ? _movingRects : _restingRects;
    final transforms = moving ? _movingTransforms : _restingTransforms;
    final colors = moving ? _movingColors : _restingColors;
    final amountIndices = moving ? _movingAmountIndices : _restingAmountIndices;
    if (moving && _movingRectsCenteredIndex != centeredIndex) {
      _prepareSpriteRects(
        centeredIndex: centeredIndex,
        amountCount: amountCount,
        rects: rects,
        amountIndices: amountIndices,
      );
      _movingRectsCenteredIndex = centeredIndex;
    }
    if (!moving && _restingRectsCenteredIndex != centeredIndex) {
      _prepareSpriteRects(
        centeredIndex: centeredIndex,
        amountCount: amountCount,
        rects: rects,
        amountIndices: amountIndices,
      );
      _restingRectsCenteredIndex = centeredIndex;
    }

    _writeSpriteGeometry(
      stepMotion: stepMotion,
      centeredProgress: centeredProgress,
      amountCount: amountCount,
      transforms: transforms,
      colors: colors,
      amountIndices: amountIndices,
    );
    if (_painterCache.paintAtlas(canvas: canvas, transforms: transforms, rects: rects, colors: colors)) {
      return;
    }

    for (var index = 0; index < amountCount; index += 1) {
      _painterCache.paintDirectly(
        canvas: canvas,
        amountIndex: amountIndices[index],
        scale: _amountScales[index],
        centerX: _centerX,
        centerY: _amountCenterYs[index],
        colorValue: colors[index],
      );
    }
  }

  void _paintEdgeFade(Canvas canvas) {
    if (_edgeFadeShader == null) {
      final transparentBackground = _backgroundColor.withValues(alpha: 0);
      _edgeFadeShader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [
          _backgroundColor,
          _backgroundColor,
          transparentBackground,
          transparentBackground,
          _backgroundColor,
          _backgroundColor,
        ],
        [
          0,
          (FlexiblePaymentValuesWheel._fontSize * FlexiblePaymentValuesWheel._adjacentAmountScale / 2 +
                  1 / _devicePixelRatio) /
              size.height,
          _topFadeRect.bottom / size.height,
          _bottomFadeRect.top / size.height,
          1 -
              (FlexiblePaymentValuesWheel._fontSize * FlexiblePaymentValuesWheel._adjacentAmountScale / 2 +
                      1 / _devicePixelRatio) /
                  size.height,
          1,
        ],
      );
    }
    _edgeFadePaint.shader = _edgeFadeShader;
    canvas
      ..drawRect(_topFadeRect, _edgeFadePaint)
      ..drawRect(_bottomFadeRect, _edgeFadePaint);
  }

  Size _layoutSize(BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : _painterCache.maximumPainterWidth + FlexiblePaymentValuesWheel._horizontalContentPadding;
    return constraints.constrain(Size(width, FlexiblePaymentValuesWheel._height));
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..textDirection = _textDirection
      ..label = _semanticLabel;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(_handleAnimationTick);
  }

  @override
  void detach() {
    _animation.removeListener(_handleAnimationTick);
    super.detach();
  }

  @override
  void dispose() {
    _painterCache.dispose();
    super.dispose();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layoutSize(constraints);

  @override
  void performResize() {
    size = _layoutSize(constraints);
    _cullRect = Offset.zero & size;
    _centerX = size.width / 2;
    _centerY = size.height / 2;
    _painterCache.prepareAtlas(
      contentWidth: math.max(0, size.width - FlexiblePaymentValuesWheel._horizontalContentPadding),
      contentHeight: size.height,
    );
    const adjacentAmountHalfHeight =
        FlexiblePaymentValuesWheel._fontSize * FlexiblePaymentValuesWheel._adjacentAmountScale / 2;
    final opaqueCenterStart = FlexiblePaymentValuesWheel._slotExtent - adjacentAmountHalfHeight - 1 / _devicePixelRatio;
    _topFadeRect = Rect.fromLTWH(0, 0, size.width, opaqueCenterStart);
    _bottomFadeRect = Rect.fromLTWH(0, size.height - opaqueCenterStart, size.width, opaqueCenterStart);
    _edgeFadeShader = null;
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    _replaceTextResources();
    _restingRectsCenteredIndex = -1;
    _movingRectsCenteredIndex = -1;
    markNeedsLayout();
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final sequenceProgress = _animation.value * _amounts.length;
    final centeredIndex = sequenceProgress.floor() % _amounts.length;
    final stepProgress = sequenceProgress - sequenceProgress.floor();
    final stepMotion =
        stepProgress -
        FlexiblePaymentValuesWheel._stepMotionStrength * math.sin(stepProgress * math.pi * 2) / (math.pi * 2);
    final centeredProgress = (1 + math.cos(stepMotion * math.pi)) / 2;
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..clipRect(_cullRect);
    _paintAmounts(
      canvas: canvas,
      stepMotion: stepMotion,
      centeredProgress: centeredProgress,
      centeredIndex: centeredIndex,
    );
    _paintEdgeFade(canvas);
    canvas.restore();
  }
}
