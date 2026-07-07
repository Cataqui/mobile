part of 'qui_skeleton.dart';

class _QuiSkeletonCanvas implements Canvas {
  _QuiSkeletonCanvas({
    required this._parent,
    required this._leafRegistry,
    required this._skeletonPaint,
    required this._textRadius,
  });

  final Canvas _parent;
  final _QuiSkeletonLeafRegistry _leafRegistry;
  final Paint _skeletonPaint;
  final Radius? _textRadius;

  Rect _textLineToRect({required LineMetrics line, required Offset offset}) {
    return Rect.fromLTWH(
      offset.dx + line.left,
      offset.dy + line.baseline - line.ascent,
      line.width,
      line.ascent + line.descent,
    );
  }

  bool _isBoneAt(Offset center) => _leafRegistry.contains(center);

  @override
  void drawRect(Rect rect, Paint paint) {
    if (paint.color.a == 0) return;

    if (_isBoneAt(rect.center)) {
      _parent.drawRect(rect, _skeletonPaint);
    } else {
      _parent.drawRect(rect, paint);
    }
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    if (paint.color.a == 0) return;

    if (_isBoneAt(rrect.center)) {
      _parent.drawRRect(rrect, _skeletonPaint);
    } else {
      _parent.drawRRect(rrect, paint);
    }
  }

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    if (paint.color.a == 0) return;
    if (_isBoneAt(outer.center)) {
      _parent.drawDRRect(outer, inner, _skeletonPaint);
    } else {
      _parent.drawDRRect(outer, inner, paint);
    }
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    if (paint.color.a == 0) return;
    if (_isBoneAt(c)) {
      _parent.drawCircle(c, radius, _skeletonPaint);
    } else {
      _parent.drawCircle(c, radius, paint);
    }
  }

  @override
  void drawOval(Rect rect, Paint paint) {
    if (paint.color.a == 0) return;
    if (_isBoneAt(rect.center)) {
      _parent.drawOval(rect, _skeletonPaint);
    } else {
      _parent.drawOval(rect, paint);
    }
  }

  @override
  void drawPath(Path path, Paint paint) {
    if (paint.color.a == 0) return;
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;
    if (_isBoneAt(bounds.center)) {
      _parent.drawPath(path, _skeletonPaint);
    } else {
      _parent.drawPath(path, paint);
    }
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    if (paragraph.height <= 0) return;
    const lineSpacing = 6.0;

    final lines = paragraph.computeLineMetrics();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineOffset = offset + Offset(0, i * lineSpacing);
      final rect = _textLineToRect(line: line, offset: lineOffset);
      final radius = _textRadius ?? Radius.circular(rect.height / 2);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      _parent.drawRRect(rrect, _skeletonPaint);
    }
  }

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) {
    final rect = offset & Size(image.width.toDouble(), image.height.toDouble());
    _parent.drawRect(rect, _skeletonPaint);
  }

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {
    _parent.drawRect(dst, _skeletonPaint);
  }

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) {
    _parent.drawRect(dst, _skeletonPaint);
  }

  @override
  void drawColor(Color color, BlendMode blendMode) {
    _parent.drawColor(color, blendMode);
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    _parent.drawLine(p1, p2, paint);
  }

  @override
  void drawPaint(Paint paint) {
    _parent.drawPaint(paint);
  }

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {
    _parent.drawPoints(pointMode, points, paint);
  }

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) {
    _parent.drawRawPoints(pointMode, points, paint);
  }

  @override
  void drawShadow(Path path, Color color, double elevation, bool transparentOccluder) {
    _parent.drawShadow(path, color, elevation, transparentOccluder);
  }

  @override
  void drawVertices(ui.Vertices vertices, ui.BlendMode blendMode, Paint paint) {
    _parent.drawVertices(vertices, blendMode, paint);
  }

  @override
  void drawAtlas(
    ui.Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    ui.BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {
    _parent.drawAtlas(atlas, transforms, rects, colors, blendMode, cullRect, paint);
  }

  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    ui.BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {
    _parent.drawRawAtlas(atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
  }

  @override
  void drawPicture(ui.Picture picture) {
    _parent.drawPicture(picture);
  }

  @override
  void clipRect(Rect rect, {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true}) {
    _parent.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    _parent.clipRRect(rrect, doAntiAlias: doAntiAlias);
  }

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    _parent.clipPath(path, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRSuperellipse(ui.RSuperellipse rsuperellipse, {bool doAntiAlias = true}) {
    _parent.clipRSuperellipse(rsuperellipse, doAntiAlias: doAntiAlias);
  }

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint) {
    _parent.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  }

  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, Paint paint) {
    _parent.drawRSuperellipse(rsuperellipse, paint);
  }

  @override
  Rect getDestinationClipBounds() => _parent.getDestinationClipBounds();

  @override
  Rect getLocalClipBounds() => _parent.getLocalClipBounds();

  @override
  void save() => _parent.save();

  @override
  void saveLayer(Rect? bounds, Paint paint) => _parent.saveLayer(bounds, paint);

  @override
  void restore() => _parent.restore();

  @override
  int getSaveCount() => _parent.getSaveCount();

  @override
  void translate(double dx, double dy) => _parent.translate(dx, dy);

  @override
  void scale(double sx, [double? sy]) => _parent.scale(sx, sy);

  @override
  void rotate(double radians) => _parent.rotate(radians);

  @override
  void skew(double sx, double sy) => _parent.skew(sx, sy);

  @override
  void transform(Float64List matrix4) => _parent.transform(matrix4);

  @override
  Float64List getTransform() => _parent.getTransform();

  @override
  void restoreToCount(int count) => _parent.restoreToCount(count);
}
