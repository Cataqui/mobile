part of '../../create_job_payment_view.dart';

class _CreateJobPaymentAmountMultipleSeparatorTransition extends StatelessWidget {
  const _CreateJobPaymentAmountMultipleSeparatorTransition({
    required this.amount,
    required this.previousAmount,
    required this.animationRevision,
    required this.style,
    required this.textMetrics,
  });

  final String amount;
  final String previousAmount;
  final int animationRevision;
  final TextStyle style;
  final _CreateJobPaymentAmountTextMetrics textMetrics;

  @override
  Widget build(BuildContext context) {
    final matching = _matchPreviousCharacters();
    return SizedBox(
      width: textMetrics.width(amount),
      height: _CreateJobPaymentAmountTransition.amountHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._buildCurrentCharacters(
            currentSeparatorIndices: matching.currentSeparatorIndices,
            previousIndexByCurrentIndex: matching.previousIndexByCurrentIndex,
          ),
          ..._buildRemovedSeparators(matching.unmatchedPreviousSeparatorIndices),
        ],
      ),
    );
  }

  List<Widget> _buildCurrentCharacters({
    required List<int> currentSeparatorIndices,
    required Map<int, int> previousIndexByCurrentIndex,
  }) {
    final children = <Widget>[];
    var newSeparatorKeyUsed = false;
    var existingSeparatorKeyUsed = false;
    for (var index = 0; index < amount.length; index += 1) {
      final metrics = textMetrics.character(text: amount, index: index);
      final previousIndex = previousIndexByCurrentIndex[index];
      final isSeparator = currentSeparatorIndices.contains(index);
      Widget character = Text(amount[index], style: style);
      if (previousIndex == null && isSeparator) {
        character = _CreateJobPaymentSeparatorVisibilityTransition(
          animationKey: newSeparatorKeyUsed
              ? ValueKey(('create_job_payment_multi_separator_new_animation', index))
              : const ValueKey('create_job_payment_multi_separator_new_animation'),
          separator: amount[index],
          style: style,
          removing: false,
        );
        newSeparatorKeyUsed = true;
      } else if (previousIndex != null) {
        final previousMetrics = textMetrics.character(text: previousAmount, index: previousIndex);
        character = Motion(
          key: isSeparator && !existingSeparatorKeyUsed
              ? const ValueKey('create_job_payment_multi_separator_existing_animation')
              : ValueKey(('create_job_payment_multi_character_animation', index)),
          effect: MoveMotionEffect(
            begin: Offset(previousMetrics.left - metrics.left, 0),
            end: Offset.zero,
            duration: _CreateJobPaymentAmountTransition.transitionDuration,
            curve: Curves.easeOutCubic,
          ),
          child: character,
        );
        if (isSeparator) existingSeparatorKeyUsed = true;
      }
      children.add(Positioned(left: metrics.left, top: 0, child: character));
    }
    return children;
  }

  List<Widget> _buildRemovedSeparators(List<int> unmatchedPreviousSeparatorIndices) {
    final children = <Widget>[];
    var firstRemovedSeparator = true;
    for (final previousIndex in unmatchedPreviousSeparatorIndices) {
      children.add(
        Positioned(
          left: textMetrics.character(text: previousAmount, index: previousIndex).left,
          top: 0,
          child: _CreateJobPaymentSeparatorVisibilityTransition(
            animationKey: firstRemovedSeparator
                ? const ValueKey('create_job_payment_multi_separator_removed_animation')
                : ValueKey(('create_job_payment_multi_separator_removed_animation', previousIndex)),
            separator: previousAmount[previousIndex],
            style: style,
            removing: true,
          ),
        ),
      );
      firstRemovedSeparator = false;
    }
    return children;
  }

  ({
    List<int> currentSeparatorIndices,
    Map<int, int> previousIndexByCurrentIndex,
    List<int> unmatchedPreviousSeparatorIndices,
  })
  _matchPreviousCharacters() {
    final currentDigitIndices = _digitIndices(amount);
    final previousDigitIndices = _digitIndices(previousAmount);
    final currentSeparatorIndices = _CreateJobPaymentAmountTransitionSpec.nonDigitIndicesAfterFirstDigit(amount);
    final previousSeparatorIndices = _CreateJobPaymentAmountTransitionSpec.nonDigitIndicesAfterFirstDigit(
      previousAmount,
    );
    final previousIndexByCurrentIndex = <int, int>{};
    for (var index = 0; index < math.min(currentDigitIndices.length, previousDigitIndices.length); index += 1) {
      previousIndexByCurrentIndex[currentDigitIndices[index]] = previousDigitIndices[index];
    }

    final unmatchedPreviousSeparatorIndices = previousSeparatorIndices.toList();
    for (final currentIndex in currentSeparatorIndices.reversed) {
      final matchingPreviousListIndex = unmatchedPreviousSeparatorIndices.lastIndexWhere(
        (previousIndex) => previousAmount[previousIndex] == amount[currentIndex],
      );
      if (matchingPreviousListIndex < 0) continue;
      previousIndexByCurrentIndex[currentIndex] = unmatchedPreviousSeparatorIndices.removeAt(matchingPreviousListIndex);
    }

    final firstCurrentDigitIndex = currentDigitIndices.firstOrNull ?? amount.length;
    final firstPreviousDigitIndex = previousDigitIndices.firstOrNull ?? previousAmount.length;
    for (var index = 0; index < math.min(firstCurrentDigitIndex, firstPreviousDigitIndex); index += 1) {
      if (amount[index] == previousAmount[index]) {
        previousIndexByCurrentIndex[index] = index;
      }
    }
    return (
      currentSeparatorIndices: currentSeparatorIndices,
      previousIndexByCurrentIndex: previousIndexByCurrentIndex,
      unmatchedPreviousSeparatorIndices: unmatchedPreviousSeparatorIndices,
    );
  }

  List<int> _digitIndices(String text) => [
    for (var index = 0; index < text.length; index += 1)
      if (!_CreateJobPaymentAmountTransitionSpec.isNonDigit(text[index])) index,
  ];
}
