import 'package:cataqui_app/widgets/whatsapp_disconnection_sheet/whatsapp_disconnection_sheet.dart';
import 'package:flutter/material.dart';

class WhatsappDisconnectionSheetTestHost extends StatelessWidget {
  const WhatsappDisconnectionSheetTestHost({super.key, this.onClosed, this.onConfirmed, this.onResult});

  static const openButtonKey = ValueKey('whatsapp_disconnection_sheet_test_open_button');

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
            final didDisconnect = await WhatsappDisconnectionSheet.show(
              context: context,
              onConfirmed: onConfirmed ?? () async {},
            );
            onResult?.call(didDisconnect);
            onClosed?.call();
          },
          child: const Text('Open sheet'),
        ),
      ),
    );
  }
}
