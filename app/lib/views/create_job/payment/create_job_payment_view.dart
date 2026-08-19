import 'dart:math' as math;

import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/icons.g.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/enums/create_job_morph_tag.dart';
import 'package:cataqui_app/views/create_job/payment/widgets/create_job_payment_amount_text/create_job_payment_amount_text.dart';
import 'package:cataqui_app/views/create_job/payment/widgets/flexible_payment_values_wheel/flexible_payment_values_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part '_fixed_payment_section.dart';
part '_flexible_payment_section.dart';
part '_other_payment_section.dart';
part '_range_payment_section.dart';

class CreateJobPaymentView extends ConsumerStatefulWidget {
  const CreateJobPaymentView({required this.jobId, super.key});

  static Future<void> precacheImages(BuildContext context) async {
    await Future.wait([
      $IconsCache.precachePadlock(context, height: _padlockIconHeight),
      $IconsCache.precacheBidirecionalHorizontalArrow(context, height: _rangeIconHeight),
      $IconsCache.precacheHandshake(context, height: _handshakeIconHeight),
      $IconsCache.precachePencil(context, height: _pencilIconHeight),
    ]);
  }

  static const _padlockIconHeight = 27.0;
  static const _rangeIconHeight = 27.0;
  static const _handshakeIconHeight = 32.0;
  static const _pencilIconHeight = 25.0;

  final String jobId;

  @override
  ConsumerState<CreateJobPaymentView> createState() => _CreateJobPaymentViewState();
}

class _CreateJobPaymentViewState extends ConsumerState<CreateJobPaymentView> {
  void _setPaymentType(JobPaymentType paymentType) {
    ref.read(createJobStateProvider.notifier).setPaymentType(paymentType);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    ref.watch(createJobStateProvider.select((state) => state.jobId));
    final paymentType = ref.watch(createJobStateProvider.select((state) => state.paymentType));
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
                switchThreshold: 0.2,
                child: Container(
                  key: const ValueKey('create_job_payment_surface'),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: context.mateo.colorScheme.background,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: MorphDescendant(
                    flightBehavior: MorphDescendantFlightBehavior.snapshot,
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
                          MateoSelect(
                            key: const ValueKey('create_job_payment_type_selector'),
                            items: [
                              MateoSelectOption(
                                value: JobPaymentType.fixed,
                                title: i18n.createJob.payment.typeSelector.fixed.title,
                                description: i18n.createJob.payment.typeSelector.fixed.description,
                                iconBuilder: (_) => $Icons.padlock(height: CreateJobPaymentView._padlockIconHeight),
                                onPressed: () => _setPaymentType(JobPaymentType.fixed),
                              ),
                              MateoSelectOption(
                                value: JobPaymentType.range,
                                title: i18n.createJob.payment.typeSelector.range.title,
                                description: i18n.createJob.payment.typeSelector.range.description,
                                iconBuilder: (_) =>
                                    $Icons.bidirecionalHorizontalArrow(height: CreateJobPaymentView._rangeIconHeight),

                                onPressed: () => _setPaymentType(JobPaymentType.range),
                              ),
                              MateoSelectOption(
                                value: JobPaymentType.flexible,
                                title: i18n.createJob.payment.typeSelector.flexible.title,
                                description: i18n.createJob.payment.typeSelector.flexible.description,
                                iconBuilder: (_) {
                                  return $Icons.handshake(height: CreateJobPaymentView._handshakeIconHeight);
                                },

                                onPressed: () => _setPaymentType(JobPaymentType.flexible),
                              ),
                              MateoSelectOption(
                                value: JobPaymentType.other,
                                title: i18n.createJob.payment.typeSelector.other.title,
                                description: i18n.createJob.payment.typeSelector.other.description,
                                iconBuilder: (_) => $Icons.pencil(height: CreateJobPaymentView._pencilIconHeight),

                                onPressed: () => _setPaymentType(JobPaymentType.other),
                              ),
                            ],
                            initialValue: paymentType,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: switch (paymentType) {
                                JobPaymentType.fixed => const _FixedPaymentSection(),
                                JobPaymentType.range => const _RangePaymentSection(),
                                JobPaymentType.flexible => const _FlexiblePaymentSection(),
                                JobPaymentType.other => const _OtherPaymentSection(),
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                            child: MateoButton(
                              key: const ValueKey('create_job_payment_continue_button'),
                              label: i18n.createJob.continueButtonSemanticLabel,
                              variant: MateoButtonVariant.primary,
                              fit: MateoButtonFit.expand,

                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
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
