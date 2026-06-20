import 'package:flutter/material.dart';
import 'package:qui/qui.dart';

/// Shared test wrapper that provides a [MaterialApp] with [QuiTheme] for
/// widget tests in the `qui` package.
///
/// Use this instead of defining per-file `_TestApp` variants.
class TestApp extends StatelessWidget {
  const TestApp({required this.child, super.key, this.debugShowCheckedModeBanner = false});

  final Widget child;
  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
