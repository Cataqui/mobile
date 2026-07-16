import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/qui_theme.dart';
import 'widgets/qui_toast/qui_toast.dart';

/// The QUI application shell.
///
/// A replacement for [MaterialApp] that auto-configures the QUI theme, system
/// UI overlay styling, and everything needed for QUI components and features.
/// This is the first step to use QUI — drop it in and all QUI infrastructure
/// is ready.
///
/// Currently provides the [QuiApp.router] constructor. A non-router [QuiApp]
/// constructor will be introduced in a future release.
///
/// ```dart
/// QuiApp.router(
///   title: 'My App',
///   color: (primary: Color(0xFFFF4A4B), onPrimary: Color(0xFFFFFFFF)),
///   routerConfig: goRouter,
///   builder: (context, child) {
///     return MySplash(child: child ?? const SizedBox.shrink());
///   },
/// )
/// ```
///
/// See also:
///  * [QuiTheme], the default QUI theme.
class QuiApp extends StatelessWidget {
  /// Creates a QUI application shell that uses a [Router] instead of a
  /// [Navigator].
  ///
  /// The [color] record controls the QUI palette via `primary` and `onPrimary`.
  /// The [routerConfig], [routerDelegate], and [routeInformationParser]
  /// parameters must not be null at the same time.
  const QuiApp.router({
    required this.title,
    required this.color,
    super.key,
    this.scaffoldMessengerKey,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.routerConfig,
    this.backButtonDispatcher,
    this.builder,
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.themeMode = ThemeMode.system,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = false,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
  }) : assert(
         routerDelegate != null || routerConfig != null,
         'At least one of routerDelegate or routerConfig must be provided.',
       );

  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final BackButtonDispatcher? backButtonDispatcher;
  final RouterConfig<Object>? routerConfig;
  final TransitionBuilder? builder;
  final String? title;
  final GenerateAppTitle? onGenerateTitle;
  final NotificationListenerCallback<NavigationNotification>? onNavigationNotification;

  /// The QUI palette configuration.
  ///
  /// Use `primary` to set the palette's primary color and `onPrimary` for the
  /// color applied on top of primary surfaces (text, icons).
  final ({Color primary, Color onPrimary}) color;
  final ThemeMode? themeMode;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool debugShowMaterialGrid;
  final bool showPerformanceOverlay;
  final bool checkerboardRasterCacheImages;
  final bool checkerboardOffscreenLayers;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;

  static SystemUiOverlayStyle _systemUiOverlayStyleFor(Brightness brightness) {
    return switch (brightness) {
      Brightness.light => const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      Brightness.dark => const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routeInformationProvider: routeInformationProvider,
      routeInformationParser: routeInformationParser,
      routerDelegate: routerDelegate,
      routerConfig: routerConfig,
      backButtonDispatcher: backButtonDispatcher,
      title: title,
      onGenerateTitle: onGenerateTitle,
      onNavigationNotification: onNavigationNotification,
      color: color.primary,
      theme: QuiTheme.light(primaryColor: color.primary, onPrimary: color.onPrimary),
      darkTheme: null,
      highContrastTheme: null,
      highContrastDarkTheme: null,
      themeMode: themeMode,
      themeAnimationDuration: kThemeAnimationDuration,
      themeAnimationCurve: Curves.linear,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      debugShowMaterialGrid: debugShowMaterialGrid,
      showPerformanceOverlay: showPerformanceOverlay,
      checkerboardRasterCacheImages: checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: checkerboardOffscreenLayers,
      showSemanticsDebugger: showSemanticsDebugger,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      shortcuts: shortcuts,
      actions: actions,
      restorationScopeId: restorationScopeId,
      themeAnimationStyle: null,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final userContent = builder?.call(context, child) ?? child ?? const SizedBox.shrink();

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _systemUiOverlayStyleFor(brightness),
          child: QuiToastMessenger(child: userContent),
        );
      },
    );
  }
}
