import 'package:flutter/material.dart';
import 'package:qui/qui.dart';

class TestApp extends StatelessWidget {
  const TestApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
