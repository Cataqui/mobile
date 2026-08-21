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
       fontFamily = null,
       _wrapInScaffold = true;

  const TestApp.screen({
    required Widget this.child,
    super.key,
    this.mediaQueryData,
    this.navigatorKey,
    this.providerOverrides = const [],
  }) : routerConfig = null,
       fontFamily = null,
       _wrapInScaffold = false;

  const TestApp.router({
    required RouterConfig<Object> this.routerConfig,
    super.key,
    this.mediaQueryData,
    this.providerOverrides = const [],
    this.fontFamily,
  }) : child = null,
       navigatorKey = null,
       _wrapInScaffold = false;

  static const _color = (accent: Color(0xFFFF4A4B), onAccent: Color(0xFFFFFFFF));
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
  final String? fontFamily;
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
            final content = _withMediaQuery(child ?? const SizedBox.shrink());
            final fontFamily = this.fontFamily;
            if (fontFamily == null) return content;

            final theme = Theme.of(context);
            return Theme(
              data: theme.copyWith(
                textTheme: theme.textTheme.apply(fontFamily: fontFamily),
                primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: fontFamily),
              ),
              child: content,
            );
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
