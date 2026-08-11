import 'package:cataqui_app/app_state.dart';
import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/network/auth_interceptor/auth_interceptor.dart';
import 'package:cataqui_app/core/network/cataqui_api_v1_dio_factory.dart';
import 'package:cataqui_app/core/repositories/auth_repository/auth_repository.dart';
import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/onboarding/onboarding_route.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_route.dart';
import 'package:cataqui_app/widgets/login_sheet/login_sheet_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Translations translation(Ref ref) {
  final locale = ref.watch(appStateProvider.select((s) => s.currentLocale));
  return locale.buildSync();
}

@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) {
  return const AppConfig(flavor: appFlavor ?? 'development');
}

@Riverpod(keepAlive: true)
SharedPreferencesAsync sharedPreferencesAsync(Ref ref) {
  return SharedPreferencesAsync();
}

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'cataqui_auth', migrateWithBackup: true),
  );
}

@Riverpod(keepAlive: true)
Dio unauthenticatedCataquiApiV1Dio(Ref ref) {
  final appConfig = ref.read(appConfigProvider);
  final locale = ref.watch(appStateProvider.select((s) => s.currentLocale));

  return CataquiApiV1DioFactory.create(appConfig: appConfig, languageTag: locale.languageTag);
}

@Riverpod(keepAlive: true)
Dio authenticatedCataquiApiV1Dio(Ref ref) {
  final appConfig = ref.read(appConfigProvider);
  final locale = ref.watch(appStateProvider.select((s) => s.currentLocale));
  final unauthenticatedDio = ref.watch(unauthenticatedCataquiApiV1DioProvider);

  return CataquiApiV1DioFactory.create(
    appConfig: appConfig,
    languageTag: locale.languageTag,
    authInterceptor: AuthInterceptor(
      unauthenticatedDio: unauthenticatedDio,
      readSession: () => ref.read(appAuthStateProvider),
      refreshSession: () => ref.read(appAuthStateProvider.notifier).refreshSession(),
      refreshSessionInBackground: () => ref.read(appAuthStateProvider.notifier).refreshSessionInBackground(),
    ),
  );
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(unauthenticatedDio: ref.watch(unauthenticatedCataquiApiV1DioProvider));
}

@Riverpod(keepAlive: true)
LoginSheetController loginSheetController(Ref ref) {
  return LoginSheetController(ref.watch(rootNavigatorKeyProvider));
}

@Riverpod(keepAlive: true)
FeedRepository feedRepository(Ref ref) {
  return FeedRepository(unauthenticatedDio: ref.watch(unauthenticatedCataquiApiV1DioProvider));
}

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final appStorage = ref.read(appStorageStateProvider).requireValue;

  return GoRouter(
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    initialLocation: appStorage.hasCompletedOnboarding ? const FeedRoute().location : const OnboardingRoute().location,
    redirect: (context, state) {
      if (state.matchedLocation != const OnboardingRoute().location) return null;

      final hasCompletedOnboarding = ref.read(appStorageStateProvider).requireValue.hasCompletedOnboarding;
      if (!hasCompletedOnboarding) return null;

      return const FeedRoute().location;
    },
    routes: [$onboardingRoute, $posterOnboardingRoute, $feedRoute, $jobRoute],
  );
}

@Riverpod(keepAlive: true)
GlobalKey<NavigatorState> rootNavigatorKey(Ref ref) {
  return GlobalKey<NavigatorState>(debugLabel: 'root_navigator');
}

@Riverpod(keepAlive: true)
JobRepository jobRepository(Ref ref) {
  return JobRepository(unauthenticatedDio: ref.watch(unauthenticatedCataquiApiV1DioProvider));
}

@riverpod
Whatsapp whatsapp(Ref ref) {
  return Whatsapp();
}

@riverpod
Telephony telephony(Ref ref) {
  return Telephony();
}
