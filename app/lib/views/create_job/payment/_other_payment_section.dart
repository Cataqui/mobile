part of 'create_job_payment_view.dart';

class _OtherPaymentSection extends ConsumerWidget {
  const _OtherPaymentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink(key: ValueKey<Object>(('create_job_empty_payment_content', JobPaymentType.other)));
  }
}
