import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class TestApp extends StatelessWidget {
  const TestApp({required Widget this.child, super.key, this.mediaQueryData})
    : routerConfig = null,
      _wrapInScaffold = true;

  const TestApp.screen({required Widget this.child, super.key, this.mediaQueryData})
    : routerConfig = null,
      _wrapInScaffold = false;

  const TestApp.router({required RouterConfig<Object> this.routerConfig, super.key, this.mediaQueryData})
    : child = null,
      _wrapInScaffold = false;

  static const _color = (primary: Color(0xFFFF4A4B), onPrimary: Color(0xFFFFFFFF));

  final Widget? child;
  final MediaQueryData? mediaQueryData;
  final RouterConfig<Object>? routerConfig;
  final bool _wrapInScaffold;

  @override
  Widget build(BuildContext context) {
    final routerConfig = this.routerConfig;
    if (routerConfig != null) {
      return MateoApp.router(
        title: 'Test App',
        color: _color,
        routerConfig: routerConfig,
        builder: (context, child) {
          return _withMediaQuery(child ?? const SizedBox.shrink());
        },
      );
    }

    final child = this.child!;
    return MateoApp(
      title: 'Test App',
      color: _color,
      home: _withMediaQuery(_wrapInScaffold ? Scaffold(body: Center(child: child)) : child),
    );
  }

  Widget _withMediaQuery(Widget child) {
    final mediaQueryData = this.mediaQueryData;
    if (mediaQueryData == null) return child;

    return MediaQuery(data: mediaQueryData, child: child);
  }
}
