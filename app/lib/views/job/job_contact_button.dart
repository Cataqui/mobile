import 'package:cataqui_app/core/app_toast.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limited_dio_exception.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/job/job_contact_state.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class JobContactButton extends ConsumerWidget {
  const JobContactButton({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);
    final jobState = ref.watch(jobStateProvider(jobId));

    final contactReference = jobState.isLoading ? null : jobState.asData?.value.job.contactReference;
    final contactMethod = contactReference?.contactMethod;

    final contactState = contactReference == null
        ? null
        : ref.watch(jobContactStateProvider(jobId: jobId, contactId: contactReference.contactId));

    if (contactReference != null) {
      ref.listen<AsyncValue<void>>(jobContactStateProvider(jobId: jobId, contactId: contactReference.contactId), (
        prev,
        next,
      ) {
        next.whenOrNull(
          error: (error, _) {
            final i18n = ref.read(translationProvider);
            if (!context.mounted) return;

            _showErrorToast(context: context, appToast: ref.read(appToastProvider), i18n: i18n, error: error);
          },
        );
      });
    }

    return MateoButton(
      presentation: .label(
        variant: .primary.neutral,
        label: switch (contactMethod) {
          .whatsapp => i18n.job.contactButton.whatsapp,
          .phoneCall => i18n.job.contactButton.phoneCall,
          .unknown => i18n.job.contactButton.unknown,
          null => '',
        },
        size: .standard,
        width: .fill,
        colorScheme: switch (contactMethod) {
          .whatsapp => switch (Theme.of(context).brightness) {
            .light => MateoButtonColorScheme(
              background: const Color(0xFF002002),
              foreground: const Color(0xFF25D366),
              backgroundDisabled: MateoTheme.of(context).palette.neutral[4],
              foregroundDisabled: MateoTheme.of(context).palette.neutral[9],
            ),
            .dark => throw UnsupportedError('Dark contact-action colors are not supported.'),
          },
          .phoneCall => switch (Theme.of(context).brightness) {
            .light => MateoButtonColorScheme(
              background: const Color(0xFF00C950),
              foreground: const Color(0xFF001F06),
              backgroundDisabled: MateoTheme.of(context).palette.neutral[4],
              foregroundDisabled: MateoTheme.of(context).palette.neutral[9],
            ),
            .dark => throw UnsupportedError('Dark contact-action colors are not supported.'),
          },
          .unknown || null => null,
        },
        leadingIcon: contactMethod?.icon(),
      ),
      isLoading: contactReference == null || (contactState?.isLoading ?? false),
      onPressed: switch (contactMethod) {
        .whatsapp || .phoneCall =>
          () => ref
              .read(jobContactStateProvider(jobId: jobId, contactId: contactReference!.contactId).notifier)
              .contact(),
        .unknown || null => null,
      },
    );
  }

  void _showErrorToast({
    required BuildContext context,
    required AppToast appToast,
    required Translations i18n,
    required Object error,
  }) {
    if (error is RateLimitedDioException) {
      appToast.maybeShowError(context, error: error, message: i18n.job.contactButton.error.rateLimitedMessage);
      return;
    }

    if (error.isOfflineConnectionDioException) {
      appToast.maybeShowError(
        context,
        error: error,
        message: i18n.job.contactButton.error.offlineMessage,
        icon: const MateoIcon(.wifiExclamation),
      );
      return;
    }

    appToast.maybeShowError(context, error: error, message: i18n.job.contactButton.error.genericMessage);
  }
}
