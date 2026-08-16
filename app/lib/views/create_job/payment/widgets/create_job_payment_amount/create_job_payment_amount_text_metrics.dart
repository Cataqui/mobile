part of '../../create_job_payment_view.dart';

class _CreateJobPaymentAmountTextMetrics {
  const _CreateJobPaymentAmountTextMetrics({required this.context, required this.style});

  final BuildContext context;
  final TextStyle style;

  ({double left, double width}) character({required String text, required int index}) {
    final painter = _createPainter(text)..layout();
    final box = painter.getBoxesForSelection(TextSelection(baseOffset: index, extentOffset: index + 1)).single;
    final metrics = (left: box.left, width: box.right - box.left);
    painter.dispose();
    return metrics;
  }

  double width(String text) {
    final painter = _createPainter(text)..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  double deletedDigitHorizontalOffset({
    required double amountWidth,
    required String previousAmount,
    required String deletedDigit,
  }) {
    final deletedDigitIndex = previousAmount.lastIndexOf(deletedDigit);
    if (deletedDigitIndex < 0) return 0;

    final previousAmountPainter = _createPainter(previousAmount)..layout();
    final deletedDigitPainter = _createPainter(deletedDigit)..layout();
    final previousDigitBox = previousAmountPainter
        .getBoxesForSelection(
          TextSelection(baseOffset: deletedDigitIndex, extentOffset: deletedDigitIndex + deletedDigit.length),
        )
        .single;
    final deletedDigitBox = deletedDigitPainter
        .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: deletedDigit.length))
        .single;
    final offset = previousDigitBox.left - previousAmountPainter.width / 2 - amountWidth / 2 - deletedDigitBox.left;
    previousAmountPainter.dispose();
    deletedDigitPainter.dispose();
    return offset;
  }

  TextPainter _createPainter(String text) => TextPainter(
    text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
    textDirection: Directionality.of(context),
    maxLines: 1,
  );
}
