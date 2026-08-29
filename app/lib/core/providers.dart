import 'package:cataqui_app/app_state.dart';
import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/app_toast.dart';
import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/network/auth_interceptor/auth_interceptor.dart';
import 'package:cataqui_app/core/network/cataqui_api_v1_dio_factory.dart';
import 'package:cataqui_app/core/network/geosearch/geosearch_access_token_interceptor.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limit_interceptor.dart';
import 'package:cataqui_app/core/repositories/auth_repository/auth_repository.dart';
import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:cataqui_app/core/repositories/geosearch_repository/geosearch_repository.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/description/create_job_description_route.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_route.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_route.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/onboarding/onboarding_route.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_route.dart';
import 'package:cataqui_app/widgets/login_sheet/login_sheet_controller.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppToast appToast(Ref ref) {
  return const AppToast();
}

@Riverpod(keepAlive: true)
Translations translation(Ref ref) {
  final locale = ref.watch(appStateProvider.select((s) => s.currentLocale));
  return locale.buildSync();
}

@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) {
  return const AppConfig(flavor: appFlavor ?? 'development');
}

@riverpod
DeviceLocation deviceLocation(Ref ref) {
  return const DeviceLocation();
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
Future<CookieJar> cataquiApiCookieJar(Ref ref) async {
  try {
    final applicationSupportDirectory = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(storage: FileStorage('${applicationSupportDirectory.path}/cataqui_api_cookies'));
    await cookieJar.forceInit();
    return cookieJar;
  } on Object {
    return CookieJar();
  }
}

@Riverpod(keepAlive: true)
Dio unauthenticatedCataquiApiV1Dio(Ref ref) {
  final appConfig = ref.read(appConfigProvider);
  final locale = ref.watch(appStateProvider.select((s) => s.currentLocale));
  final cookieJar = ref.watch(cataquiApiCookieJarProvider).requireValue;

  return CataquiApiV1DioFactory.create(appConfig: appConfig, languageTag: locale.languageTag, cookieJar: cookieJar);
}

@Riverpod(keepAlive: true)
Dio authenticatedCataquiApiV1Dio(Ref ref) {
  final appConfig = ref.read(appConfigProvider);
  final locale = ref.watch(appStateProvider.select((s) => s.currentLocale));
  final cookieJar = ref.watch(cataquiApiCookieJarProvider).requireValue;
  final unauthenticatedDio = ref.watch(unauthenticatedCataquiApiV1DioProvider);

  return CataquiApiV1DioFactory.create(
    appConfig: appConfig,
    languageTag: locale.languageTag,
    cookieJar: cookieJar,
    authInterceptor: AuthInterceptor(
      unauthenticatedDio: unauthenticatedDio,
      getCurrentSession: () => ref.read(appAuthStateProvider),
      getOrAuthenticateSession: () => ref.read(appAuthStateProvider.notifier).getOrAuthenticateSession(),
      refreshSession: () => ref.read(appAuthStateProvider.notifier).refreshSession(),
      refreshSessionInBackground: () => ref.read(appAuthStateProvider.notifier).refreshSessionInBackground(),
    ),
  );
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    authenticatedDio: ref.watch(authenticatedCataquiApiV1DioProvider),
    unauthenticatedDio: ref.watch(unauthenticatedCataquiApiV1DioProvider),
  );
}

@Riverpod(keepAlive: true)
Dio geosearchDio(Ref ref) {
  final appConfig = ref.read(appConfigProvider);
  final locale = ref.watch(appStateProvider.select((state) => state.currentLocale));

  final dio = Dio(
    BaseOptions(
      baseUrl: appConfig.geosearchUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, String>{
        Headers.acceptHeader: Headers.jsonContentType,
        Headers.contentTypeHeader: Headers.jsonContentType,
        'accept-language': locale.languageTag,
      },
    ),
  );
  if (appConfig.isDevelopment) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, logPrint: (object) => debugPrint(object.toString())),
    );
  }

  dio.interceptors.add(RateLimitInterceptor());
  dio.interceptors.add(
    GeosearchAccessTokenInterceptor(
      geosearchDio: dio,
      authRepository: ref.watch(authRepositoryProvider),
      readAuthenticatedUserId: () => ref.read(appAuthStateProvider)?.userId,
      getOrAuthenticateSession: () => ref.read(appAuthStateProvider.notifier).getOrAuthenticateSession(),
    ),
  );

  dio.interceptors.add(OfflineErrorDioInterceptor());

  ref.onDispose(() => dio.close(force: true));
  return dio;
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
    observers: [ref.watch(routeObserverProvider)],
    initialLocation: appStorage.hasCompletedOnboarding ? const FeedRoute().location : const OnboardingRoute().location,
    redirect: (context, state) {
      if (state.matchedLocation != const OnboardingRoute().location) return null;

      final hasCompletedOnboarding = ref.read(appStorageStateProvider).requireValue.hasCompletedOnboarding;
      if (!hasCompletedOnboarding) return null;

      return const FeedRoute().location;
    },
    routes: [
      $onboardingRoute,
      $posterOnboardingRoute,
      $feedRoute,
      $createJobDescriptionRoute,
      $createJobLocationRoute,
      $createJobPaymentRoute,
      $jobRoute,
    ],
  );
}

@Riverpod(keepAlive: true)
RouteObserver<ModalRoute<void>> routeObserver(Ref ref) {
  return RouteObserver<ModalRoute<void>>();
}

@Riverpod(keepAlive: true)
GlobalKey<NavigatorState> rootNavigatorKey(Ref ref) {
  return GlobalKey<NavigatorState>(debugLabel: 'root_navigator');
}

@Riverpod(keepAlive: true)
JobRepository jobRepository(Ref ref) {
  return JobRepository(
    authenticatedDio: ref.watch(authenticatedCataquiApiV1DioProvider),
    unauthenticatedDio: ref.watch(unauthenticatedCataquiApiV1DioProvider),
  );
}

@Riverpod(keepAlive: true)
GeosearchRepository geosearchRepository(Ref ref) {
  return GeosearchRepository(geosearchDio: ref.watch(geosearchDioProvider));
}

@riverpod
Whatsapp whatsapp(Ref ref) {
  return Whatsapp();
}

@riverpod
Telephony telephony(Ref ref) {
  return Telephony();
}
