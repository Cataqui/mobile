import 'package:cataqui_app/widgets/whatsapp_connection_sheet/whatsapp_connection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class WhatsappConnectionSheetTestHost extends StatelessWidget {
  const WhatsappConnectionSheetTestHost({required this.onShown, super.key});

  static const openButtonKey = ValueKey('whatsapp_connection_sheet_test_open');

  final void Function(Future<bool> result) onShown;

  @override
  Widget build(BuildContext context) {
    return MateoButton(
      presentation: const MateoButtonPresentation.label(label: 'Open connection', variant: MateoButtonVariant.primary),
      key: openButtonKey,
      onPressed: () => onShown(WhatsappConnectionSheet.show(context: context)),
    );
  }
}
