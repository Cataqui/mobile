part of 'create_job_payment_view.dart';

class _OtherPaymentSection extends ConsumerStatefulWidget {
  const _OtherPaymentSection();

  @override
  ConsumerState<_OtherPaymentSection> createState() => _OtherPaymentSectionState();
}

class _OtherPaymentSectionState extends ConsumerState<_OtherPaymentSection> {
  late final MateoTextInputController _paymentNoteController;

  void _setPaymentNote(String paymentNote) {
    ref.read(createJobStateProvider.notifier).setPaymentNote(paymentNote);
  }

  @override
  void initState() {
    super.initState();
    _paymentNoteController = MateoTextInputController(text: ref.read(createJobStateProvider).paymentNote);
  }

  @override
  void dispose() {
    _paymentNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return Align(
      key: const ValueKey('create_job_other_payment_content'),
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 20),
        child: MateoTextInput(
          controller: _paymentNoteController,
          placeholder: i18n.createJob.payment.otherSection.placeholder,
          variant: MateoTextInputVariant.quiet,
          autofocus: true,
          unfocusOnTapOutside: false,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textStyle: const TextStyle(fontSize: 20),
          maxLength: 500,
          multiline: true,
          onChanged: _setPaymentNote,
        ),
      ),
    );
  }
}
