import 'package:cataqui_app/widgets/logout_warning_sheet/logout_warning_sheet.dart';
import 'package:flutter/material.dart';

class LogoutWarningSheetTestHost extends StatelessWidget {
  const LogoutWarningSheetTestHost({super.key, this.onClosed});

  static const openButtonKey = ValueKey('logout_warning_sheet_test_open_button');

  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: openButtonKey,
          onPressed: () async {
            await LogoutWarningSheet.show(context: context);
            onClosed?.call();
          },
          child: const Text('Open sheet'),
        ),
      ),
    );
  }
}
