import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class TestJobMapApp extends StatelessWidget {
  const TestJobMapApp.screen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = MateoPalette();
    return MateoApp(
      title: 'Job Map Test',
      theme: MateoThemeData.light(accentColor: palette.red[9], onAccent: palette.neutral[1]),
      home: Material(type: .transparency, child: child),
    );
  }
}
