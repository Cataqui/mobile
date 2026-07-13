library;

import 'package:flutter/material.dart';

import 'package:qui/src/theme/qui_theme_context.dart';

part 'qui_radar_pulse_step.dart';
part 'qui_radar_pulse_painter.dart';

/// A pulse of expanding rings that emanate from behind a child widget.
///
/// `QuiRadarPulse` wraps [child] and draws a continuous sequence of translucent
/// rings that start at the child's size and expand outward to [maxScale]× while
/// fading. The rings are drawn behind the child, so the child always sits on
/// top of the pulse — the pulse appears to come from behind the child. The
/// widget does not paint any background of its own; the child is in charge of
/// its own opacity.
///
/// The widget sizes itself to the [child] (layout is transparent to the child),
/// and the rings overflow visually via `Clip.none`. The pulse respects
/// [MediaQuery.disableAnimationsOf] and renders a static snapshot when reduced
/// motion is enabled.
///
/// When placed inside a keep-alive list item that scrolls off-screen, the pulse
/// continues animating until the item is disposed. Avoid wrapping [QuiRadarPulse] in
/// [AutomaticKeepAlive] for off-screen items, or pause it manually, to save
/// CPU/GPU on low-end devices.
///
/// ```dart
/// QuiRadarPulse(
///   child: Icon(Icons.bolt_rounded, size: 48, color: Colors.white),
/// )
/// ```
///
/// To customize the per-ring appearance, pass [steps] with custom
/// [QuiRadarPulseStep.color], [QuiRadarPulseStep.borderRadius], and [QuiRadarPulseStep.alpha]
/// values:
///
/// ```dart
/// QuiRadarPulse(
///   steps: const [
///     QuiRadarPulseStep(color: Color(0xFFFF4A4B), alpha: 0.6),
///     QuiRadarPulseStep(color: Color(0xFF00A896), alpha: 0.2),
///   ],
///   child: Icon(Icons.bolt_rounded, size: 48, color: Colors.white),
/// )
/// ```
class QuiRadarPulse extends StatefulWidget {
  /// Creates a QUI pulse widget around [child].
  ///
  /// Requires at least one [steps] entry (enforced by `assert` in debug mode).
  /// [maxScale] must be greater than `1.0` so the rings can expand beyond the
  /// child bounds.
  const QuiRadarPulse({
    required this.child,
    super.key,
    this.steps = const [QuiRadarPulseStep(), QuiRadarPulseStep()],
    this.duration = const Duration(milliseconds: 1600),
    this.maxScale = 1.5,
  }) : assert(steps.length > 0, 'QuiRadarPulse requires at least one step, but steps is empty.'),
       assert(maxScale > 1, 'maxScale must be greater than 1.0 so the pulse can expand beyond the child.');

  /// The widget rendered at the center of the pulse.
  ///
  /// The widget sizes itself to this child; the expanding rings are drawn
  /// around the child's edges and overflow beyond its bounds.
  final Widget child;

  /// Visual layers for the pulse sequence.
  ///
  /// The number of rings equals the length of this list. Each ring uses the
  /// corresponding step's [QuiRadarPulseStep.color] (or the theme primary when
  /// `null`) and [QuiRadarPulseStep.borderRadius]. Rings are drawn behind the child
  /// and are staggered in time so a ripple effect is always visible.
  final List<QuiRadarPulseStep> steps;

  /// Duration of one full pulse cycle.
  final Duration duration;

  /// Maximum scale of each expanding ring relative to the child size.
  ///
  /// Must be greater than `1.0`. At this scale the ring reaches its largest
  /// extent and its alpha reaches zero (fully transparent). Defaults to `1.5`.
  final double maxScale;

  @override
  State<QuiRadarPulse> createState() => _QuiRadarPulseState();
}

class _QuiRadarPulseState extends State<QuiRadarPulse> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _syncControllerState();
  }

  @override
  void didUpdateWidget(covariant QuiRadarPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) _controller.duration = widget.duration;
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

  void _syncControllerState() {
    final disabled = MediaQuery.disableAnimationsOf(context);

    if (disabled) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  Widget _buildRings(
    Color primary, {
    required bool animated,
    required double progress,
    Widget? staticChild,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _RadarPulseRingPainter(
                steps: widget.steps,
                progress: progress,
                animated: animated,
                maxScale: widget.maxScale,
                primary: primary,
              ),
            ),
          ),
        ),
        staticChild ?? RepaintBoundary(child: widget.child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.qui.colorScheme.colors.primary.solid;
    final disabled = MediaQuery.disableAnimationsOf(context);

    if (disabled) return _buildRings(primary, animated: false, progress: 0);

    return AnimatedBuilder(
      animation: _controller,
      child: RepaintBoundary(child: widget.child),
      builder: (context, staticChild) =>
          _buildRings(primary, animated: true, progress: _controller.value, staticChild: staticChild),
    );
  }
}
