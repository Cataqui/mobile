import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/widgets/app_animated_splash/app_animated_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qui/qui.dart';

class CataquiApp extends ConsumerWidget {
  const CataquiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final i18n = ref.watch(translationProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: MaterialApp.router(
        title: i18n.app.name,
        routerConfig: goRouter,
        theme: QuiTheme.light(),
        locale: i18n.$meta.locale.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => AppAnimatedSplash(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
