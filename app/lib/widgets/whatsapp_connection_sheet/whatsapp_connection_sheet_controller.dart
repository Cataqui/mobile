import 'package:cataqui_app/widgets/whatsapp_connection_sheet/whatsapp_connection_sheet.dart';
import 'package:flutter/widgets.dart';

class WhatsappConnectionSheetController {
  WhatsappConnectionSheetController(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  Future<bool>? _activePresentation;

  Future<bool> show() {
    final activePresentation = _activePresentation;
    if (activePresentation != null) return activePresentation;

    final overlayContext = _navigatorKey.currentState?.overlay?.context;
    if (overlayContext == null) {
      throw StateError('The WhatsApp connection sheet cannot be shown before the root navigator is mounted.');
    }

    late final Future<bool> presentation;

    presentation = WhatsappConnectionSheet.show(context: overlayContext).whenComplete(() {
      if (identical(_activePresentation, presentation)) _activePresentation = null;
    });

    _activePresentation = presentation;

    return presentation;
  }
}
