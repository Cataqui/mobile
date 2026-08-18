part of 'create_job_payment_amount_text.dart';

class _CreateJobPaymentAmountTextPainterCache {
  _CreateJobPaymentAmountTextPainterCache({
    required this.textStyle,
    required this.textDirection,
    required this.locale,
    required this.textScaler,
    required this.devicePixelRatio,
  });

  static const _maximumAtlasDimension = 2048;
  static const _maximumAtlasPixels = 1024 * 1024;

  final Paint _atlasPaint = Paint()..filterQuality = FilterQuality.low;
  final Map<String, TextPainter> _painters = <String, TextPainter>{};
  final Map<String, ({double left, double top, double right, double bottom, double anchorX, double anchorY})> _sprites =
      {};
  final TextStyle textStyle;
  final TextDirection textDirection;
  final Locale locale;
  final TextScaler textScaler;
  final double devicePixelRatio;
  Float32List _atlasRects = Float32List(0);
  Float32List _atlasTransforms = Float32List(0);
  final Float32List _singleGlyphAtlasRects = Float32List(4);
  final Float32List _singleGlyphAtlasTransforms = Float32List(4);
  ui.Image? _atlas;
  bool _atlasDisabled = false;
  bool _atlasDirty = true;
  bool _atlasDrawValidated = false;
  int _atlasRevision = 0;
  int _preparedAtlasRevision = -1;
  List<_CreateJobPaymentAmountTextToken>? _preparedTokens;
  Iterable<Object>? _preparedExcludedTokenIds;
  late final double _inverseDevicePixelRatio = 1 / devicePixelRatio;
  late final double _lineHeight = painterFor('0').height;

  double get lineHeight => _lineHeight;

  void dispose() {
    _atlas?.dispose();
    for (final painter in _painters.values) {
      painter.dispose();
    }
    _painters.clear();
  }

  void paintTokenGlyphs({
    required Canvas canvas,
    required List<_CreateJobPaymentAmountTextToken> tokens,
    required Float64List geometryValues,
    required bool recomputeTransforms,
    Iterable<Object>? excludedTokenIds,
  }) {
    final hasExcludedTokenIds = excludedTokenIds?.isNotEmpty ?? false;
    var glyphCount = tokens.length;
    if (hasExcludedTokenIds) {
      glyphCount = 0;
      for (final token in tokens) {
        if (!excludedTokenIds!.contains(token.id)) glyphCount += 1;
      }
    }
    if (glyphCount == 0) return;

    prepareAtlas();
    final atlas = _atlas;
    if (atlas == null) {
      _paintTokenGlyphsDirectly(
        canvas: canvas,
        tokens: tokens,
        geometryValues: geometryValues,
        excludedTokenIds: excludedTokenIds,
      );
      return;
    }

    final canReusePreparedTransforms =
        !recomputeTransforms &&
        identical(_preparedTokens, tokens) &&
        identical(_preparedExcludedTokenIds, excludedTokenIds) &&
        _preparedAtlasRevision == _atlasRevision;
    if (!canReusePreparedTransforms) {
      if (!_prepareAtlasTransforms(
        tokens: tokens,
        geometryValues: geometryValues,
        glyphCount: glyphCount,
        excludedTokenIds: excludedTokenIds,
      )) {
        _paintTokenGlyphsDirectly(
          canvas: canvas,
          tokens: tokens,
          geometryValues: geometryValues,
          excludedTokenIds: excludedTokenIds,
        );
        return;
      }
    }
    if (!_atlasDrawValidated) {
      try {
        canvas.drawRawAtlas(atlas, _atlasTransforms, _atlasRects, null, null, null, _atlasPaint);
        _atlasDrawValidated = true;
      } on ui.PictureRasterizationException {
        _disableAtlas();
        _paintTokenGlyphsDirectly(
          canvas: canvas,
          tokens: tokens,
          geometryValues: geometryValues,
          excludedTokenIds: excludedTokenIds,
        );
      }
      return;
    }

    canvas.drawRawAtlas(atlas, _atlasTransforms, _atlasRects, null, null, null, _atlasPaint);
  }

  bool paintGlyph({
    required Canvas canvas,
    required String text,
    required double left,
    required double top,
    required double scale,
  }) {
    if (!_atlasDrawValidated) return false;

    final atlas = _atlas;
    if (atlas == null) return false;
    if (!_writeAtlasTransform(
      text: text,
      left: left,
      top: top,
      scale: scale,
      rects: _singleGlyphAtlasRects,
      transforms: _singleGlyphAtlasTransforms,
      outputIndex: 0,
    )) {
      return false;
    }

    canvas.drawRawAtlas(atlas, _singleGlyphAtlasTransforms, _singleGlyphAtlasRects, null, null, null, _atlasPaint);
    return true;
  }

  bool _prepareAtlasTransforms({
    required List<_CreateJobPaymentAmountTextToken> tokens,
    required Float64List geometryValues,
    required int glyphCount,
    required Iterable<Object>? excludedTokenIds,
  }) {
    final bufferLength = glyphCount * 4;
    if (_atlasRects.length != bufferLength) {
      _atlasRects = Float32List(bufferLength);
      _atlasTransforms = Float32List(bufferLength);
    }
    final hasExcludedTokenIds = excludedTokenIds?.isNotEmpty ?? false;
    final rects = _atlasRects;
    final transforms = _atlasTransforms;
    var glyphIndex = 0;
    for (var index = 0; index < tokens.length; index += 1) {
      final token = tokens[index];
      if (hasExcludedTokenIds && excludedTokenIds!.contains(token.id)) continue;
      final geometryIndex = index * 4;
      final bufferIndex = glyphIndex * 4;
      if (!_writeAtlasTransform(
        text: token.text,
        left: geometryValues[geometryIndex],
        top: geometryValues[geometryIndex + 1],
        scale: geometryValues[geometryIndex + 2],
        rects: rects,
        transforms: transforms,
        outputIndex: bufferIndex,
      )) {
        _disableAtlas();
        return false;
      }
      glyphIndex += 1;
    }
    _preparedTokens = tokens;
    _preparedExcludedTokenIds = excludedTokenIds;
    _preparedAtlasRevision = _atlasRevision;
    return true;
  }

  bool _writeAtlasTransform({
    required String text,
    required double left,
    required double top,
    required double scale,
    required Float32List rects,
    required Float32List transforms,
    required int outputIndex,
  }) {
    final sprite = _sprites[text];
    final painter = _painters[text];
    if (sprite == null || painter == null) return false;

    final atlasScale = scale * _inverseDevicePixelRatio;
    rects[outputIndex] = sprite.left;
    rects[outputIndex + 1] = sprite.top;
    rects[outputIndex + 2] = sprite.right;
    rects[outputIndex + 3] = sprite.bottom;
    transforms[outputIndex] = atlasScale;
    transforms[outputIndex + 1] = 0;
    transforms[outputIndex + 2] = left + painter.width * scale / 2 - atlasScale * sprite.anchorX;
    transforms[outputIndex + 3] = top + painter.height * scale / 2 - atlasScale * sprite.anchorY;
    return true;
  }

  void _paintTokenGlyphsDirectly({
    required Canvas canvas,
    required List<_CreateJobPaymentAmountTextToken> tokens,
    required Float64List geometryValues,
    required Iterable<Object>? excludedTokenIds,
  }) {
    final hasExcludedTokenIds = excludedTokenIds?.isNotEmpty ?? false;
    for (var index = 0; index < tokens.length; index += 1) {
      final token = tokens[index];
      if (hasExcludedTokenIds && excludedTokenIds!.contains(token.id)) continue;
      final geometryIndex = index * 4;
      final painter = painterFor(token.text);
      canvas
        ..save()
        ..translate(geometryValues[geometryIndex], geometryValues[geometryIndex + 1])
        ..scale(geometryValues[geometryIndex + 2]);
      painter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  TextPainter painterFor(String text) {
    final painter = _painters[text];
    if (painter != null) return painter;

    _atlasDirty = true;
    return _painters[text] = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      maxLines: 1,
    )..layout();
  }

  void primeLocalizedNumberTokens() {
    for (final character in '0123456789'.characters) {
      painterFor(character);
    }
    final localizedNumber =
        (NumberFormat.decimalPattern(locale.toString())
              ..minimumFractionDigits = 2
              ..maximumFractionDigits = 2)
            .format(9876543210.12);
    for (final character in localizedNumber.characters) {
      painterFor(character);
    }
  }

  void prepareAtlas() {
    if (!_atlasDirty || _atlasDisabled || _painters.isEmpty) return;

    _atlas?.dispose();
    _atlas = null;
    _sprites.clear();
    final padding = math.max(2 / devicePixelRatio, _RenderCreateJobPaymentAmountText._glyphClipHorizontalInset);
    final paddingPixels = (padding * devicePixelRatio).ceil();
    var x = 0;
    var y = 0;
    var rowHeight = 0;
    var atlasWidth = 0;
    for (final entry in _painters.entries) {
      final painter = entry.value;
      final glyphWidth = (painter.width * devicePixelRatio).ceil();
      final glyphHeight = (painter.height * devicePixelRatio).ceil();
      final spriteWidth = math.max(1, glyphWidth + paddingPixels * 2);
      final spriteHeight = math.max(1, glyphHeight + paddingPixels * 2);
      if (spriteWidth > _maximumAtlasDimension || spriteHeight > _maximumAtlasDimension) {
        _disableAtlas();
        return;
      }
      if (x > 0 && x + spriteWidth > _maximumAtlasDimension) {
        x = 0;
        y += rowHeight;
        rowHeight = 0;
      }
      if (y + spriteHeight > _maximumAtlasDimension) {
        _disableAtlas();
        return;
      }
      _sprites[entry.key] = (
        left: x.toDouble(),
        top: y.toDouble(),
        right: (x + spriteWidth).toDouble(),
        bottom: (y + spriteHeight).toDouble(),
        anchorX: paddingPixels + painter.width * devicePixelRatio / 2,
        anchorY: paddingPixels + painter.height * devicePixelRatio / 2,
      );
      x += spriteWidth;
      rowHeight = math.max(rowHeight, spriteHeight);
      atlasWidth = math.max(atlasWidth, x);
    }
    final atlasHeight = y + rowHeight;
    if (atlasWidth * atlasHeight > _maximumAtlasPixels) {
      _disableAtlas();
      return;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(devicePixelRatio, devicePixelRatio);
    for (final entry in _painters.entries) {
      final sprite = _sprites[entry.key]!;
      final left = sprite.left / devicePixelRatio;
      final top = sprite.top / devicePixelRatio;
      final right = sprite.right / devicePixelRatio;
      final bottom = sprite.bottom / devicePixelRatio;
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(left, top, right, bottom));
      entry.value.paint(
        canvas,
        Offset(left + paddingPixels / devicePixelRatio, top + paddingPixels / devicePixelRatio),
      );
      canvas.restore();
    }
    final picture = recorder.endRecording();
    try {
      _atlas = picture.toImageSync(atlasWidth, atlasHeight);
      _atlasDrawValidated = false;
      _atlasRevision += 1;
    } on ui.PictureRasterizationException {
      _sprites.clear();
      _disableAtlas();
    } finally {
      picture.dispose();
    }
    _atlasDirty = false;
  }

  void _disableAtlas() {
    _atlasDisabled = true;
    _atlasDirty = false;
    _atlasDrawValidated = false;
    _atlas?.dispose();
    _atlas = null;
    _preparedTokens = null;
    _preparedExcludedTokenIds = null;
    _preparedAtlasRevision = -1;
    _atlasRevision += 1;
  }

  double width(String text) => painterFor(text).width;
}
