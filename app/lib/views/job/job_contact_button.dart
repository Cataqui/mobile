import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/job/job_contact_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qui/qui.dart';

class JobContactButton extends ConsumerWidget {
  const JobContactButton({required this.jobId, required this.contactReference, required this.isLoading, super.key});

  final String jobId;
  final JobContactReferenceDto? contactReference;
  final bool isLoading;

  static double get estimatedButtonHeight => _buttonPadding.vertical + _iconSize;

  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 18);
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = contactReference;

    if (reference == null) {
      return QuiButton(variant: QuiButtonVariant.primary, label: '', padding: _buttonPadding, isLoading: isLoading);
    }

    final i18n = ref.watch(translationProvider);
    final colorScheme = context.qui.colorScheme;

    return switch (reference.contactMethod) {
      JobContactMethod.whatsapp => _buildWhatsAppButton(i18n, colorScheme, ref),
      JobContactMethod.phoneCall => _buildPhoneCallButton(i18n, colorScheme, ref),
      JobContactMethod.unknown => QuiButton(
        variant: QuiButtonVariant.primary,
        label: i18n.job.contactButton.unknown,
        padding: _buttonPadding,
        leadingIconSpacing: 10,
        isLoading: isLoading,
        leadingIconBuilder: (state) => QuiIcon.circleBlock(
          width: _iconSize,
          height: _iconSize,
          color: state.foregroundColor,
        ),
      ),
    };
  }

  QuiButton _buildWhatsAppButton(Translations i18n, QuiColorScheme colorScheme, WidgetRef ref) {
    return QuiButton(
      variant: QuiButtonVariant.primary,
      label: i18n.job.contactButton.whatsapp,
      colorScheme: colorScheme.buttons.whatsapp.tertiary,
      padding: _buttonPadding,
      isLoading: isLoading,
      leadingIconBuilder: (state) => QuiIcon.whatsapp(
        width: _iconSize,
        height: _iconSize,
        color: state.foregroundColor,
      ),
      onPressed: () => _handleContactPressed(ref),
    );
  }

  QuiButton _buildPhoneCallButton(Translations i18n, QuiColorScheme colorScheme, WidgetRef ref) {
    return QuiButton(
      variant: QuiButtonVariant.primary,
      label: i18n.job.contactButton.phoneCall,
      colorScheme: colorScheme.buttons.success,
      padding: _buttonPadding,
      leadingIconSpacing: 12,
      isLoading: isLoading,
      leadingIconBuilder: (state) => QuiIcon.phone(
        width: _iconSize,
        height: _iconSize,
        color: state.foregroundColor,
      ),
      onPressed: () => _handleContactPressed(ref),
    );
  }

  Future<void> _handleContactPressed(WidgetRef ref) async {
    final reference = contactReference;
    if (reference == null) return;

    try {
      final contactData = await ref.read(jobContactStateProvider(jobId: jobId, contactId: reference.contactId).future);

      final identifier = contactData.contact.identifier;

      switch (reference.contactMethod) {
        case JobContactMethod.whatsapp:
          final whatsapp = ref.read(whatsappProvider);
          await whatsapp.launchChat(number: identifier);

        case JobContactMethod.phoneCall:
          final telephony = ref.read(telephonyProvider);
          await telephony.call(number: identifier);

        case JobContactMethod.unknown:
          break;
      }
    } catch (error) {
      debugPrint('Failed to launch contact: $error');
    }
  }
}
