import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/job/job_contact_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qui/qui.dart';

class JobContactButton extends ConsumerWidget {
  const JobContactButton({required this.jobId, required this.contactReference, super.key});

  final String jobId;
  final JobContactReferenceDto contactReference;

  static double get estimatedButtonHeight => _buttonPadding.vertical + _iconSize;

  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 18);
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);
    final colors = context.qui.colors;

    return switch (contactReference.contactMethod) {
      JobContactMethod.whatsapp => _buildWhatsAppButton(i18n, colors, ref),
      JobContactMethod.phoneCall => _buildPhoneCallButton(i18n, colors, ref),
      JobContactMethod.unknown => QuiPrimaryButton(
        label: i18n.job.contactButton.unknown,
        padding: _buttonPadding,
        leadingIconSpacing: 10,
        leadingIconBuilder: (state) => QuiIcons.instance.build(
          (assets) => assets.circleBlock,
          width: _iconSize,
          height: _iconSize,
          colorFilter: ColorFilter.mode(state.foregroundColor, BlendMode.srcIn),
        ),
      ),
    };
  }

  QuiPrimaryButton _buildWhatsAppButton(Translations i18n, QuiColors colors, WidgetRef ref) {
    return QuiPrimaryButton(
      label: i18n.job.contactButton.whatsapp,
      backgroundColor: colors.neutralButtonBackground,
      foregroundColor: colors.money,
      padding: _buttonPadding,
      leadingIconBuilder: (state) => QuiIcons.instance.build(
        (assets) => assets.whatsapp,
        width: _iconSize,
        height: _iconSize,
        colorFilter: ColorFilter.mode(state.foregroundColor, BlendMode.srcIn),
      ),
      onPressed: () => _handleContactPressed(ref),
    );
  }

  QuiPrimaryButton _buildPhoneCallButton(Translations i18n, QuiColors colors, WidgetRef ref) {
    return QuiPrimaryButton(
      label: i18n.job.contactButton.phoneCall,
      backgroundColor: colors.money,
      foregroundColor: colors.textPrimary,
      padding: _buttonPadding,
      leadingIconSpacing: 12,
      leadingIconBuilder: (state) => QuiIcons.instance.build(
        (assets) => assets.phone,
        width: _iconSize,
        height: _iconSize,
        colorFilter: ColorFilter.mode(state.foregroundColor, BlendMode.srcIn),
      ),
      onPressed: () => _handleContactPressed(ref),
    );
  }

  Future<void> _handleContactPressed(WidgetRef ref) async {
    try {
      final contactData = await ref.read(
        jobContactStateProvider(jobId: jobId, contactId: contactReference.contactId).future,
      );

      final identifier = contactData.contact.identifier;

      switch (contactReference.contactMethod) {
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
