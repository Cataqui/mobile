import 'dart:async';

import 'package:flutter/services.dart';

final class PaymentIconsTestAssetBundle extends CachingAssetBundle {
  final Completer<void> _releaseCompleter = Completer<void>();
  bool didRequestPaymentIcon = false;

  void release() {
    if (_releaseCompleter.isCompleted) return;

    _releaseCompleter.complete();
  }

  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/icons/')) {
      didRequestPaymentIcon = true;
      await _releaseCompleter.future;
    }

    return rootBundle.load(key);
  }
}
