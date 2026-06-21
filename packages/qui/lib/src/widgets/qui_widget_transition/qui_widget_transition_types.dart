part of 'qui_widget_transition.dart';

/// Signature for transition builders used by [QuiWidgetTransition].
///
/// The [child] parameter is the widget being transitioned. The [animation]
/// goes from `0` to `1` over the corresponding animation duration.
///
/// {@template qui_widget_transition_curve_tween}
/// Prefer [CurveTween] over [CurvedAnimation] to avoid adding persistent
/// listeners to the [AnimationController]:
///
/// ```dart
/// inTransition: (child, animation) {
///   final curved = CurveTween(curve: Curves.easeOutCubic);
///   return FadeTransition(
///     opacity: curved.animate(animation),
///     child: child,
///   );
/// },
/// ```
/// {@endtemplate}
///
/// Wrap expensive children in [RepaintBoundary] to prevent repainting when
/// the transition animation changes:
///
/// ```dart
/// outTransition: (child, controller) => FadeTransition(
///   opacity: Tween<double>(begin: 1, end: 0).animate(controller),
///   child: RepaintBoundary(child: child),
/// ),
/// ```
typedef QuiWidgetTransitionAnimationBuilder = Widget Function(
  Widget child,
  Animation<double> animation,
);
