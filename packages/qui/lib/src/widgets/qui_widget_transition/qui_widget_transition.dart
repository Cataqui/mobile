library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

part '_qui_widget_transition_entry.dart';
part '_qui_widget_transition_key.dart';
part 'qui_widget_transition_enums.dart';
part 'qui_widget_transition_types.dart';

/// Transition between different widgets returned by [builder].
///
/// When the [builder] returns a widget with a different [runtimeType] or [Key],
/// the old widget animates out (via [outTransition]) while the new widget
/// animates in (via [inTransition]).
///
/// The old widget is **disposed** after the exit animation completes. Its
/// [State] is not preserved for future transitions. Navigating back to a
/// previously shown widget creates a fresh [State].
///
/// {@macro qui_widget_transition_key_requirement}
///
/// {@macro qui_widget_transition_curve_tween}
///
/// See also:
///   * [QuiWidgetTransitionAnimationBuilder], the typedef for transition
///     builders.
class QuiWidgetTransition extends StatefulWidget {
  /// Creates a QUI widget transition.
  ///
  /// The [builder] is called on every build to produce the current child.
  /// When it returns a different child (different runtime type or key), the
  /// transition starts.
  ///
  /// The [outDuration] and [inDuration] control the animation timing.
  const QuiWidgetTransition({
    required this.builder,
    required this.outDuration,
    required this.inDuration,
    super.key,
    this.outTransition,
    this.inTransition,
  });

  /// Called on every build to return the current child widget.
  ///
  /// The return value is compared to the previous child by [runtimeType] and
  /// [Key]. When either differs, a transition is triggered.
  final WidgetBuilder builder;

  /// Duration of the exit animation (old widget animating out).
  final Duration outDuration;

  /// Duration of the enter animation (new widget animating in).
  final Duration inDuration;

  /// Builder for the exit animation.
  ///
  /// Receives the old widget's child and an [Animation<double>] that goes
  /// from `0` to `1`. Wrap the child in transition widgets (e.g.,
  /// [FadeTransition]) to animate the old widget out.
  ///
  /// When `null`, the old widget is removed immediately without any exit
  /// animation.
  final QuiWidgetTransitionAnimationBuilder? outTransition;

  /// Builder for the enter animation.
  ///
  /// Receives the new widget's child and an [Animation<double>] that goes
  /// from `0` to `1`. Wrap the child in transition widgets (e.g.,
  /// [FadeTransition], [SlideTransition]) to animate the new widget in.
  ///
  /// When `null`, the new widget appears immediately without any enter
  /// animation.
  final QuiWidgetTransitionAnimationBuilder? inTransition;

  @override
  State<QuiWidgetTransition> createState() => _QuiWidgetTransitionState();
}

class _QuiWidgetTransitionState extends State<QuiWidgetTransition>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animationController;
  final Animation<double> _visibleAnim = const AlwaysStoppedAnimation<double>(1);

  _QuiWidgetTransitionEntry? _activeEntry;
  _QuiWidgetTransitionEntry? _exitingEntry;
  var _phase = _QuiWidgetTransitionPhase.idle;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this);
    _animationController.addStatusListener(_onAnimationStatus);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _animationController.stop();
      return;
    }
    if (state == AppLifecycleState.resumed) _resumeOrSkipTransition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_phase == _QuiWidgetTransitionPhase.idle) return;
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disabled) _skipToIdle();
  }

  void _resumeOrSkipTransition() {
    if (_phase == _QuiWidgetTransitionPhase.idle) return;

    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disabled) {
      _skipToIdle();
      return;
    }

    _animationController.forward();
  }

  void _skipToIdle() {
    _animationController
      ..stop()
      ..value = 0;
    _exitingEntry = null;

    setState(() => _phase = _QuiWidgetTransitionPhase.idle);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    switch (_phase) {
      case _QuiWidgetTransitionPhase.exit:
        _onExitCompleted();
      case _QuiWidgetTransitionPhase.enter:
        setState(() => _phase = _QuiWidgetTransitionPhase.idle);
      case _QuiWidgetTransitionPhase.idle:
        break;
    }
  }

  void _onExitCompleted() {
    _exitingEntry = null;
    setState(() => _phase = _QuiWidgetTransitionPhase.enter);
    _animationController
      ..duration = widget.inDuration
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final newChild = widget.builder(context);
    final newKey = _QuiWidgetTransitionKey(newChild.runtimeType, newChild.key);

    if (_phase != _QuiWidgetTransitionPhase.idle) {
      _updateDuringTransition(newChild, newKey);
    } else {
      _updateDuringIdle(newChild, newKey);
    }

    final showActive = _phase != _QuiWidgetTransitionPhase.exit;

    return RepaintBoundary(
      child: Stack(
        children: [
          if (_exitingEntry != null) Positioned.fill(key: const ValueKey('exiting'), child: _buildExitingEntry()),
          if (_activeEntry != null && showActive)
            Positioned.fill(key: const ValueKey('active'), child: _buildActiveEntry()),
        ],
      ),
    );
  }

  void _updateDuringIdle(Widget newChild, _QuiWidgetTransitionKey newKey) {
    if (_activeEntry == null) {
      _activeEntry = _QuiWidgetTransitionEntry(newChild, newKey);
      return;
    }
    if (newKey != _activeEntry!.key) {
      _exitingEntry = _activeEntry;
      _activeEntry = _QuiWidgetTransitionEntry(newChild, newKey);
      _startExitTransition();
      return;
    }
    _activeEntry!.widget = newChild;
  }

  void _updateDuringTransition(Widget newChild, _QuiWidgetTransitionKey newKey) {
    if (_activeEntry == null) return;
    if (newKey != _activeEntry!.key) return;
    _activeEntry!.widget = newChild;
  }

  Widget _buildExitingEntry() {
    final entry = _exitingEntry!;
    final wrappedChild = KeyedSubtree(key: entry.globalKey, child: entry.widget);
    final transition = widget.outTransition;

    if (transition == null) return RepaintBoundary(child: wrappedChild);
    return RepaintBoundary(child: transition(wrappedChild, _animationController));
  }

  Widget _buildActiveEntry() {
    final entry = _activeEntry!;
    final anim = _resolveActiveAnim();
    final wrappedChild = KeyedSubtree(key: entry.globalKey, child: entry.widget);
    final transition = widget.inTransition;

    if (transition == null) return RepaintBoundary(child: wrappedChild);
    return RepaintBoundary(child: transition(wrappedChild, anim));
  }

  Animation<double> _resolveActiveAnim() {
    if (_phase == _QuiWidgetTransitionPhase.enter) return _animationController;
    return _visibleAnim;
  }

  void _startExitTransition() {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations || widget.outTransition == null) {
      _exitingEntry = null;
      _tryStartEnterTransition(disableAnimations);
      return;
    }

    setState(() => _phase = _QuiWidgetTransitionPhase.exit);
    _animationController
      ..duration = widget.outDuration
      ..forward(from: 0);
  }

  void _tryStartEnterTransition(bool disableAnimations) {
    if (widget.inTransition == null || disableAnimations) {
      setState(() => _phase = _QuiWidgetTransitionPhase.idle);
      return;
    }

    setState(() => _phase = _QuiWidgetTransitionPhase.enter);
    _animationController
      ..duration = widget.inDuration
      ..forward(from: 0);
  }
}

@Preview(name: 'QuiWidgetTransition', group: 'Transitions')
Widget quiWidgetTransitionPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: const _QuiWidgetTransitionPreview(),
  );
}

class _QuiWidgetTransitionPreview extends StatefulWidget {
  const _QuiWidgetTransitionPreview();

  @override
  State<_QuiWidgetTransitionPreview> createState() => _QuiWidgetTransitionPreviewState();
}

class _QuiWidgetTransitionPreviewState extends State<_QuiWidgetTransitionPreview> {
  static const _colors = [Color(0xFFFF4A4B), Color(0xFF00A896), Color(0xFF3D5A80), Color(0xFFF4A261)];
  static const _labels = ['Vermelho', 'Verde', 'Azul', 'Laranja'];
  var _currentIndex = 0;

  Widget _buildFadeIn(Widget child, Animation<double> animation) {
    final curved = CurveTween(curve: Curves.easeOutCubic);
    return FadeTransition(opacity: curved.animate(animation), child: child);
  }

  Widget _buildFadeOut(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: Tween<double>(begin: 1, end: 0).animate(animation), child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: QuiWidgetTransition(
                  builder: (_) => KeyedSubtree(
                    key: ValueKey(_currentIndex),
                    child: ColoredBox(
                      color: _colors[_currentIndex],
                      child: Center(
                        child: Text(
                          _labels[_currentIndex],
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  outDuration: const Duration(milliseconds: 400),
                  outTransition: _buildFadeOut,
                  inDuration: const Duration(milliseconds: 600),
                  inTransition: _buildFadeIn,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PreviewButton(label: 'Anterior', onTap: () => setState(() => _currentIndex = 0)),
                const SizedBox(width: 16),
                _PreviewButton(label: 'Proximo', onTap: () => setState(() => _currentIndex = 1)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PreviewButton(label: 'Azul', onTap: () => setState(() => _currentIndex = 2)),
                const SizedBox(width: 16),
                _PreviewButton(label: 'Laranja', onTap: () => setState(() => _currentIndex = 3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.qui.colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }
}
