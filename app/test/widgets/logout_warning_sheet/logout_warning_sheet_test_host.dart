import 'package:cataqui_app/widgets/logout_warning_sheet/logout_warning_sheet.dart';
import 'package:flutter/material.dart';

class LogoutWarningSheetTestHost extends StatelessWidget {
  const LogoutWarningSheetTestHost({super.key, this.onClosed, this.onConfirmed, this.onResult});

  static const openButtonKey = ValueKey('logout_warning_sheet_test_open_button');

  final VoidCallback? onClosed;
  final Future<void> Function()? onConfirmed;
  final ValueChanged<bool>? onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: openButtonKey,
          onPressed: () async {
            final didLogout = await LogoutWarningSheet.show(context: context, onConfirmed: onConfirmed ?? () async {});
            onResult?.call(didLogout);
            onClosed?.call();
          },
          child: const Text('Open sheet'),
        ),
      ),
    );
  }
}
