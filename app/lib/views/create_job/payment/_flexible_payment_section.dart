part of 'create_job_payment_view.dart';

class _FlexiblePaymentSection extends ConsumerWidget {
  const _FlexiblePaymentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: SizedBox(
        key: ValueKey<Object>(('create_job_empty_payment_content', JobPaymentType.flexible)),
        child: Text('A Combinar'),
      ),
    );
  }
}
