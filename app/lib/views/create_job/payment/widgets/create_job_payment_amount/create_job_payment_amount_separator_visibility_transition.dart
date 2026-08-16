part of '../../create_job_payment_view.dart';

class _CreateJobPaymentSeparatorVisibilityTransition extends StatelessWidget {
  const _CreateJobPaymentSeparatorVisibilityTransition({
    required this.animationKey,
    required this.separator,
    required this.style,
    required this.removing,
  });

  final Key animationKey;
  final String separator;
  final TextStyle style;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: animationKey,
      tween: Tween(begin: removing ? 1 : 0, end: removing ? 0 : 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : _CreateJobPaymentAmountTransition.transitionDuration,
      curve: removing ? Curves.easeInCubic : Curves.easeOutCubic,
      builder: (context, visibility, child) => Opacity(
        opacity: visibility,
        child: Transform.scale(scale: 0.7 + visibility * 0.3, child: child),
      ),
      child: Text(separator, style: style),
    );
  }
}
