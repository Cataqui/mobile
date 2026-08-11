import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

class TestApp extends StatelessWidget {
  const TestApp({
    required Widget this.child,
    super.key,
    this.mediaQueryData,
    this.navigatorKey,
    this.providerOverrides = const [],
  }) : routerConfig = null,
       _wrapInScaffold = true;

  const TestApp.screen({
    required Widget this.child,
    super.key,
    this.mediaQueryData,
    this.navigatorKey,
    this.providerOverrides = const [],
  }) : routerConfig = null,
       _wrapInScaffold = false;

  const TestApp.router({
    required RouterConfig<Object> this.routerConfig,
    super.key,
    this.mediaQueryData,
    this.providerOverrides = const [],
  }) : child = null,
       navigatorKey = null,
       _wrapInScaffold = false;

  static const _color = (primary: Color(0xFFFF4A4B), onPrimary: Color(0xFFFFFFFF));
  static final _secureStorageOverride = secureStorageProvider.overrideWith((ref) {
    final secureStorage = MockFlutterSecureStorage();
    when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    return secureStorage;
  });

  final Widget? child;
  final MediaQueryData? mediaQueryData;
  final GlobalKey<NavigatorState>? navigatorKey;
  final List<Override> providerOverrides;
  final RouterConfig<Object>? routerConfig;
  final bool _wrapInScaffold;

  @override
  Widget build(BuildContext context) {
    final routerConfig = this.routerConfig;
    if (routerConfig != null) {
      return ProviderScope(
        overrides: _resolvedProviderOverrides(),
        child: MateoApp.router(
          title: 'Test App',
          color: _color,
          routerConfig: routerConfig,
          builder: (context, child) {
            return _withMediaQuery(child ?? const SizedBox.shrink());
          },
        ),
      );
    }

    final child = this.child!;
    return ProviderScope(
      overrides: _resolvedProviderOverrides(),
      child: MateoApp(
        title: 'Test App',
        color: _color,
        navigatorKey: navigatorKey,
        home: _withMediaQuery(_wrapInScaffold ? Scaffold(body: Center(child: child)) : child),
      ),
    );
  }

  Widget _withMediaQuery(Widget child) {
    final mediaQueryData = this.mediaQueryData;
    if (mediaQueryData == null) return child;

    return MediaQuery(data: mediaQueryData, child: child);
  }

  List<Override> _resolvedProviderOverrides() {
    final overridesSecureStorage = providerOverrides.any((override) => override.origin == secureStorageProvider);
    if (overridesSecureStorage) return providerOverrides;

    return [_secureStorageOverride, ...providerOverrides];
  }
}
