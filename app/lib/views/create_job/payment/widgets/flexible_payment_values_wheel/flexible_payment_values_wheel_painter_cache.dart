part of 'flexible_payment_values_wheel.dart';

class _FlexiblePaymentValuesWheelPainterCache {
  _FlexiblePaymentValuesWheelPainterCache({
    required List<String> amounts,
    required TextStyle textStyle,
    required this._textDirection,
    required this._locale,
    required this._textScaler,
    required this._textHeightBehavior,
    required this._textWidthBasis,
    required this.devicePixelRatio,
    required this._onAtlasReady,
  }) : _amounts = amounts,
       _textStyle = textStyle {
    _painters = [for (final amount in amounts) _createPainter(text: amount, textStyle: textStyle)];
    _sprites = Float32List(amounts.length * _spriteValueCount);
    _fitScales = Float64List(amounts.length);
  }

  static const _maximumAtlasDimension = 2048;
  static const _maximumAtlasPixels = 2 * 1024 * 1024;
  static const _maximumDirectPainterCount = 512;
  static const _spriteValueCount = 6;

  final Paint _atlasPaint = Paint()..filterQuality = FilterQuality.low;
  final Map<int, TextPainter> _directPainters = <int, TextPainter>{};
  final List<String> _amounts;
  final TextStyle _textStyle;
  final TextDirection _textDirection;
  final Locale _locale;
  final TextScaler _textScaler;
  final ui.TextHeightBehavior? _textHeightBehavior;
  final TextWidthBasis _textWidthBasis;
  final VoidCallback _onAtlasReady;
  final double devicePixelRatio;
  late final List<TextPainter> _painters;
  late final Float32List _sprites;
  late final Float64List _fitScales;
  ui.Image? _atlas;
  double? _preparedContentWidth;
  double? _preparedContentHeight;
  int _atlasGeneration = 0;
  bool _atlasDisabled = false;
  bool _disposed = false;

  double get maximumPainterWidth {
    var maximumWidth = 0.0;
    for (final painter in _painters) {
      maximumWidth = math.max(maximumWidth, painter.width);
    }
    return maximumWidth;
  }

  bool get isAtlasReady => _atlas != null && !_atlasDisabled;

  int get directPainterCount => _directPainters.length;

  double amountFitScale(int index) => _fitScales[index];

  void prepareAtlas({required double contentWidth, required double contentHeight}) {
    if (_preparedContentWidth == contentWidth && _preparedContentHeight == contentHeight) return;

    _preparedContentWidth = contentWidth;
    _preparedContentHeight = contentHeight;
    _atlasGeneration += 1;
    _atlas?.dispose();
    _atlas = null;
    _atlasDisabled = false;
    const paddingPixels = 2;
    var x = 0;
    var y = 0;
    var rowHeight = 0;
    var atlasWidth = 0;
    for (var index = 0; index < _painters.length; index += 1) {
      final painter = _painters[index];
      final widthScale = painter.width <= 0 ? 1.0 : math.max(0, contentWidth) / painter.width;
      final heightScale = painter.height <= 0 ? 1.0 : math.max(0, contentHeight) / painter.height;
      _fitScales[index] = math.min(1, math.min(widthScale, heightScale));
    }
    for (var index = 0; index < _painters.length; index += 1) {
      final painter = _painters[index];
      final fitScale = _fitScales[index];
      final spriteWidth = math.max(1, (painter.width * fitScale * devicePixelRatio).ceil() + paddingPixels * 2);
      final spriteHeight = math.max(1, (painter.height * fitScale * devicePixelRatio).ceil() + paddingPixels * 2);
      if (spriteWidth > _maximumAtlasDimension || spriteHeight > _maximumAtlasDimension) {
        _atlasDisabled = true;
        return;
      }
      if (x > 0 && x + spriteWidth > _maximumAtlasDimension) {
        x = 0;
        y += rowHeight;
        rowHeight = 0;
      }
      if (y + spriteHeight > _maximumAtlasDimension) {
        _atlasDisabled = true;
        return;
      }

      final spriteIndex = index * _spriteValueCount;
      _sprites[spriteIndex] = x.toDouble();
      _sprites[spriteIndex + 1] = y.toDouble();
      _sprites[spriteIndex + 2] = (x + spriteWidth).toDouble();
      _sprites[spriteIndex + 3] = (y + spriteHeight).toDouble();
      _sprites[spriteIndex + 4] = paddingPixels + painter.width * fitScale * devicePixelRatio / 2;
      _sprites[spriteIndex + 5] = paddingPixels + painter.height * fitScale * devicePixelRatio / 2;
      x += spriteWidth;
      rowHeight = math.max(rowHeight, spriteHeight);
      atlasWidth = math.max(atlasWidth, x);
    }

    final atlasHeight = y + rowHeight;
    if (atlasWidth * atlasHeight > _maximumAtlasPixels) {
      _atlasDisabled = true;
      return;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var index = 0; index < _painters.length; index += 1) {
      final spriteIndex = index * _spriteValueCount;
      final left = _sprites[spriteIndex];
      final top = _sprites[spriteIndex + 1];
      final right = _sprites[spriteIndex + 2];
      final bottom = _sprites[spriteIndex + 3];
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(left, top, right, bottom))
        ..translate(left + paddingPixels, top + paddingPixels)
        ..scale(_fitScales[index] * devicePixelRatio);
      _painters[index].paint(canvas, Offset.zero);
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final generation = _atlasGeneration;
    try {
      unawaited(
        _completeAtlasRasterization(
          generation: generation,
          picture: picture,
          imageFuture: picture.toImage(atlasWidth, atlasHeight),
        ),
      );
    } on Exception {
      picture.dispose();
      _atlasDisabled = true;
    }
  }

  void writeSpriteRect({required int amountIndex, required Float32List rects, required int outputIndex}) {
    final spriteIndex = amountIndex * _spriteValueCount;
    rects[outputIndex] = _sprites[spriteIndex];
    rects[outputIndex + 1] = _sprites[spriteIndex + 1];
    rects[outputIndex + 2] = _sprites[spriteIndex + 2];
    rects[outputIndex + 3] = _sprites[spriteIndex + 3];
  }

  void writeSpriteTransform({
    required int amountIndex,
    required double motionScale,
    required double centerX,
    required double centerY,
    required Float32List transforms,
    required int outputIndex,
  }) {
    final spriteIndex = amountIndex * _spriteValueCount;
    final atlasScale = motionScale / devicePixelRatio;
    transforms[outputIndex] = atlasScale;
    transforms[outputIndex + 1] = 0;
    transforms[outputIndex + 2] = centerX - atlasScale * _sprites[spriteIndex + 4];
    transforms[outputIndex + 3] = centerY - atlasScale * _sprites[spriteIndex + 5];
  }

  bool paintAtlas({
    required Canvas canvas,
    required Float32List transforms,
    required Float32List rects,
    required Int32List colors,
  }) {
    final atlas = _atlas;
    if (atlas == null || _atlasDisabled) return false;

    try {
      canvas.drawRawAtlas(atlas, transforms, rects, colors, BlendMode.dstIn, null, _atlasPaint);
      return true;
    } on ui.PictureRasterizationException {
      _disableAtlas();
      return false;
    }
  }

  void paintDirectly({
    required Canvas canvas,
    required int amountIndex,
    required double scale,
    required double centerX,
    required double centerY,
    required int colorValue,
  }) {
    final painterKey = (amountIndex << 32) | (colorValue & 0xFFFFFFFF);
    final cachedPainter = _directPainters[painterKey];
    final painter =
        cachedPainter ??
        _createPainter(
          text: _amounts[amountIndex],
          textStyle: _textStyle.merge(TextStyle(color: Color(colorValue & 0xFFFFFFFF))),
        );
    final shouldDisposePainter = cachedPainter == null && _directPainters.length >= _maximumDirectPainterCount;
    if (cachedPainter == null && !shouldDisposePainter) _directPainters[painterKey] = painter;
    canvas
      ..save()
      ..translate(centerX - painter.width * scale / 2, centerY - painter.height * scale / 2)
      ..scale(scale);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
    if (shouldDisposePainter) painter.dispose();
  }

  void clearDirectPainters() {
    _disposeDirectPainters();
  }

  void dispose() {
    _disposed = true;
    _atlasGeneration += 1;
    _atlas?.dispose();
    _disposeDirectPainters();
    for (final painter in _painters) {
      painter.dispose();
    }
  }

  TextPainter _createPainter({required String text, required TextStyle textStyle}) {
    return TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: TextAlign.center,
      textDirection: _textDirection,
      textScaler: _textScaler,
      locale: _locale,
      maxLines: 1,
      textWidthBasis: _textWidthBasis,
      textHeightBehavior: _textHeightBehavior,
    )..layout();
  }

  Future<void> _completeAtlasRasterization({
    required int generation,
    required ui.Picture picture,
    required Future<ui.Image> imageFuture,
  }) async {
    try {
      final image = await imageFuture;
      if (_disposed || generation != _atlasGeneration) {
        image.dispose();
        return;
      }

      _atlas = image;
      _disposeDirectPainters();
      _onAtlasReady();
    } on Exception {
      if (!_disposed && generation == _atlasGeneration) _atlasDisabled = true;
    } finally {
      picture.dispose();
    }
  }

  void _disposeDirectPainters() {
    for (final painter in _directPainters.values) {
      painter.dispose();
    }
    _directPainters.clear();
  }

  void _disableAtlas() {
    _atlasDisabled = true;
    _atlasGeneration += 1;
    _atlas?.dispose();
    _atlas = null;
  }
}
