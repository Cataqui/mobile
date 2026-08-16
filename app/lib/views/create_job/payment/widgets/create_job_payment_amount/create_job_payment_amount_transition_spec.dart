part of '../../create_job_payment_view.dart';

class _CreateJobPaymentAmountTransitionSpec {
  const _CreateJobPaymentAmountTransitionSpec._({
    required this.amount,
    required this.stationaryAmount,
    required this.separatorPreviousAmount,
    required this.newTrailingDigit,
    required this.deletedTrailingDigit,
    required this.newTrailingDigitIndex,
    required this.replacedDigit,
    required this.insertedSeparator,
    required this.removedSeparator,
    required this.movedSeparator,
    required this.useMultipleSeparatorTransition,
  });

  factory _CreateJobPaymentAmountTransitionSpec.resolve({
    required String amount,
    required String previousAmount,
    required String? newTrailingDigit,
    required String? deletedTrailingDigit,
  }) {
    final newTrailingDigitIndex = newTrailingDigit == null ? null : amount.lastIndexOf(newTrailingDigit);
    final amountWithoutNewTrailingDigit = newTrailingDigitIndex == null
        ? amount
        : amount.replaceRange(newTrailingDigitIndex, newTrailingDigitIndex + newTrailingDigit!.length, '');
    final detectedInsertedSeparator = _insertedNonDigit(previousAmount, amountWithoutNewTrailingDigit);
    final insertedSeparator =
        detectedInsertedSeparator != null &&
            (newTrailingDigitIndex == null || detectedInsertedSeparator.index < newTrailingDigitIndex)
        ? detectedInsertedSeparator
        : null;
    final deletedTrailingDigitIndex = deletedTrailingDigit == null
        ? null
        : previousAmount.lastIndexOf(deletedTrailingDigit);
    final previousAmountWithoutDeletedTrailingDigit = deletedTrailingDigitIndex == null
        ? previousAmount
        : previousAmount.replaceRange(
            deletedTrailingDigitIndex,
            deletedTrailingDigitIndex + deletedTrailingDigit!.length,
            '',
          );
    final removedSeparator = deletedTrailingDigitIndex == null
        ? null
        : _insertedNonDigit(amount, previousAmountWithoutDeletedTrailingDigit);
    final separatorPreviousAmount = deletedTrailingDigitIndex == null
        ? previousAmount
        : previousAmountWithoutDeletedTrailingDigit;
    final previousSeparatorIndices = _nonDigitIndicesAfterFirstDigit(separatorPreviousAmount);
    final currentSeparatorIndices = _nonDigitIndicesAfterFirstDigit(amountWithoutNewTrailingDigit);
    var separatorLayoutChanged = previousSeparatorIndices.length != currentSeparatorIndices.length;
    for (var index = 0; !separatorLayoutChanged && index < previousSeparatorIndices.length; index += 1) {
      final previousIndex = previousSeparatorIndices[index];
      final currentIndex = currentSeparatorIndices[index];
      separatorLayoutChanged =
          previousIndex != currentIndex ||
          separatorPreviousAmount[previousIndex] != amountWithoutNewTrailingDigit[currentIndex];
    }
    final movedSeparator = insertedSeparator == null && removedSeparator == null
        ? _movedNonDigit(separatorPreviousAmount, amountWithoutNewTrailingDigit)
        : null;
    final replacedDigit = _replacedDigit(previousAmount, amount);

    return _CreateJobPaymentAmountTransitionSpec._(
      amount: amount,
      stationaryAmount: newTrailingDigitIndex != null
          ? amount.substring(0, newTrailingDigitIndex)
          : replacedDigit == null
          ? amount
          : amount.substring(0, replacedDigit.index),
      separatorPreviousAmount: separatorPreviousAmount,
      newTrailingDigit: newTrailingDigit,
      deletedTrailingDigit: deletedTrailingDigit,
      newTrailingDigitIndex: newTrailingDigitIndex,
      replacedDigit: replacedDigit,
      insertedSeparator: insertedSeparator,
      removedSeparator: removedSeparator,
      movedSeparator: movedSeparator,
      useMultipleSeparatorTransition:
          separatorLayoutChanged && (previousSeparatorIndices.length > 1 || currentSeparatorIndices.length > 1),
    );
  }

  final String amount;
  final String stationaryAmount;
  final String separatorPreviousAmount;
  final String? newTrailingDigit;
  final String? deletedTrailingDigit;
  final int? newTrailingDigitIndex;
  final ({int index, String previous, String current})? replacedDigit;
  final ({int index, String value})? insertedSeparator;
  final ({int index, String value})? removedSeparator;
  final ({int previousIndex, int currentIndex, String value})? movedSeparator;
  final bool useMultipleSeparatorTransition;

  static String digitsOf(String text) => text.replaceAll(_nonDigitPattern, '');

  static bool isNonDigit(String character) => _nonDigitPattern.hasMatch(character);

  static ({int index, String previous, String current})? findReplacedDigit(String previousText, String currentText) {
    return _replacedDigit(previousText, currentText);
  }

  static List<int> nonDigitIndicesAfterFirstDigit(String text) => _nonDigitIndicesAfterFirstDigit(text);

  static final RegExp _nonDigitPattern = RegExp(r'\D');

  static ({int index, String value})? _insertedNonDigit(String previousText, String currentText) {
    if (currentText.length != previousText.length + 1) return null;

    for (var index = 0; index < currentText.length; index += 1) {
      final value = currentText[index];
      if (!isNonDigit(value)) continue;
      if (currentText.replaceRange(index, index + 1, '') != previousText) continue;
      return (index: index, value: value);
    }

    return null;
  }

  static ({int index, String previous, String current})? _replacedDigit(String previousText, String currentText) {
    if (previousText.length != currentText.length) return null;

    ({int index, String previous, String current})? replacement;
    for (var index = 0; index < currentText.length; index += 1) {
      final previous = previousText[index];
      final current = currentText[index];
      if (previous == current) continue;
      if (replacement != null || isNonDigit(previous) || isNonDigit(current)) return null;

      replacement = (index: index, previous: previous, current: current);
    }
    return replacement;
  }

  static ({int previousIndex, int currentIndex, String value})? _movedNonDigit(
    String previousText,
    String currentText,
  ) {
    final previousNonDigits = _indexedNonDigits(previousText);
    final currentNonDigits = _indexedNonDigits(currentText);
    if (previousNonDigits.length != currentNonDigits.length) return null;

    for (var index = previousNonDigits.length - 1; index >= 0; index -= 1) {
      final previous = previousNonDigits[index];
      final current = currentNonDigits[index];
      if (previous.value != current.value || previous.index == current.index) continue;
      return (previousIndex: previous.index, currentIndex: current.index, value: current.value);
    }

    return null;
  }

  static List<({int index, String value})> _indexedNonDigits(String text) => [
    for (var index = 0; index < text.length; index += 1)
      if (isNonDigit(text[index])) (index: index, value: text[index]),
  ];

  static List<int> _nonDigitIndicesAfterFirstDigit(String text) {
    final firstDigitIndex = text.indexOf(RegExp(r'\d'));
    if (firstDigitIndex < 0) return const [];

    return [
      for (var index = firstDigitIndex + 1; index < text.length; index += 1)
        if (isNonDigit(text[index])) index,
    ];
  }
}
