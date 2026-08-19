part of 'create_job_payment_view.dart';

class _OtherPaymentSection extends ConsumerWidget {
  const _OtherPaymentSection({required this.noteTextController});

  final MateoTextInputController noteTextController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    return Align(
      key: const ValueKey('create_job_other_payment_content'),
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 20),
        child: MateoTextInput(
          controller: noteTextController,
          placeholder: i18n.createJob.payment.otherSection.placeholder,
          variant: MateoTextInputVariant.quiet,
          autofocus: false,
          unfocusOnTapOutside: false,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textStyle: const TextStyle(fontSize: 20),
          maxLength: 500,
          multiline: true,
          onChanged: (paymentNote) => ref.read(createJobStateProvider.notifier).setPaymentNote(paymentNote),
        ),
      ),
    );
  }
}
