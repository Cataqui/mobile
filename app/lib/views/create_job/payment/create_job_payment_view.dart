import 'dart:math' as math;

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/enums/create_job_morph_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'widgets/create_job_payment_amount/create_job_payment_amount.dart';
part 'widgets/create_job_payment_amount/create_job_payment_amount_multiple_separator_transition.dart';
part 'widgets/create_job_payment_amount/create_job_payment_amount_separator_transition.dart';
part 'widgets/create_job_payment_amount/create_job_payment_amount_separator_visibility_transition.dart';
part 'widgets/create_job_payment_amount/create_job_payment_amount_text_metrics.dart';
part 'widgets/create_job_payment_amount/create_job_payment_amount_transition.dart';
part 'widgets/create_job_payment_amount/create_job_payment_amount_transition_spec.dart';

class CreateJobPaymentView extends ConsumerStatefulWidget {
  const CreateJobPaymentView({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<CreateJobPaymentView> createState() => _CreateJobPaymentViewState();
}

class _CreateJobPaymentViewState extends ConsumerState<CreateJobPaymentView> {
  late final MateoTextInputController _amountTextController;
  late final MotionController _shakeAmountMotionController;

  void _setAmountText() {
    ref.read(createJobStateProvider.notifier).setPaymentAmount(_amountTextController.text);
  }

  @override
  void initState() {
    super.initState();
    _amountTextController = MateoTextInputController(text: ref.read(createJobStateProvider).paymentAmount)
      ..addListener(_setAmountText);

    _shakeAmountMotionController = MotionController();
  }

  @override
  void dispose() {
    _amountTextController
      ..removeListener(_setAmountText)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    ref.watch(createJobStateProvider.select((state) => state.jobId));
    final mediaQueryData = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: MediaQuery(
        data: mediaQueryData.copyWith(
          padding: mediaQueryData.padding.copyWith(bottom: mediaQueryData.viewPadding.bottom),
          viewInsets: mediaQueryData.viewInsets.copyWith(bottom: 0),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Morph(
                tag: CreateJobMorphTag.surface,
                curve: Curves.fastOutSlowIn,
                switchTransition: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Container(
                  key: const ValueKey('create_job_payment_surface'),
                  decoration: BoxDecoration(
                    color: context.mateo.colorScheme.background,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: SafeArea(
                    child: Column(
                      key: const ValueKey('create_job_payment_view_content'),
                      children: [
                        SizedBox(
                          height: 53,
                          child: Center(
                            child: Text(
                              i18n.createJob.payment.title,
                              key: const ValueKey('create_job_payment_title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.mateo.colorScheme.text.primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 64),
                        _CreateJobPaymentAmount(
                          amountController: _amountTextController,
                          shakeMotionController: _shakeAmountMotionController,
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Morph(
                              tag: CreateJobMorphTag.continueButton,
                              child: MateoFloatingActionButton(
                                key: const ValueKey('create_job_payment_continue_button'),
                                onPressed: () {},
                                semanticLabel: i18n.createJob.continueButtonSemanticLabel,
                                backgroundColor: context.mateo.palette.primary[9],
                                foregroundColor: context.mateo.palette.primary[1],
                                borderSide: BorderSide.none,
                                size: 53,
                                iconSize: 22,
                                iconBuilder: (state) => MateoIcon.arrowRight(
                                  key: const ValueKey('create_job_continue_icon'),
                                  width: state.iconSize,
                                  height: state.iconSize,
                                  color: state.foregroundColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        MorphDescendant(
                          flightBehavior: MorphDescendantFlightBehavior.snapshot,
                          child: MateoNumericKeypad(
                            key: const ValueKey('create_job_payment_keypad'),
                            controllers: [_amountTextController],
                            variant: MateoNumericKeypadVariant.monetary,
                            onChangeRejected: _shakeAmountMotionController.play,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Align(
                alignment: AlignmentGeometry.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: SizedBox(
                    height: 53,
                    child: Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Morph(
                        tag: CreateJobMorphTag.navigationButton,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: MateoFloatingActionButton(
                          key: const ValueKey('create_job_payment_back_button'),
                          onPressed: context.pop,
                          semanticLabel: i18n.createJob.payment.backButtonSemanticLabel,
                          backgroundColor: context.mateo.colorScheme.bottomSheet.background,
                          foregroundColor: context.mateo.colorScheme.text.primary,
                          borderSide: BorderSide.none,
                          size: 44,
                          tapTargetSize: 48,
                          iconSize: 20,
                          iconBuilder: (state) => MateoIcon.arrowLeft(
                            width: state.iconSize,
                            height: state.iconSize,
                            color: state.foregroundColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
