library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qui/qui.dart';

part 'qui_dot_matrix_dot.dart';
part 'qui_dot_matrix_painter.dart';

/// A matrix of dots with an organic, continuously navigating highlight
/// that never repeats or jumps, indicating content is loading.
///
/// Use [QuiDotMatrix] inside any area whose dimensions are known
/// but whose content is not yet ready — an image slot, a card body, or a full
/// screen that is about to reveal a surprise.  When [width] and [height] are
/// omitted the scene fills the available parent space.
///
/// ```dart
/// QuiDotMatrix(width: 320, height: 220, radius: 16)
/// ```
///
/// ## How it works
///
/// The scene builds concentric parallel curves of the rounded‑rectangle
/// shape. Each layer is a self‑contained contour: when the layer still has
/// rounded corners (lr > 0) dots are placed by walking the full perimeter at
/// even padding intervals; when the rounding is exhausted (lr = 0) dots
/// are placed per‑edge with exact corner positions so squares read cleanly
/// at every scale. All layers descend at the same centre‑to‑centre
/// step, so dot density is uniform regardless of [radius]. As [radius]
/// increases, straight edges progressively shrink and quarter‑circle arcs
/// grow, morphing continuously from a square silhouette to concentric
/// rings.
///
/// Instead of a single rigid wave, three independent Gaussian nodes
/// drift around the matrix like living things — each with its own
/// position, size, and intensity that evolve smoothly via deterministic
/// noise.  Their combined influence creates shapes that emerge and
/// dissolve organically: sometimes a single circular blob glows in one
/// area, sometimes two nodes stretch into a worm‑like band, sometimes
/// all three spread across the shape in a complex flowing pattern.  The
/// motion never repeats, never jumps, and never feels algorithmic.
///
/// As the highlight passes over each dot, the dot subtly increases in
/// size and becomes fully opaque, then smoothly returns
/// to normal size and low opacity as the highlight moves on.
/// Neighbouring dots transition together so the motion feels like a
/// flowing spotlight.
///
///
/// ## Performance
///
/// The scene is a single [CustomPaint] inside a [RepaintBoundary].  Per frame
/// it issues roughly one `drawCircle` call per grid cell.  There is no blur,
/// no `saveLayer`, no gradients, and no off‑screen buffers.  The scene honours
/// [MediaQuery.disableAnimationsOf], pauses its ticker when the app is
/// backgrounded, and costs nothing when off‑screen.
///
/// See also:
///  * [QuiSkeleton] the shimmer-sweep placeholder for known-shape skeletons.
class QuiDotMatrix extends StatefulWidget {
  /// Creates a [QuiDotMatrix] that fills the given area with cycling dots.
  const QuiDotMatrix({super.key, this.width, this.height, this.radius = 0, this.color, this.dotSize, this.duration})
    : assert(width == null || width >= 0, 'width must be non-negative, but got $width.'),
      assert(height == null || height >= 0, 'height must be non-negative, but got $height.'),
      assert(radius >= 0, 'radius must be non-negative, but got $radius.');

  /// Optional scene width in logical pixels.
  ///
  /// When omitted the scene fills the available parent width.
  final double? width;

  /// Optional scene height in logical pixels.
  ///
  /// When omitted the scene fills the available parent height.
  final double? height;

  /// Uniform corner radius of the scene bounding box.
  ///
  /// Defaults to `0` (square corners).  A value larger than half the shorter
  /// side produces a pill shape.
  final double radius;

  /// Colour for all dots.
  ///
  /// When omitted, the theme's neutral solid color token is used.
  final Color? color;

  /// Size (radius) of each dot in logical pixels.
  ///
  /// Defaults to `7`.  Larger values produce bigger,
  /// fewer dots; smaller values produce finer, denser dots.
  final double? dotSize;

  /// Duration of one full diagonal sweep.
  ///
  /// The band travels from the top‑left corner to the bottom‑right corner
  /// over this period, then seamlessly wraps back.  Defaults to 2.5 seconds.
  final Duration? duration;

  @override
  State<QuiDotMatrix> createState() => _QuiDotMatrixState();
}

const double _kParticleRadius = 7;

const Duration _kDefaultDuration = Duration(milliseconds: 2500);

class _QuiDotMatrixState extends State<QuiDotMatrix> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  double get _pr => widget.dotSize ?? _kParticleRadius;
  late final AnimationController _controller;
  List<_QuiDotMatrixDot> _particles = [];
  double _previousValue = 0;
  int _loopCount = 0;
  double? _resolvedWidth;
  double? _resolvedHeight;

  void _invalidateParticles() {
    _resolvedWidth = null;
    _resolvedHeight = null;
  }

  void _syncControllerState() {
    final disabled = MediaQuery.disableAnimationsOf(context);

    if (disabled) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  void _onAnimationTick() {
    final currentValue = _controller.value;

    if (currentValue < _previousValue) {
      _loopCount++;
    }

    _previousValue = currentValue;
  }

  double get _cycleT => _controller.value + _loopCount;

  List<_QuiDotMatrixDot> _generateParticles({required double w, required double h}) {
    final r = widget.radius;

    if (w < _pr * 2 || h < _pr * 2) return [];

    return _generateContours(w: w, h: h, r: r);
  }

  List<_QuiDotMatrixDot> _generateContours({required double w, required double h, required double r}) {
    final pr = _pr;
    final cell = pr * 2 + _effectivePadding(w: w, h: h);
    final particles = <_QuiDotMatrixDot>[];

    var lastOx = 0.0;
    var lastOy = 0.0;
    var lastLw = 0.0;
    var lastLh = 0.0;

    for (var d = 0.0; ; d += cell) {
      final lw = w - 2 * (pr + d);
      final lh = h - 2 * (pr + d);
      if (lw <= pr * 2 || lh <= pr * 2) break;

      lastOx = pr + d;
      lastOy = pr + d;
      lastLw = lw;
      lastLh = lh;

      final lr = math.max<double>(0, math.min(r - pr - d, math.min(lw / 2, lh / 2)));
      final ox = pr + d;
      final oy = pr + d;

      if (lr * math.pi / 2 >= cell / 2) {
        _addRoundedLayerDots(particles: particles, ox: ox, oy: oy, lw: lw, lh: lh, lr: lr, cell: cell);
      } else {
        _addRectLayerDots(particles: particles, ox: ox, oy: oy, lw: lw, lh: lh, cell: cell);
      }
    }

    final px = w / 2;
    final py = h / 2;
    final hasCenter = particles.any((p) {
      final dx = p.position.dx - px;
      final dy = p.position.dy - py;
      return dx * dx + dy * dy <= cell * cell;
    });

    if (lastLw > 0) {
      final nH = math.max(2, (lastLw / cell).round() + 1);
      final nV = math.max(2, (lastLh / cell).round() + 1);
      if (nV > 2 || nH > 2) {
        final hStep = lastLw / (nH - 1);
        final vStep = lastLh / (nV - 1);

        for (var row = 1; row < nV - 1; row++) {
          final py2 = lastOy + row * vStep;
          for (var col = 1; col < nH - 1; col++) {
            _tryAddDot(particles: particles, px: lastOx + col * hStep, py: py2);
          }
        }
      } else if (!hasCenter) {
        _tryAddDot(particles: particles, px: px, py: py);
      }
    } else if (!hasCenter) {
      _tryAddDot(particles: particles, px: px, py: py);
    }

    return particles;
  }

  void _addRectLayerDots({
    required List<_QuiDotMatrixDot> particles,
    required double ox,
    required double oy,
    required double lw,
    required double lh,
    required double cell,
  }) {
    final nH = math.max(2, (lw / cell).round() + 1);
    final nV = math.max(2, (lh / cell).round() + 1);
    final hStep = lw / (nH - 1);
    final vStep = lh / (nV - 1);

    for (var i = 0; i < nH; i++) {
      _tryAddDot(particles: particles, px: ox + i * hStep, py: oy);
    }

    for (var i = 0; i < nH; i++) {
      _tryAddDot(particles: particles, px: ox + i * hStep, py: oy + lh);
    }

    for (var j = 1; j < nV - 1; j++) {
      _tryAddDot(particles: particles, px: ox, py: oy + j * vStep);
    }

    for (var j = 1; j < nV - 1; j++) {
      _tryAddDot(particles: particles, px: ox + lw, py: oy + j * vStep);
    }
  }

  void _addRoundedLayerDots({
    required List<_QuiDotMatrixDot> particles,
    required double ox,
    required double oy,
    required double lw,
    required double lh,
    required double lr,
    required double cell,
  }) {
    final straightH = lw - 2 * lr;
    final straightV = lh - 2 * lr;
    final arcLen = math.pi * lr / 2;

    final segments = <({double length, Offset Function(double t) point})>[
      (length: straightH, point: (t) => Offset(ox + lr + t, oy)),
      (
        length: arcLen,
        point: (t) {
          final angle = -math.pi / 2 + t / lr;
          return Offset(ox + lw - lr + lr * math.cos(angle), oy + lr + lr * math.sin(angle));
        },
      ),
      (length: straightV, point: (t) => Offset(ox + lw, oy + lr + t)),
      (
        length: arcLen,
        point: (t) {
          final angle = t / lr;
          return Offset(ox + lw - lr + lr * math.cos(angle), oy + lh - lr + lr * math.sin(angle));
        },
      ),
      (length: straightH, point: (t) => Offset(ox + lw - lr - t, oy + lh)),
      (
        length: arcLen,
        point: (t) {
          final angle = math.pi / 2 + t / lr;
          return Offset(ox + lr + lr * math.cos(angle), oy + lh - lr + lr * math.sin(angle));
        },
      ),
      (length: straightV, point: (t) => Offset(ox, oy + lh - lr - t)),
      (
        length: arcLen,
        point: (t) {
          final angle = math.pi + t / lr;
          return Offset(ox + lr + lr * math.cos(angle), oy + lr + lr * math.sin(angle));
        },
      ),
    ];

    final perimeter = segments.fold<double>(0, (sum, segment) => sum + segment.length);
    if (perimeter <= 0) return;

    final n = math.max(4, (perimeter / cell).round());
    final step = perimeter / n;

    for (var i = 0; i < n; i++) {
      var remaining = i * step;
      for (final segment in segments) {
        if (remaining <= segment.length) {
          final point = segment.point(remaining);
          _tryAddDot(particles: particles, px: point.dx, py: point.dy);
          break;
        }
        remaining -= segment.length;
      }
    }
  }

  void _tryAddDot({required List<_QuiDotMatrixDot> particles, required double px, required double py}) {
    for (final p in particles) {
      if ((p.position.dx - px).abs() < 1 && (p.position.dy - py).abs() < 1) return;
    }
    particles.add(_makeParticle(px: px, py: py, pr: _pr));
  }

  double _effectivePadding({required double w, required double h}) {
    return (math.min(w, h) / 12).clamp(10.0, 18.0);
  }

  _QuiDotMatrixDot _makeParticle({required double px, required double py, required double pr}) {
    return _QuiDotMatrixDot(position: Offset(px, py), radius: pr);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration ?? _kDefaultDuration);
    _previousValue = _controller.value;
    _controller.addListener(_onAnimationTick);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllerState();
  }

  @override
  void didUpdateWidget(covariant QuiDotMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.radius != widget.radius ||
        oldWidget.dotSize != widget.dotSize) {
      _invalidateParticles();
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration ?? _kDefaultDuration;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _syncControllerState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = widget.width ?? constraints.maxWidth;
        final h = widget.height ?? constraints.maxHeight;
        if (w != _resolvedWidth || h != _resolvedHeight) {
          _resolvedWidth = w;
          _resolvedHeight = h;
          _particles = _generateParticles(w: w, h: h);
        }

        final color = widget.color ?? context.qui.colorScheme.colors.neutral.solid;
        final disabled = MediaQuery.disableAnimationsOf(context);

        return SizedBox(
          width: w,
          height: h,
          child: RepaintBoundary(
            child: disabled
                ? CustomPaint(
                    painter: _QuiDotMatrixPainter(particles: _particles, color: color, progress: 0.5),
                    size: Size(w, h),
                  )
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _QuiDotMatrixPainter(particles: _particles, color: color, progress: _cycleT),
                        size: Size(w, h),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
