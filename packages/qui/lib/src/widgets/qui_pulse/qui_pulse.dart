library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

part 'qui_pulse_step.dart';
part 'qui_pulse_painter.dart';

/// A pulse of expanding rings that emanate from behind a child widget.
///
/// `QuiPulse` wraps [child] and draws a continuous sequence of translucent
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
/// continues animating until the item is disposed. Avoid wrapping [QuiPulse] in
/// [AutomaticKeepAlive] for off-screen items, or pause it manually, to save
/// CPU/GPU on low-end devices.
///
/// ```dart
/// QuiPulse(
///   child: Icon(Icons.bolt_rounded, size: 48, color: Colors.white),
/// )
/// ```
///
/// To customize the per-ring appearance, pass [steps] with custom
/// [QuiPulseStep.color], [QuiPulseStep.borderRadius], and [QuiPulseStep.alpha]
/// values:
///
/// ```dart
/// QuiPulse(
///   steps: const [
///     QuiPulseStep(color: Color(0xFFFF4A4B), alpha: 0.6),
///     QuiPulseStep(color: Color(0xFF00A896), alpha: 0.2),
///   ],
///   child: Icon(Icons.bolt_rounded, size: 48, color: Colors.white),
/// )
/// ```
class QuiPulse extends StatefulWidget {
  /// Creates a QUI pulse widget around [child].
  ///
  /// Requires at least one [steps] entry (enforced by `assert` in debug mode).
  /// [maxScale] must be greater than `1.0` so the rings can expand beyond the
  /// child bounds.
  const QuiPulse({
    required this.child,
    super.key,
    this.steps = const [QuiPulseStep(), QuiPulseStep()],
    this.duration = const Duration(milliseconds: 1600),
    this.maxScale = 1.5,
  }) : assert(steps.length > 0, 'QuiPulse requires at least one step, but steps is empty.'),
       assert(maxScale > 1, 'maxScale must be greater than 1.0 so the pulse can expand beyond the child.');

  /// The widget rendered at the center of the pulse.
  ///
  /// The widget sizes itself to this child; the expanding rings are drawn
  /// around the child's edges and overflow beyond its bounds.
  final Widget child;

  /// Visual layers for the pulse sequence.
  ///
  /// The number of rings equals the length of this list. Each ring uses the
  /// corresponding step's [QuiPulseStep.color] (or the theme primary when
  /// `null`) and [QuiPulseStep.borderRadius]. Rings are drawn behind the child
  /// and are staggered in time so a ripple effect is always visible.
  final List<QuiPulseStep> steps;

  /// Duration of one full pulse cycle.
  final Duration duration;

  /// Maximum scale of each expanding ring relative to the child size.
  ///
  /// Must be greater than `1.0`. At this scale the ring reaches its largest
  /// extent and its alpha reaches zero (fully transparent). Defaults to `1.5`.
  final double maxScale;

  @override
  State<QuiPulse> createState() => _QuiPulseState();
}

class _QuiPulseState extends State<QuiPulse> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  void didUpdateWidget(covariant QuiPulse oldWidget) {
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
              painter: _PulseRingPainter(
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
    final primary = context.qui.colors.primary;
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

@Preview(name: 'QuiPulse', group: 'Pulse')
Widget quiPulsePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: const Color(0xFFF6F4F1),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            QuiPulse(
              child: const _PreviewDot(icon: Icons.bolt_rounded, color: Color(0xFFFF4A4B)),
            ),
            QuiPulse(
              steps: const [
                QuiPulseStep(color: Color(0xFFFF4A4B), borderRadius: BorderRadius.all(Radius.circular(24))),
                QuiPulseStep(color: Color(0xFF00A896)),
              ],
              child: const _PreviewDot(icon: Icons.restaurant_rounded, color: Color(0xFF00A896)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
