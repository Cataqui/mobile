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
  late final MateoTextController _paymentNoteController;

  void _focusPaymentNote() {
    if (!mounted || ref.read(createJobStateProvider).paymentType != JobPaymentType.other) return;
    if (_paymentNoteController.hasFocus) return;

    _paymentNoteController.focus();
  }

  void _focusPaymentNoteAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusPaymentNote());
  }

  void _setPaymentType(JobPaymentType paymentType) {
    ref.read(createJobStateProvider.notifier).setPaymentType(paymentType);
  }

  @override
  void initState() {
    super.initState();
    final createJobData = ref.read(createJobStateProvider);
    _paymentNoteController = MateoTextController(text: createJobData.paymentNote);
    if (createJobData.paymentType != JobPaymentType.other) return;

    _focusPaymentNoteAfterBuild();
  }

  @override
  void dispose() {
    _paymentNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    ref.watch(createJobStateProvider.select((state) => state.jobId));
    final paymentType = ref.watch(createJobStateProvider.select((state) => state.paymentType));
    final mediaQueryData = MediaQuery.of(context);
    final continueButton = MateoButton(
      key: const ValueKey('create_job_payment_continue_button'),
      label: i18n.createJob.continueButtonSemanticLabel,
      variant: MateoButtonVariant.primary,
      fit: MateoButtonFit.expand,
      onPressed: () {},
    );

    return MateoView(
      backgroundColor: Colors.transparent,
      edgeFade: null,
      header: MateoViewHeader(
        centerTitle: true,
        title: i18n.createJob.payment.title,
        leading: MateoFloatingActionButton(
          key: const ValueKey('create_job_payment_back_button'),
          onPressed: context.pop,
          semanticLabel: i18n.createJob.payment.backButtonSemanticLabel,
          backgroundColor: context.mateo.colorScheme.bottomSheet.background,
          foregroundColor: context.mateo.colorScheme.text.primary,
          borderSide: BorderSide.none,
          size: 50,
          tapTargetSize: 55,
          iconSize: 20,
          iconBuilder: (state) {
            return MateoIcon.arrowLeft(width: state.iconSize, height: state.iconSize, color: state.foregroundColor);
          },
        ),
      ),

      bodySurfaceBuilder: (context, content) {
        return MediaQuery(
          data: mediaQueryData.copyWith(
            padding: mediaQueryData.padding.copyWith(bottom: mediaQueryData.viewPadding.bottom),
            viewInsets: mediaQueryData.viewInsets.copyWith(bottom: 0),
          ),
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
              child: content,
            ),
          ),
        );
      },
      body: MorphDescendant(
        flightBehavior: MorphDescendantFlightBehavior.snapshot,
        child: SafeArea(
          top: false,
          child: Column(
            key: const ValueKey('create_job_payment_view_content'),
            children: [
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
                onCloseCompleted: _focusPaymentNoteAfterBuild,
              ),
              if (paymentType == JobPaymentType.other)
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _OtherPaymentSection(noteTextController: _paymentNoteController),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: math.max(
                              mediaQueryData.viewInsets.bottom - mediaQueryData.viewPadding.bottom + 12,
                              12,
                            ),
                          ),
                          child: continueButton,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: switch (paymentType) {
                      JobPaymentType.fixed => const _FixedPaymentSection(),
                      JobPaymentType.range => const _RangePaymentSection(),
                      JobPaymentType.flexible => const _FlexiblePaymentSection(),
                      JobPaymentType.other => throw StateError('Other payment is rendered separately.'),
                    },
                  ),
                ),
                Padding(padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12, top: 8), child: continueButton),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
