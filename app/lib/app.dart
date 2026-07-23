import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/widgets/app_animated_splash/app_animated_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class CataquiApp extends ConsumerWidget {
  const CataquiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final i18n = ref.watch(translationProvider);

    return MateoApp.router(
      title: i18n.app.name,
      color: (primary: const Color(0xFFFF4A4B), onPrimary: const Color(0xFFFFFFFF)),
      routerConfig: goRouter,
      locale: i18n.$meta.locale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        return AppAnimatedSplash(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
