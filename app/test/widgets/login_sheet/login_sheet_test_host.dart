import 'package:cataqui_app/widgets/login_sheet/login_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class LoginSheetTestHost extends StatelessWidget {
  const LoginSheetTestHost({required this.onShown, super.key});

  static const openButtonKey = ValueKey('login_sheet_test_open');

  final void Function(Future<bool> result) onShown;

  @override
  Widget build(BuildContext context) {
    return MateoButton(
      key: openButtonKey,
      label: 'Open login',
      variant: MateoButtonVariant.primary,
      onPressed: () => onShown(LoginSheet.show(context: context)),
    );
  }
}
