part of 'create_job_payment_amount_text.dart';

class _RenderCreateJobPaymentAmountText extends RenderBox with RelayoutWhenSystemFontsChangeMixin {
  _RenderCreateJobPaymentAmountText({
    required String initialAmountText,
    required String initialAmount,
    required String? initialSemanticLabel,
    required bool? initialSemanticSelected,
    required Alignment initialAlignment,
    required double initialDevicePixelRatio,
    required Color initialEdgeFadeColor,
    required Locale initialLocale,
    required TextDirection initialTextDirection,
    required TextScaler initialTextScaler,
    required TextStyle initialTextStyle,
    required TickerProvider vsync,
  }) : _amountText = initialAmountText,
       _amount = initialAmount,
       _semanticLabel = initialSemanticLabel,
       _semanticSelected = initialSemanticSelected,
       _alignment = initialAlignment,
       _devicePixelRatio = initialDevicePixelRatio,
       _edgeFadeColor = initialEdgeFadeColor,
       _locale = initialLocale,
       _textDirection = initialTextDirection,
       _textScaler = initialTextScaler,
       _textStyle = initialTextStyle {
    _ticker = vsync.createTicker(_handleTick);
    _painterCache = _createPainterCache();
    _amountLayout = _resolveLayout(_amount);
    _preparePainterCache(_painterCache);
  }

  static const _glyphClipHorizontalInset = 6.0;
  static const _edgeFadeExtent = 40.0;
  static const _bottomEdgeFadeOverlap = 20.0;
  static const _edgeFadeCurveSegmentCount = 32;
  static const _deletionTransitionDurationMicroseconds = 200000;
  static const _separatorDepartureDurationMicroseconds = 80000;
  static const _minimumDeletionTransitionDurationMicroseconds = 70000;
  static const _deletionTransitionAccelerationMicroseconds = 20000;

  static final List<double> _edgeFadeStops = List<double>.unmodifiable([
    for (var index = 0; index <= _edgeFadeCurveSegmentCount; index++) index / _edgeFadeCurveSegmentCount,
  ]);

  static double _edgeFadeOpacity(double progress) {
    final progressSquared = progress * progress;
    final progressCubed = progressSquared * progress;
    return progressCubed * (progress * (progress * 6 - 15) + 10);
  }

  final Paint _backgroundOverlayPaint = Paint();
  final Paint _bottomEdgeFadePaint = Paint();
  final Paint _edgeFadePaint = Paint();
  final Paint _opacityLayerPaint = Paint();
  final List<
    ({
      String text,
      double left,
      double top,
      double scale,
      double opacity,
      double width,
      Object id,
      int startedAtMicroseconds,
      int durationMicroseconds,
      bool fadesWhileSlidingRight,
      bool slidesRight,
    })
  >
  _departingTokens = [];
  final Map<Object, int> _incomingDigitStartedAtMicroseconds = <Object, int>{};
  final Map<Object, ({double left, double top, double scale, double opacity})> _targetStartGeometry = {};
  final Set<Object> _transitionTokenIds = {};
  late final Ticker _ticker;
  late _CreateJobPaymentAmountTextPainterCache _painterCache;
  late _CreateJobPaymentAmountTextLayout _amountLayout;
  Alignment _alignment;
  double _devicePixelRatio;
  Color _edgeFadeColor;
  Locale _locale;
  TextDirection _textDirection;
  TextScaler _textScaler;
  TextStyle _textStyle;
  String _amountText;
  String _amount;
  String? _semanticLabel;
  bool? _semanticSelected;
  int _clockMicroseconds = 0;
  int _mainTransitionDurationMicroseconds = CreateJobPaymentAmountText.transitionDuration.inMicroseconds;
  int? _lastTickMicroseconds;
  int? _mainTransitionStartedAtMicroseconds;
  ui.Shader? _bottomEdgeFadeShader;
  List<Color>? _edgeFadeColors;
  ui.Shader? _edgeFadeShader;
  double? _edgeFadeShaderExtent;
  Float64List _currentGeometryValues = Float64List(0);
  bool _geometryNeedsUpdate = true;
  bool _lastLayoutHadBoundedWidth = false;
  Map<Object, ({double left, double top, double scale, double opacity})> _presentedTokenGeometry = const {};

  @override
  bool get isRepaintBoundary => true;

  @override
  Rect get paintBounds => Rect.fromLTWH(0, 0, size.width, size.height + _edgeFadeExtent - _bottomEdgeFadeOverlap);

  double get amountLayoutWidth => _amountLayout.width;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..textDirection = _textDirection
      ..label = _semanticLabel ?? _amount;
    if (_semanticLabel == null) return;
    config
      ..value = _amount
      ..isButton = true
      ..isSelected = _semanticSelected ?? false;
  }

  void updateConfiguration({
    required String amountText,
    required String amount,
    required String? semanticLabel,
    required bool? semanticSelected,
    required Alignment alignment,
    required bool animate,
    required double devicePixelRatio,
    required Color edgeFadeColor,
    required Locale locale,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required TextStyle textStyle,
  }) {
    final textResourceConfigurationChanged =
        _devicePixelRatio != devicePixelRatio ||
        _locale != locale ||
        _textDirection != textDirection ||
        _textScaler != textScaler ||
        _textStyle != textStyle;
    final edgeFadeColorChanged = _edgeFadeColor != edgeFadeColor;
    final alignmentChanged = _alignment != alignment;
    final semanticConfigurationChanged = _semanticLabel != semanticLabel || _semanticSelected != semanticSelected;
    _alignment = alignment;
    _devicePixelRatio = devicePixelRatio;
    _edgeFadeColor = edgeFadeColor;
    _locale = locale;
    _textDirection = textDirection;
    _textScaler = textScaler;
    _textStyle = textStyle;
    _semanticLabel = semanticLabel;
    _semanticSelected = semanticSelected;

    if (edgeFadeColorChanged) {
      _bottomEdgeFadeShader = null;
      _bottomEdgeFadePaint.shader = null;
      _edgeFadeColors = null;
      _edgeFadeShader = null;
      _edgeFadeShaderExtent = null;
      _edgeFadePaint.shader = null;
    }
    if (textResourceConfigurationChanged) {
      _replaceTextResources();
      _amountText = amountText;
      _amount = amount;
      _amountLayout = _resolveLayout(_amount);
      _preparePainterCache(_painterCache);
      _settleMotion();
      markNeedsLayout();
      markNeedsSemanticsUpdate();
      return;
    }

    updateAmount(amountText: amountText, amount: amount, animate: animate);
    if (edgeFadeColorChanged) markNeedsPaint();
    if (alignmentChanged) {
      _geometryNeedsUpdate = true;
      markNeedsPaint();
    }
    if (semanticConfigurationChanged) markNeedsSemanticsUpdate();
  }

  void updateAmount({required String amountText, required String amount, required bool animate}) {
    if (_amountText == amountText && _amount == amount) {
      if (!animate && _hasActiveMotion) _settleMotion();
      return;
    }

    if (_amountText == amountText || !animate) {
      _amountText = amountText;
      _amount = amount;
      _amountLayout = _resolveLayout(_amount);
      _settleMotion();
      if (!_lastLayoutHadBoundedWidth) markNeedsLayout();
      markNeedsSemanticsUpdate();
      return;
    }

    _beginAmountTransition(amountText: amountText, amount: amount);
    markNeedsSemanticsUpdate();
  }

  void _beginAmountTransition({required String amountText, required String amount}) {
    _capturePresentedTokenGeometry();
    _pruneDepartingTokens();

    final previousAmountText = _amountText;
    final previousLayout = _amountLayout;
    final nextLayout = _resolveLayout(amount);
    _painterCache.prepareAtlas();
    final previousDigits = _CreateJobPaymentAmountTextTransitionSpec.digitsOf(previousAmountText);
    final nextDigits = _CreateJobPaymentAmountTextTransitionSpec.digitsOf(amountText);
    final deletesTrailingDigit =
        previousDigits.length == nextDigits.length + 1 && previousDigits.startsWith(nextDigits);
    final insertsTrailingDigit =
        nextDigits.length == previousDigits.length + 1 && nextDigits.startsWith(previousDigits);
    final incomingMotionDurationMicroseconds = CreateJobPaymentAmountText.transitionDuration.inMicroseconds;
    final replacementOutgoingMotionDurationMicroseconds = const Duration(milliseconds: 240).inMicroseconds;
    final replacementIncomingDelayMicroseconds = replacementOutgoingMotionDurationMicroseconds ~/ 2;
    final previousIncomingDigitStartedAtMicroseconds = Map<Object, int>.of(_incomingDigitStartedAtMicroseconds);
    final previousIncomingDigitIsPending = previousIncomingDigitStartedAtMicroseconds.values.any(
      (startedAtMicroseconds) => startedAtMicroseconds > _clockMicroseconds,
    );

    _targetStartGeometry.clear();
    _incomingDigitStartedAtMicroseconds.clear();

    for (final token in nextLayout.tokens) {
      final previousToken = previousLayout.tokenById(token.id);
      final targetGeometry = _targetTokenGeometry(layout: nextLayout, token: token);
      final presentedGeometry = _presentedTokenGeometry[token.id];
      var initialGeometry =
          presentedGeometry ??
          (previousToken == null ? targetGeometry : _targetTokenGeometry(layout: previousLayout, token: previousToken));

      if (previousToken == null && token.isSeparator) {
        initialGeometry = (
          left: targetGeometry.left,
          top: targetGeometry.top + _painterCache.lineHeight * targetGeometry.scale,
          scale: targetGeometry.scale,
          opacity: 1,
        );
      }

      final replacesDigit = previousToken != null && token.isDigit && previousToken.text != token.text;
      final previousIncomingDigitStartedAt = previousIncomingDigitStartedAtMicroseconds[token.id];
      if (previousIncomingDigitStartedAt != null &&
          _clockMicroseconds - previousIncomingDigitStartedAt < incomingMotionDurationMicroseconds) {
        final incomingDigitIsPending = _clockMicroseconds < previousIncomingDigitStartedAt;
        _incomingDigitStartedAtMicroseconds[token.id] = incomingDigitIsPending
            ? previousIncomingDigitStartedAt
            : _clockMicroseconds;
        if (incomingDigitIsPending) {
          initialGeometry = _incomingDigitInitialGeometry(token: token, targetGeometry: targetGeometry);
        }
      }
      if ((previousToken == null && token.isDigit && insertsTrailingDigit) ||
          (replacesDigit && !deletesTrailingDigit)) {
        _incomingDigitStartedAtMicroseconds[token.id] =
            _clockMicroseconds +
            (replacesDigit || previousIncomingDigitIsPending ? replacementIncomingDelayMicroseconds : 0);
        initialGeometry = _incomingDigitInitialGeometry(token: token, targetGeometry: targetGeometry);
      }

      if (replacesDigit && !deletesTrailingDigit) {
        _addDepartingToken(
          text: previousToken.text,
          token: previousToken,
          geometry: presentedGeometry ?? _targetTokenGeometry(layout: previousLayout, token: previousToken),
          durationMicroseconds: replacementOutgoingMotionDurationMicroseconds,
          fadesWhileSlidingRight: true,
          slidesRight: false,
        );
      }

      _targetStartGeometry[token.id] = initialGeometry;
    }

    for (final previousToken in previousLayout.tokens) {
      if (nextLayout.tokenById(previousToken.id) != null) continue;

      _addDepartingToken(
        text: previousToken.text,
        token: previousToken,
        geometry:
            _presentedTokenGeometry[previousToken.id] ??
            _targetTokenGeometry(layout: previousLayout, token: previousToken),
        durationMicroseconds: previousToken.isDigit
            ? _deletionDurationMicroseconds(activeDeletionCount: _activeDeletionCount)
            : _separatorDepartureDurationMicroseconds,
        fadesWhileSlidingRight: false,
        slidesRight: previousToken.isDigit,
      );
    }

    if (deletesTrailingDigit) {
      final deletedDigit = previousLayout.lastDigit;
      final matchingTargetToken = deletedDigit == null ? null : nextLayout.tokenById(deletedDigit.id);
      if (deletedDigit != null && matchingTargetToken != null && matchingTargetToken.text != deletedDigit.text) {
        _addDepartingToken(
          text: deletedDigit.text,
          token: deletedDigit,
          geometry:
              _presentedTokenGeometry[deletedDigit.id] ??
              _targetTokenGeometry(layout: previousLayout, token: deletedDigit),
          durationMicroseconds: _deletionDurationMicroseconds(activeDeletionCount: _activeDeletionCount),
          fadesWhileSlidingRight: false,
          slidesRight: true,
        );
      }
    }

    _transitionTokenIds
      ..clear()
      ..addAll(_incomingDigitStartedAtMicroseconds.keys)
      ..addAll(nextLayout.tokens.where((token) => token.isSeparator).map((token) => token.id));

    _amountText = amountText;
    _amount = amount;
    _amountLayout = nextLayout;
    _mainTransitionDurationMicroseconds = incomingMotionDurationMicroseconds;
    for (final startedAtMicroseconds in _incomingDigitStartedAtMicroseconds.values) {
      _mainTransitionDurationMicroseconds = math.max(
        _mainTransitionDurationMicroseconds,
        startedAtMicroseconds + incomingMotionDurationMicroseconds - _clockMicroseconds,
      );
    }
    _mainTransitionStartedAtMicroseconds = _clockMicroseconds;
    _geometryNeedsUpdate = true;
    _startTickerIfNeeded();
    markNeedsPaint();
  }

  void _addDepartingToken({
    required String text,
    required _CreateJobPaymentAmountTextToken token,
    required ({double left, double top, double scale, double opacity}) geometry,
    required int durationMicroseconds,
    required bool fadesWhileSlidingRight,
    required bool slidesRight,
  }) {
    _departingTokens.add((
      text: text,
      left: geometry.left,
      top: geometry.top,
      scale: geometry.scale,
      opacity: geometry.opacity,
      width: token.width,
      id: token.id,
      startedAtMicroseconds: _clockMicroseconds,
      durationMicroseconds: durationMicroseconds,
      fadesWhileSlidingRight: fadesWhileSlidingRight,
      slidesRight: slidesRight,
    ));
  }

  void _capturePresentedTokenGeometry() {
    if (!hasSize) return;
    _writeCurrentTokenGeometry();
    final presentedGeometry = <Object, ({double left, double top, double scale, double opacity})>{};
    for (var index = 0; index < _amountLayout.tokens.length; index += 1) {
      final geometryIndex = index * 4;
      presentedGeometry[_amountLayout.tokens[index].id] = (
        left: _currentGeometryValues[geometryIndex],
        top: _currentGeometryValues[geometryIndex + 1],
        scale: _currentGeometryValues[geometryIndex + 2],
        opacity: _currentGeometryValues[geometryIndex + 3],
      );
    }
    _presentedTokenGeometry = presentedGeometry;
  }

  void _handleTick(Duration elapsed) {
    final elapsedMicroseconds = elapsed.inMicroseconds;
    final previousTickMicroseconds = _lastTickMicroseconds;
    _lastTickMicroseconds = elapsedMicroseconds;
    if (previousTickMicroseconds != null) {
      _clockMicroseconds += elapsedMicroseconds - previousTickMicroseconds;
    }

    _settleCompletedMainTransition();
    _pruneDepartingTokens();
    markNeedsPaint();
    if (_hasActiveMotion) return;
    _ticker.stop();
  }

  void _pruneDepartingTokens() {
    _departingTokens.removeWhere(
      (token) => _clockMicroseconds - token.startedAtMicroseconds >= token.durationMicroseconds,
    );
  }

  void _replaceTextResources() {
    _painterCache.dispose();
    _painterCache = _createPainterCache();
  }

  _CreateJobPaymentAmountTextPainterCache _createPainterCache() {
    return _CreateJobPaymentAmountTextPainterCache(
      textStyle: _textStyle,
      textDirection: _textDirection,
      locale: _locale,
      textScaler: _textScaler,
      devicePixelRatio: _devicePixelRatio,
    );
  }

  void _preparePainterCache(_CreateJobPaymentAmountTextPainterCache painterCache) {
    painterCache
      ..primeLocalizedNumberTokens()
      ..prepareAtlas();
  }

  void _settleCompletedMainTransition() {
    final startedAtMicroseconds = _mainTransitionStartedAtMicroseconds;
    if (startedAtMicroseconds == null ||
        _clockMicroseconds - startedAtMicroseconds < _mainTransitionDurationMicroseconds) {
      return;
    }

    _mainTransitionStartedAtMicroseconds = null;
    _targetStartGeometry.clear();
    _incomingDigitStartedAtMicroseconds.clear();
    _transitionTokenIds.clear();
    _geometryNeedsUpdate = true;
  }

  void _settleMotion() {
    _mainTransitionStartedAtMicroseconds = null;
    _targetStartGeometry.clear();
    _incomingDigitStartedAtMicroseconds.clear();
    _transitionTokenIds.clear();
    _departingTokens.clear();
    _presentedTokenGeometry = const {};
    _lastTickMicroseconds = null;
    _geometryNeedsUpdate = true;
    _ticker.stop();
    markNeedsPaint();
  }

  void _startTickerIfNeeded() {
    if (!attached || _ticker.isActive || !_hasActiveMotion) return;
    _lastTickMicroseconds = null;
    _ticker.start();
  }

  ({double left, double top, double scale, double opacity}) _targetTokenGeometry({
    required _CreateJobPaymentAmountTextLayout layout,
    required _CreateJobPaymentAmountTextToken token,
  }) {
    final scale = _layoutScale(layout);
    final contentLeft = _contentLeft(layout: layout, scale: scale);
    final contentTop = (size.height - _painterCache.lineHeight * scale) / 2;
    return (left: contentLeft + token.left * scale, top: contentTop, scale: scale, opacity: 1);
  }

  ({double left, double top, double scale, double opacity}) _incomingDigitInitialGeometry({
    required _CreateJobPaymentAmountTextToken token,
    required ({double left, double top, double scale, double opacity}) targetGeometry,
  }) {
    return (
      left: targetGeometry.left + _digitMotionExtent(token.width) * targetGeometry.scale,
      top: targetGeometry.top,
      scale: targetGeometry.scale,
      opacity: 1,
    );
  }

  double _incomingDigitMovementProgress({required int startedAtMicroseconds}) {
    return Curves.easeOutCubic.transform(
      ((_clockMicroseconds - startedAtMicroseconds) / CreateJobPaymentAmountText.transitionDuration.inMicroseconds)
          .clamp(0.0, 1.0),
    );
  }

  void _writeCurrentTokenGeometry() {
    final tokenCount = _amountLayout.tokens.length;
    final requiredGeometryLength = tokenCount * 4;
    if (_currentGeometryValues.length != requiredGeometryLength) {
      _currentGeometryValues = Float64List(requiredGeometryLength);
    }

    final movementProgress = Curves.easeOutCubic.transform(_mainTransitionProgress);
    final targetScale = _layoutScale(_amountLayout);
    final targetContentLeft = _contentLeft(layout: _amountLayout, scale: targetScale);
    final targetContentTop = (size.height - _painterCache.lineHeight * targetScale) / 2;

    for (var index = 0; index < tokenCount; index += 1) {
      final token = _amountLayout.tokens[index];
      final targetLeft = targetContentLeft + token.left * targetScale;
      final initial = _targetStartGeometry[token.id];
      final incomingDigitStartedAtMicroseconds = _incomingDigitStartedAtMicroseconds[token.id];
      final tokenMovementProgress = incomingDigitStartedAtMicroseconds == null
          ? movementProgress
          : _incomingDigitMovementProgress(startedAtMicroseconds: incomingDigitStartedAtMicroseconds);
      final geometryIndex = index * 4;
      if (initial == null) {
        _currentGeometryValues[geometryIndex] = targetLeft;
        _currentGeometryValues[geometryIndex + 1] = targetContentTop;
        _currentGeometryValues[geometryIndex + 2] = targetScale;
        _currentGeometryValues[geometryIndex + 3] = 1;
        continue;
      }
      _currentGeometryValues[geometryIndex] = initial.left + (targetLeft - initial.left) * tokenMovementProgress;
      _currentGeometryValues[geometryIndex + 1] =
          initial.top + (targetContentTop - initial.top) * tokenMovementProgress;
      _currentGeometryValues[geometryIndex + 2] = initial.scale + (targetScale - initial.scale) * tokenMovementProgress;
      _currentGeometryValues[geometryIndex + 3] = 1;
    }
  }

  double _digitMotionExtent(double digitWidth) {
    return digitWidth + _glyphClipHorizontalInset + _edgeFadeExtent;
  }

  Rect _digitMotionClipRect({
    required double digitWidth,
    required double left,
    required double top,
    required double scale,
  }) {
    return Rect.fromLTWH(
      left - _glyphClipHorizontalInset * scale,
      top,
      (_digitMotionExtent(digitWidth) + _glyphClipHorizontalInset) * scale,
      _painterCache.lineHeight * scale,
    );
  }

  void _paintIncomingDigit({
    required Canvas canvas,
    required _CreateJobPaymentAmountTextToken token,
    required double left,
    required double top,
    required double scale,
    required double opacity,
  }) {
    final targetScale = _layoutScale(_amountLayout);
    final targetLeft = _contentLeft(layout: _amountLayout, scale: targetScale) + token.left * targetScale;
    final targetTop = (size.height - _painterCache.lineHeight * targetScale) / 2;
    canvas
      ..save()
      ..clipRect(_digitMotionClipRect(digitWidth: token.width, left: targetLeft, top: targetTop, scale: targetScale));
    _paintGlyph(
      canvas: canvas,
      text: token.text,
      left: left,
      top: top,
      scale: scale,
      opacity: opacity,
      width: token.width,
      horizontalOverlayInset: _glyphClipHorizontalInset,
    );
    _paintEdgeFade(canvas: canvas, digitWidth: token.width, left: targetLeft, top: targetTop, scale: targetScale);
    canvas.restore();
  }

  void _paintDepartingToken({
    required Canvas canvas,
    required ({
      String text,
      double left,
      double top,
      double scale,
      double opacity,
      double width,
      Object id,
      int startedAtMicroseconds,
      int durationMicroseconds,
      bool fadesWhileSlidingRight,
      bool slidesRight,
    })
    token,
  }) {
    final rawProgress = ((_clockMicroseconds - token.startedAtMicroseconds) / token.durationMicroseconds).clamp(
      0.0,
      1.0,
    );
    if (token.fadesWhileSlidingRight || token.slidesRight) {
      final movementProgress = Curves.easeOutCubic.transform(rawProgress);
      final left = token.left + _digitMotionExtent(token.width) * token.scale * movementProgress;
      canvas
        ..save()
        ..clipRect(_digitMotionClipRect(digitWidth: token.width, left: token.left, top: token.top, scale: token.scale));
      if (token.fadesWhileSlidingRight) {
        final opacityProgress = Curves.easeOutQuart.transform(rawProgress);
        _opacityLayerPaint.color = _edgeFadeColor.withValues(alpha: token.opacity * (1 - opacityProgress));
        canvas.saveLayer(
          Rect.fromLTWH(
            left - _glyphClipHorizontalInset * token.scale,
            token.top,
            (token.width + _glyphClipHorizontalInset * 2) * token.scale,
            _painterCache.lineHeight * token.scale,
          ),
          _opacityLayerPaint,
        );
      }
      _paintGlyph(
        canvas: canvas,
        text: token.text,
        left: left,
        top: token.top,
        scale: token.scale,
        opacity: token.fadesWhileSlidingRight ? 1 : token.opacity,
        width: token.width,
        horizontalOverlayInset: _glyphClipHorizontalInset,
        useAtlas: false,
      );
      if (token.fadesWhileSlidingRight) canvas.restore();
      _paintEdgeFade(canvas: canvas, digitWidth: token.width, left: token.left, top: token.top, scale: token.scale);
      canvas.restore();
      return;
    }

    final movementProgress = Curves.easeInCubic.transform(rawProgress);
    canvas
      ..save()
      ..clipRect(
        Rect.fromLTWH(
          token.left - _glyphClipHorizontalInset * token.scale,
          token.top,
          (token.width + _glyphClipHorizontalInset * 2) * token.scale,
          (_painterCache.lineHeight + _edgeFadeExtent - _bottomEdgeFadeOverlap) * token.scale,
        ),
      );
    _paintGlyph(
      canvas: canvas,
      text: token.text,
      left: token.left,
      top: token.top + _painterCache.lineHeight * token.scale * movementProgress,
      scale: token.scale,
      opacity: token.opacity,
      width: token.width,
      useAtlas: false,
    );
    _paintBottomEdgeFade(canvas: canvas, left: token.left, top: token.top, scale: token.scale, width: token.width);
    canvas.restore();
  }

  void _paintGlyph({
    required Canvas canvas,
    required String text,
    required double left,
    required double top,
    required double scale,
    required double opacity,
    required double width,
    double horizontalOverlayInset = 0,
    bool useAtlas = true,
  }) {
    final paintedWithAtlas =
        useAtlas && _painterCache.paintGlyph(canvas: canvas, text: text, left: left, top: top, scale: scale);
    if (!paintedWithAtlas) {
      final painter = _painterCache.painterFor(text);
      canvas
        ..save()
        ..translate(left, top)
        ..scale(scale);
      painter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    if (opacity >= 1) return;
    _paintBackgroundOverlay(
      left: left - horizontalOverlayInset * scale,
      top: top,
      scale: scale,
      opacity: opacity,
      width: width + horizontalOverlayInset * 2,
      canvas: canvas,
    );
  }

  void _paintBackgroundOverlay({
    required Canvas canvas,
    required double left,
    required double top,
    required double scale,
    required double opacity,
    required double width,
  }) {
    if (opacity >= 1) return;
    _backgroundOverlayPaint.color = _edgeFadeColor.withValues(alpha: 1 - opacity);
    canvas.drawRect(Rect.fromLTWH(left, top, width * scale, _painterCache.lineHeight * scale), _backgroundOverlayPaint);
  }

  void _paintEdgeFade({
    required Canvas canvas,
    required double digitWidth,
    required double left,
    required double top,
    required double scale,
  }) {
    if (_edgeFadeShader == null || _edgeFadeShaderExtent != _edgeFadeExtent) {
      _edgeFadeShader = ui.Gradient.linear(
        Offset.zero,
        const Offset(_edgeFadeExtent, 0),
        _resolvedEdgeFadeColors,
        _edgeFadeStops,
      );
      _edgeFadeShaderExtent = _edgeFadeExtent;
    }
    _edgeFadePaint.shader = _edgeFadeShader;
    canvas
      ..save()
      ..translate(left + (digitWidth + _glyphClipHorizontalInset) * scale, top)
      ..scale(scale)
      ..drawRect(Rect.fromLTWH(0, 0, _edgeFadeExtent, _painterCache.lineHeight), _edgeFadePaint)
      ..restore();
  }

  void _paintBottomEdgeFade({
    required Canvas canvas,
    required double left,
    required double top,
    required double scale,
    required double width,
  }) {
    _bottomEdgeFadeShader ??= ui.Gradient.linear(
      Offset.zero,
      const Offset(0, _edgeFadeExtent),
      _resolvedEdgeFadeColors,
      _edgeFadeStops,
    );
    _bottomEdgeFadePaint.shader = _bottomEdgeFadeShader;
    canvas
      ..save()
      ..translate(
        left - _glyphClipHorizontalInset * scale,
        top + (_painterCache.lineHeight - _bottomEdgeFadeOverlap) * scale,
      )
      ..scale(scale)
      ..drawRect(Rect.fromLTWH(0, 0, width + _glyphClipHorizontalInset * 2, _edgeFadeExtent), _bottomEdgeFadePaint)
      ..restore();
  }

  List<Color> get _resolvedEdgeFadeColors => _edgeFadeColors ??= [
    for (var index = 0; index <= _edgeFadeCurveSegmentCount; index++)
      _edgeFadeColor.withValues(alpha: _edgeFadeColor.a * _edgeFadeOpacity(index / _edgeFadeCurveSegmentCount)),
  ];

  double _layoutScale(_CreateJobPaymentAmountTextLayout layout) {
    if (!size.width.isFinite || layout.width <= 0) return 1;
    final contentWidth = math.max(0, size.width - CreateJobPaymentAmountText.contentPadding.horizontal);
    return math.min(1, contentWidth / layout.width);
  }

  double _contentLeft({required _CreateJobPaymentAmountTextLayout layout, required double scale}) {
    const padding = CreateJobPaymentAmountText.contentPadding;
    final contentWidth = math.max(0, size.width - padding.horizontal);
    return padding.left + (contentWidth - layout.width * scale) * (_alignment.x + 1) / 2;
  }

  double get _mainTransitionProgress {
    final startedAtMicroseconds = _mainTransitionStartedAtMicroseconds;
    if (startedAtMicroseconds == null) return 1;
    return ((_clockMicroseconds - startedAtMicroseconds) / CreateJobPaymentAmountText.transitionDuration.inMicroseconds)
        .clamp(0.0, 1.0);
  }

  int get _activeDeletionCount => _departingTokens.where((token) => token.slidesRight).length;

  bool get _hasActiveMainTransition => _mainTransitionStartedAtMicroseconds != null;

  bool get _hasActiveMotion => _hasActiveMainTransition || _departingTokens.isNotEmpty;

  int _deletionDurationMicroseconds({required int activeDeletionCount}) {
    return math.max(
      _minimumDeletionTransitionDurationMicroseconds,
      _deletionTransitionDurationMicroseconds - activeDeletionCount * _deletionTransitionAccelerationMicroseconds,
    );
  }

  _CreateJobPaymentAmountTextLayout _resolveLayout(String amount) {
    return _CreateJobPaymentAmountTextLayout.resolve(text: amount, widthOf: _painterCache.width);
  }

  Size _layoutSize(BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : _amountLayout.width + CreateJobPaymentAmountText.contentPadding.horizontal;
    return constraints.constrain(Size(width, _painterCache.lineHeight));
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _startTickerIfNeeded();
  }

  @override
  void detach() {
    _ticker.stop();
    _lastTickMicroseconds = null;
    super.detach();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _painterCache.dispose();
    super.dispose();
  }

  @override
  void performLayout() {
    _lastLayoutHadBoundedWidth = constraints.hasBoundedWidth;
    size = _layoutSize(constraints);
    _geometryNeedsUpdate = true;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layoutSize(constraints);

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    _replaceTextResources();
    _amountLayout = _resolveLayout(_amount);
    _preparePainterCache(_painterCache);
    _settleMotion();
    markNeedsLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final recomputeTransforms = _hasActiveMainTransition || _geometryNeedsUpdate;
    if (recomputeTransforms) _writeCurrentTokenGeometry();
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..clipRect(paintBounds);

    for (final token in _departingTokens) {
      if (!token.fadesWhileSlidingRight) continue;
      _paintDepartingToken(canvas: canvas, token: token);
    }
    _painterCache.paintTokenGlyphs(
      canvas: canvas,
      tokens: _amountLayout.tokens,
      geometryValues: _currentGeometryValues,
      recomputeTransforms: recomputeTransforms,
      excludedTokenIds: _hasActiveMainTransition ? _transitionTokenIds : null,
    );
    if (_hasActiveMainTransition) {
      for (var index = 0; index < _amountLayout.tokens.length; index += 1) {
        final token = _amountLayout.tokens[index];
        final geometryIndex = index * 4;
        final left = _currentGeometryValues[geometryIndex];
        final top = _currentGeometryValues[geometryIndex + 1];
        final scale = _currentGeometryValues[geometryIndex + 2];
        final opacity = _currentGeometryValues[geometryIndex + 3];
        final incomingDigitStartedAtMicroseconds = _incomingDigitStartedAtMicroseconds[token.id];
        if (incomingDigitStartedAtMicroseconds != null) {
          if (_clockMicroseconds < incomingDigitStartedAtMicroseconds) continue;
          _paintIncomingDigit(canvas: canvas, token: token, left: left, top: top, scale: scale, opacity: opacity);
          continue;
        }
        if (token.isSeparator) continue;
        _paintBackgroundOverlay(
          canvas: canvas,
          left: left,
          top: top,
          scale: scale,
          opacity: opacity,
          width: token.width,
        );
      }
      for (var index = 0; index < _amountLayout.tokens.length; index += 1) {
        final token = _amountLayout.tokens[index];
        if (!token.isSeparator) continue;
        final geometryIndex = index * 4;
        _paintGlyph(
          canvas: canvas,
          text: token.text,
          left: _currentGeometryValues[geometryIndex],
          top: _currentGeometryValues[geometryIndex + 1],
          scale: _currentGeometryValues[geometryIndex + 2],
          opacity: _currentGeometryValues[geometryIndex + 3],
          width: token.width,
        );
      }
    }
    for (final token in _departingTokens) {
      if (token.fadesWhileSlidingRight) continue;
      _paintDepartingToken(canvas: canvas, token: token);
    }

    canvas.restore();
    _geometryNeedsUpdate = false;
  }
}
