part of 'create_job_payment_view.dart';

class _OtherPaymentSection extends ConsumerWidget {
  const _OtherPaymentSection({required this.noteTextController});

  final MateoTextController noteTextController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);
    final viewMediaQueryData = MediaQueryData.fromView(View.of(context));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: MateoTextArea(
        key: const ValueKey('create_job_other_payment_content'),
        controller: noteTextController,
        placeholder: i18n.createJob.payment.otherSection.placeholder,
        autofocus: false,
        unfocusOnTapOutside: false,
        textStyle: const TextStyle(fontSize: 20),
        maxLength: 500,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 20, bottom: 20),
        bottomEdgeFadeStyle: const MateoEdgeFadeStyle(mainAxisExtent: 70),
        topEdgeFadeStyle: const MateoEdgeFadeStyle(mainAxisExtent: 90),
        protectedBottomInset:
            math.max(0, viewMediaQueryData.viewInsets.bottom - viewMediaQueryData.viewPadding.bottom) + 20,
        onChanged: (paymentNote) => ref.read(createJobStateProvider.notifier).setPaymentNote(paymentNote),
      ),
    );
  }
}
