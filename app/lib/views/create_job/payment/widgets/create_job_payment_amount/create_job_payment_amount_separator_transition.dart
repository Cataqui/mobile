part of '../../create_job_payment_view.dart';

class _CreateJobPaymentAmountSeparatorTransition extends StatelessWidget {
  const _CreateJobPaymentAmountSeparatorTransition({
    required this.transition,
    required this.animationRevision,
    required this.style,
    required this.textMetrics,
  });

  final _CreateJobPaymentAmountTransitionSpec transition;
  final int animationRevision;
  final TextStyle style;
  final _CreateJobPaymentAmountTextMetrics textMetrics;

  @override
  Widget build(BuildContext context) {
    if (transition.useMultipleSeparatorTransition) {
      return _CreateJobPaymentAmountMultipleSeparatorTransition(
        amount: transition.stationaryAmount,
        previousAmount: transition.separatorPreviousAmount,
        animationRevision: animationRevision,
        style: style,
        textMetrics: textMetrics,
      );
    }
    if (transition.insertedSeparator case final insertedSeparator?) {
      return _buildSeparatorInsertion(insertedSeparator);
    }
    if (transition.removedSeparator case final removedSeparator?) {
      return _buildSeparatorRemoval(removedSeparator);
    }
    if (transition.movedSeparator case final movedSeparator?) {
      return _buildSeparatorMovement(movedSeparator);
    }
    return Text(transition.stationaryAmount, style: style);
  }

  Widget _buildSeparatorInsertion(({int index, String value}) insertedSeparator) {
    final separatorWidth = textMetrics.width(insertedSeparator.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(transition.stationaryAmount.substring(0, insertedSeparator.index), style: style),
        KeyedSubtree(
          key: const ValueKey('create_job_payment_new_separator_animation'),
          child: _CreateJobPaymentSeparatorVisibilityTransition(
            animationKey: ValueKey(animationRevision),
            separator: insertedSeparator.value,
            style: style,
            removing: false,
          ),
        ),
        KeyedSubtree(
          key: const ValueKey('create_job_payment_separator_right_group_animation'),
          child: Motion(
            key: ValueKey(animationRevision),
            effect: MoveMotionEffect(
              begin: Offset(-separatorWidth, 0),
              end: Offset.zero,
              duration: _CreateJobPaymentAmountTransition.transitionDuration,
              curve: Curves.easeOutCubic,
            ),
            child: Text(
              transition.stationaryAmount.substring(insertedSeparator.index + insertedSeparator.value.length),
              style: style,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparatorRemoval(({int index, String value}) removedSeparator) {
    final separatorWidth = textMetrics.width(removedSeparator.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(transition.stationaryAmount.substring(0, removedSeparator.index), style: style),
        SizedBox(
          width: 0,
          height: _CreateJobPaymentAmountTransition.amountHeight,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: separatorWidth,
            maxWidth: separatorWidth,
            minHeight: _CreateJobPaymentAmountTransition.amountHeight,
            maxHeight: _CreateJobPaymentAmountTransition.amountHeight,
            child: _CreateJobPaymentSeparatorVisibilityTransition(
              animationKey: const ValueKey('create_job_payment_removed_separator_animation'),
              separator: removedSeparator.value,
              style: style,
              removing: true,
            ),
          ),
        ),
        KeyedSubtree(
          key: const ValueKey('create_job_payment_removed_separator_right_group_animation'),
          child: Motion(
            key: ValueKey(animationRevision),
            effect: MoveMotionEffect(
              begin: Offset(separatorWidth, 0),
              end: Offset.zero,
              duration: _CreateJobPaymentAmountTransition.transitionDuration,
              curve: Curves.easeInCubic,
            ),
            child: Text(transition.stationaryAmount.substring(removedSeparator.index), style: style),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparatorMovement(({int previousIndex, int currentIndex, String value}) movedSeparator) {
    final separatorWidth = textMetrics.width(movedSeparator.value);
    final movingRight = movedSeparator.currentIndex > movedSeparator.previousIndex;
    final crossedGroupStart = movingRight
        ? movedSeparator.previousIndex
        : movedSeparator.currentIndex + movedSeparator.value.length;
    final crossedGroupEnd = movingRight
        ? movedSeparator.currentIndex
        : movedSeparator.previousIndex + movedSeparator.value.length;
    final crossedGroup = transition.stationaryAmount.substring(crossedGroupStart, crossedGroupEnd);
    final crossedGroupWidth = textMetrics.width(crossedGroup);
    final prefixEnd = movingRight ? movedSeparator.previousIndex : movedSeparator.currentIndex;
    final suffixStart = movingRight
        ? movedSeparator.currentIndex + movedSeparator.value.length
        : movedSeparator.previousIndex + movedSeparator.value.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(transition.stationaryAmount.substring(0, prefixEnd), style: style),
        if (!movingRight) _buildMovedSeparator(separator: movedSeparator.value, horizontalOffset: crossedGroupWidth),
        KeyedSubtree(
          key: const ValueKey('create_job_payment_moved_separator_crossed_group_animation'),
          child: Motion(
            key: ValueKey(animationRevision),
            effect: MoveMotionEffect(
              begin: Offset(movingRight ? separatorWidth : -separatorWidth, 0),
              end: Offset.zero,
              duration: _CreateJobPaymentAmountTransition.transitionDuration,
              curve: Curves.easeOutCubic,
            ),
            child: Text(crossedGroup, style: style),
          ),
        ),
        if (movingRight) _buildMovedSeparator(separator: movedSeparator.value, horizontalOffset: -crossedGroupWidth),
        KeyedSubtree(
          key: const ValueKey('create_job_payment_moved_separator_right_group_animation'),
          child: Motion(
            key: ValueKey(animationRevision),
            effect: MoveMotionEffect(
              begin: Offset(movingRight ? -separatorWidth : separatorWidth, 0),
              end: Offset.zero,
              duration: _CreateJobPaymentAmountTransition.transitionDuration,
              curve: Curves.easeOutCubic,
            ),
            child: Text(transition.stationaryAmount.substring(suffixStart), style: style),
          ),
        ),
      ],
    );
  }

  Widget _buildMovedSeparator({required String separator, required double horizontalOffset}) {
    return Motion(
      key: ValueKey(('create_job_payment_moved_separator', animationRevision)),
      effect: MoveMotionEffect(
        begin: Offset(horizontalOffset, 0),
        end: Offset.zero,
        duration: _CreateJobPaymentAmountTransition.transitionDuration,
        curve: Curves.easeOutCubic,
      ),
      child: Text(separator, key: const ValueKey('create_job_payment_moved_separator_new_position'), style: style),
    );
  }
}
