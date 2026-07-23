import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/job/job_contact_state.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class JobContactButton extends ConsumerWidget {
  const JobContactButton({required this.jobId, super.key});

  final String jobId;

  static double get estimatedButtonHeight => _buttonPadding.vertical + _iconSize;

  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 18);
  static const double _iconSize = 20;

  void _contact(WidgetRef ref, String jobId, String contactId) {
    ref.read(jobContactStateProvider(jobId: jobId, contactId: contactId).notifier).contact();
  }

  void _showErrorToast(BuildContext context, Translations i18n, Object error) {
    if (error.isOfflineConnectionDioException) {
      MateoToast.show(
        context,
        message: i18n.job.contactButton.error.offlineMessage,
        iconBuilder: (state) {
          return MateoIcon.wifiExclamation(width: state.iconSize, height: state.iconSize, color: state.iconColor);
        },
      );
      return;
    }

    MateoToast.show(context, message: i18n.job.contactButton.error.genericMessage);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);
    final colorScheme = context.mateo.colorScheme;
    final jobState = ref.watch(jobStateProvider(jobId));

    if (jobState.isLoading) return _buildLoadingButton();

    final contactReference = jobState.asData?.value.job.contactReference;
    final contactMethod = contactReference?.contactMethod;

    final contactState = contactReference == null
        ? null
        : ref.watch(jobContactStateProvider(jobId: jobId, contactId: contactReference.contactId));

    final isLoading = contactState?.isLoading ?? false;

    if (contactReference != null) {
      ref.listen<AsyncValue<void>>(jobContactStateProvider(jobId: jobId, contactId: contactReference.contactId), (
        prev,
        next,
      ) {
        next.whenOrNull(
          error: (error, _) {
            final i18n = ref.read(translationProvider);
            if (!context.mounted) return;

            _showErrorToast(context, i18n, error);
          },
        );
      });
    }

    return switch (contactMethod) {
      JobContactMethod.whatsapp => _buildWhatsAppButton(ref, context, i18n, colorScheme, isLoading, contactReference!),
      JobContactMethod.phoneCall => _buildPhoneCallButton(
        ref,
        context,
        i18n,
        colorScheme,
        isLoading,
        contactReference!,
      ),
      JobContactMethod.unknown => _buildUnknownButton(i18n, isLoading),
      null => _buildLoadingButton(),
    };
  }

  MateoButton _buildWhatsAppButton(
    WidgetRef ref,
    BuildContext context,
    Translations i18n,
    MateoColorScheme colorScheme,
    bool isLoading,
    JobContactReferenceDto contactReference,
  ) {
    return MateoButton(
      variant: MateoButtonVariant.primary,
      label: i18n.job.contactButton.whatsapp,
      colorScheme: colorScheme.buttons.whatsapp.tertiary,
      padding: _buttonPadding,
      isLoading: isLoading,
      onPressed: () => _contact(ref, jobId, contactReference.contactId),
      leadingIconBuilder: (state) {
        return MateoIcon.whatsapp(width: _iconSize, height: _iconSize, color: state.foregroundColor);
      },
    );
  }

  MateoButton _buildPhoneCallButton(
    WidgetRef ref,
    BuildContext context,
    Translations i18n,
    MateoColorScheme colorScheme,
    bool isLoading,
    JobContactReferenceDto contactReference,
  ) {
    return MateoButton(
      variant: MateoButtonVariant.primary,
      label: i18n.job.contactButton.phoneCall,
      colorScheme: colorScheme.buttons.success,
      padding: _buttonPadding,
      leadingIconSpacing: 12,
      isLoading: isLoading,
      leadingIconBuilder: (state) => MateoIcon.phone(width: _iconSize, height: _iconSize, color: state.foregroundColor),
      onPressed: () => _contact(ref, jobId, contactReference.contactId),
    );
  }

  MateoButton _buildUnknownButton(Translations i18n, bool isLoading) {
    return MateoButton(
      variant: MateoButtonVariant.primary,
      label: i18n.job.contactButton.unknown,
      padding: _buttonPadding,
      leadingIconSpacing: 10,
      isLoading: isLoading,
      leadingIconBuilder: (state) {
        return MateoIcon.circleBlock(width: _iconSize, height: _iconSize, color: state.foregroundColor);
      },
    );
  }

  MateoButton _buildLoadingButton() {
    return const MateoButton(variant: MateoButtonVariant.primary, label: '', padding: _buttonPadding, isLoading: true);
  }
}
