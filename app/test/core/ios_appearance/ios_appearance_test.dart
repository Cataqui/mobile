import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS uses the light appearance supplied by the app instead of device dark mode', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(infoPlist, matches(RegExp(r'<key>UIUserInterfaceStyle</key>\s*<string>Light</string>')));
  });
}
