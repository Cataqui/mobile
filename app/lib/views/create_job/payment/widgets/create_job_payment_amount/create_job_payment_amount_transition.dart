part of '../../create_job_payment_view.dart';

class _CreateJobPaymentAmountTransition extends StatelessWidget {
  const _CreateJobPaymentAmountTransition({
    required this.amount,
    required this.previousAmount,
    required this.newTrailingDigit,
    required this.deletedTrailingDigit,
    required this.animationRevision,
    required this.rejectedChangeController,
  });

  static const transitionDuration = Duration(milliseconds: 140);
  static const amountHeight = 56.0;
  static const _digitEdgeFadeExtent = 25.0;
  static const _digitEdgeFadePadding = _digitEdgeFadeExtent;

  final String amount;
  final String previousAmount;
  final String? newTrailingDigit;
  final String? deletedTrailingDigit;
  final int animationRevision;
  final MotionController rejectedChangeController;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: context.mateo.colorScheme.text.primary,
      fontSize: amountHeight,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    final transition = _CreateJobPaymentAmountTransitionSpec.resolve(
      amount: amount,
      previousAmount: previousAmount,
      newTrailingDigit: newTrailingDigit,
      deletedTrailingDigit: deletedTrailingDigit,
    );
    final textMetrics = _CreateJobPaymentAmountTextMetrics(context: context, style: style);
    final amountWidth = textMetrics.width(amount);
    final horizontalOffset = (amountWidth - textMetrics.width(previousAmount)) / 2;
    final deletedDigitHorizontalOffset = deletedTrailingDigit == null
        ? 0.0
        : textMetrics.deletedDigitHorizontalOffset(
            amountWidth: amountWidth,
            previousAmount: previousAmount,
            deletedDigit: deletedTrailingDigit!,
          );
    final stationaryAmount = _CreateJobPaymentAmountSeparatorTransition(
      transition: transition,
      animationRevision: animationRevision,
      style: style,
      textMetrics: textMetrics,
    );

    return Semantics(
      key: const ValueKey('create_job_payment_amount'),
      label: amount,
      child: ExcludeSemantics(
        child: Motion(
          key: const ValueKey('create_job_payment_rejected_change'),
          controller: rejectedChangeController,
          startup: MotionStartup.skip,
          effect: const ShakeMotionEffect(
            offset: Offset(6, 0),
            duration: Duration(milliseconds: 1300),
            curve: Curves.easeOutBack,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildAmountContent(
              transition: transition,
              stationaryAmount: stationaryAmount,
              textMetrics: textMetrics,
              horizontalOffset: horizontalOffset,
              deletedDigitHorizontalOffset: deletedDigitHorizontalOffset,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountContent({
    required _CreateJobPaymentAmountTransitionSpec transition,
    required Widget stationaryAmount,
    required _CreateJobPaymentAmountTextMetrics textMetrics,
    required double horizontalOffset,
    required double deletedDigitHorizontalOffset,
  }) {
    final newTrailingDigit = transition.newTrailingDigit;
    final newTrailingDigitIndex = transition.newTrailingDigitIndex;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (transition.newTrailingDigit != null ||
            transition.deletedTrailingDigit != null ||
            transition.insertedSeparator != null ||
            transition.removedSeparator != null ||
            transition.movedSeparator != null)
          Motion(
            key: ValueKey(('create_job_payment_amount_centering', animationRevision)),
            effect: MoveMotionEffect(
              begin: Offset(horizontalOffset, 0),
              end: Offset.zero,
              duration: transitionDuration,
              curve: Curves.easeOutCubic,
            ),
            child: stationaryAmount,
          )
        else
          stationaryAmount,
        if (transition.replacedDigit case final replacedDigit?)
          KeyedSubtree(
            key: const ValueKey('create_job_payment_replaced_digit_animation'),
            child: _buildDigitMotionViewport(
              digit: replacedDigit.current,
              textMetrics: textMetrics,
              child: Stack(
                children: [
                  Motion(
                    key: ValueKey(('replaced_payment_digit', animationRevision)),
                    effect: const MoveMotionEffect(
                      begin: Offset.zero,
                      end: Offset(amountHeight, 0),
                      duration: transitionDuration,
                      curve: Curves.easeInCubic,
                    ),
                    child: Text(replacedDigit.previous, style: textMetrics.style),
                  ),
                  Motion(
                    key: ValueKey(('replacement_payment_digit', animationRevision)),
                    effect: const MoveMotionEffect(
                      begin: Offset(amountHeight, 0),
                      end: Offset.zero,
                      delay: transitionDuration,
                      duration: transitionDuration,
                      curve: Curves.easeOutCubic,
                    ),
                    child: Text(replacedDigit.current, style: textMetrics.style),
                  ),
                ],
              ),
            ),
          ),
        if (transition.replacedDigit case final replacedDigit?
            when replacedDigit.index + replacedDigit.current.length < transition.amount.length)
          Text(
            transition.amount.substring(replacedDigit.index + replacedDigit.current.length),
            style: textMetrics.style,
          ),
        if (newTrailingDigit != null)
          KeyedSubtree(
            key: const ValueKey('create_job_payment_new_digit_animation'),
            child: _buildDigitMotionViewport(
              digit: newTrailingDigit,
              textMetrics: textMetrics,
              child: Motion(
                key: ValueKey(animationRevision),
                effect: const MoveMotionEffect(
                  begin: Offset(amountHeight, 0),
                  end: Offset.zero,
                  duration: transitionDuration,
                  curve: Curves.easeOutCubic,
                ),
                child: Text(newTrailingDigit, style: textMetrics.style),
              ),
            ),
          ),
        if (newTrailingDigit != null &&
            newTrailingDigitIndex != null &&
            newTrailingDigitIndex + newTrailingDigit.length < transition.amount.length)
          Motion(
            key: ValueKey(('create_job_payment_amount_suffix_centering', animationRevision)),
            effect: MoveMotionEffect(
              begin: Offset(horizontalOffset, 0),
              end: Offset.zero,
              duration: transitionDuration,
              curve: Curves.easeOutCubic,
            ),
            child: Text(
              transition.amount.substring(newTrailingDigitIndex + newTrailingDigit.length),
              style: textMetrics.style,
            ),
          ),
        if (transition.deletedTrailingDigit != null)
          _buildDeletedDigit(
            transition: transition,
            textMetrics: textMetrics,
            horizontalOffset: deletedDigitHorizontalOffset,
          ),
      ],
    );
  }

  Widget _buildDeletedDigit({
    required _CreateJobPaymentAmountTransitionSpec transition,
    required _CreateJobPaymentAmountTextMetrics textMetrics,
    required double horizontalOffset,
  }) {
    final deletedDigit = transition.deletedTrailingDigit!;
    return SizedBox(
      width: 0,
      height: amountHeight,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0,
        maxWidth: double.infinity,
        minHeight: amountHeight,
        maxHeight: amountHeight,
        child: Transform.translate(
          offset: Offset(horizontalOffset, 0),
          child: KeyedSubtree(
            key: const ValueKey('create_job_payment_deleted_digit_animation'),
            child: _buildDigitMotionViewport(
              digit: deletedDigit,
              textMetrics: textMetrics,
              child: Motion.list(
                key: ValueKey(animationRevision),
                effects: [
                  MoveMotionEffect(
                    begin: Offset.zero,
                    end: Offset(-horizontalOffset, 0),
                    duration: transitionDuration,
                    curve: Curves.easeOutCubic,
                  ),
                  const MoveMotionEffect(
                    begin: Offset.zero,
                    end: Offset(amountHeight, 0),
                    duration: transitionDuration,
                    curve: Curves.easeInCubic,
                  ),
                ],
                child: Text(deletedDigit, style: textMetrics.style),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitMotionViewport({
    required String digit,
    required _CreateJobPaymentAmountTextMetrics textMetrics,
    required Widget child,
  }) {
    final digitWidth = textMetrics.width(digit);
    return SizedBox(
      width: digitWidth,
      height: amountHeight,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: digitWidth + _digitEdgeFadePadding,
        maxWidth: digitWidth + _digitEdgeFadePadding,
        minHeight: amountHeight,
        maxHeight: amountHeight,
        child: ClipRect(
          child: Stack(
            children: [
              child,
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: MateoEdgeFade(
                  position: MateoEdgeFadePosition.right,
                  style: MateoEdgeFadeStyle(
                    color: textMetrics.context.mateo.colorScheme.bottomSheet.background,
                    mainAxisExtent: _digitEdgeFadeExtent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
