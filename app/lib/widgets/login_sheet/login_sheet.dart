import 'dart:async';

import 'package:cataqui_app/core/app_auth/login_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/icons.g.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class LoginSheet extends ConsumerWidget {
  const LoginSheet({super.key});

  static const imageKey = ValueKey('login_sheet_keys');
  static const subtitleKey = ValueKey('login_sheet_subtitle');
  static const titleKey = ValueKey('login_sheet_title');

  static Future<void> precacheImages(BuildContext context) {
    return $IconsCache.precachePadlock(context, height: _illustrationHeight);
  }

  static const _illustrationHeight = 110.0;

  static Future<bool> show({required BuildContext context}) async {
    unawaited(precacheImages(context));
    final providerContainer = ProviderScope.containerOf(context, listen: false);

    final didLogin = await MateoBottomSheet.show<bool>(
      context,
      avoidKeyboardInset: false,
      shouldDismiss: (source) {
        final isLoginInProgress = providerContainer.read(loginStateProvider).isLoading;
        if (!isLoginInProgress) return true;

        return switch (source) {
          MateoBottomSheetDismissSource.closeButton => true,
          MateoBottomSheetDismissSource.drag => false,
          MateoBottomSheetDismissSource.tapOutside => false,
          MateoBottomSheetDismissSource.systemBack => true,
          MateoBottomSheetDismissSource.accessibilityAction => false,
        };
      },
      child: const LoginSheet(),
    );

    return didLogin ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);
    final colorScheme = context.mateo.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: $Icons.padlock(key: imageKey, height: _illustrationHeight, fit: BoxFit.contain),
            ),
            const SizedBox(height: 42),
            FractionallySizedBox(
              widthFactor: 0.9,
              child: Text(
                key: titleKey,

                i18n.loginSheet.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.text.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: WhatsappLoginButton(onSuccess: (_) => Navigator.of(context).pop(true)),
        ),
      ],
    );
  }
}
