part of 'create_job_payment_view.dart';

class _FlexiblePaymentSection extends ConsumerWidget {
  const _FlexiblePaymentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    return Center(
      key: const ValueKey('create_job_flexible_payment_content'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const FlexiblePaymentValuesWheel(),
          const SizedBox(height: 10),
          Text(
            i18n.createJob.payment.flexibleSection.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          FractionallySizedBox(
            widthFactor: .6,
            child: Text(
              i18n.createJob.payment.flexibleSection.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: context.mateo.colorScheme.text.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
