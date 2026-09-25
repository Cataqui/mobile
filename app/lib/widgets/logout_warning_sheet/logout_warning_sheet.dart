import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class LogoutWarningSheet extends ConsumerStatefulWidget {
  const LogoutWarningSheet({super.key});

  static Future<void> show({required BuildContext context}) {
    unawaited(HapticFeedback.warningNotification());

    return showMateoSheet<void>(
      context: context,
      view: const MateoSheetView(
        reserveHeaderSpace: false,
        header: MateoSheetViewHeader(presentation: .closeButton()),
        surface: MateoSheetViewSurface(key: ValueKey('logout_warning_sheet_surface'), child: LogoutWarningSheet()),
      ),
    );
  }

  @override
  ConsumerState<LogoutWarningSheet> createState() => _LogoutWarningSheetState();
}

class _LogoutWarningSheetState extends ConsumerState<LogoutWarningSheet> {
  final MotionController _warningIconMotionController = MotionController();
  bool _hasShaken = false;

  void _shakeWhenSettled() {
    if (_hasShaken) return;
    _hasShaken = true;
    _warningIconMotionController.play();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final colorScheme = MateoTheme.of(context).colorScheme;

    return RouteListener(
      onSettled: _shakeWhenSettled,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Motion(
            controller: _warningIconMotionController,
            startup: .skip,
            effect: const ShakeMotionEffect(
              offset: Offset(3, 0),
              count: 5,
              damping: 1,
              duration: Duration(milliseconds: 1700),
              curve: Curves.easeOutBack,
            ),
            child: MateoIcon(.exclamationTriangle, size: 56, color: MateoTheme.of(context).palette.amber),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text(
                  i18n.logoutWarningSheet.title,
                  style: TextStyle(color: colorScheme.text.primary, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  i18n.logoutWarningSheet.description,
                  style: TextStyle(
                    color: colorScheme.text.tertiary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: MateoButton(
                  key: const ValueKey('logout_warning_sheet_back_button'),
                  presentation: .label(label: i18n.logoutWarningSheet.back, variant: .secondary.neutral, width: .fill),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MateoButton(
                  key: const ValueKey('logout_warning_sheet_logout_button'),
                  presentation: .label(label: i18n.logoutWarningSheet.logout, variant: .primary.warning, width: .fill),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
