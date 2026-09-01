import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
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
      theme: MateoTheme.adaptive(accentColor: const Color(0xFFFF4A4B), onAccent: const Color(0xFFFFFFFF)),
      routerConfig: goRouter,
      debugShowCheckedModeBanner: true,
      locale: Locale.fromSubtags(
        languageCode: i18n.$meta.locale.languageCode,
        scriptCode: i18n.$meta.locale.scriptCode,
        countryCode: i18n.$meta.locale.countryCode,
      ),
      supportedLocales: AppLocaleUtils.instance.locales.map(
        (locale) => Locale.fromSubtags(
          languageCode: locale.languageCode,
          scriptCode: locale.scriptCode,
          countryCode: locale.countryCode,
        ),
      ),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        unawaited(ref.read(deviceCornerRadiiProvider.notifier).preload(context));
        return AppAnimatedSplash(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
