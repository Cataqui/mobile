part of 'create_job_payment_amount_text.dart';

class CreateJobPaymentAmountTextMetrics {
  const CreateJobPaymentAmountTextMetrics({required this.context, required this.style});

  final BuildContext context;
  final TextStyle style;

  double get lineHeight => style.fontSize!;

  double amountWidth(String text) => _CreateJobPaymentAmountTextLayout.resolve(text: text, widthOf: width).width;

  double width(String text) {
    final painter = _createPainter(text)..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  TextPainter _createPainter(String text) => TextPainter(
    text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
    textDirection: Directionality.of(context),
    maxLines: 1,
  );
}
