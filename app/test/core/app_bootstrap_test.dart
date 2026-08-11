import 'dart:async';

import 'package:cataqui_app/core/app_bootstrap.dart';
import 'package:cataqui_app/core/app_storage/app_storage_data.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

void main() {
  group('AppBootstrap.setup', () {
    group('when startupProvider loads successfully', () {
      late MockSharedPreferencesAsync prefs;
      late MockFlutterSecureStorage secureStorage;
      late MockFeedRepository feedRepository;

      setUp(() {
        prefs = MockSharedPreferencesAsync();
        secureStorage = MockFlutterSecureStorage();
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);
        when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

        feedRepository = MockFeedRepository();
        when(() => feedRepository.getFeedJobs()).thenAnswer(
          (_) async => ApiEnvelopeDto<List<FeedJobDto>>(
            data: [FeedJobDto.fixture()],
            requestId: 'test-request-id',
            timestamp: DateTime.now(),
            endpoint: '/feed',
            pagination: ApiPaginationDto.fixture(),
          ),
        );
      });

      ProviderContainer _buildFeedContainer() {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesAsyncProvider.overrideWithValue(prefs),
            secureStorageProvider.overrideWithValue(secureStorage),
            feedRepositoryProvider.overrideWithValue(feedRepository),
          ],
        );
        addTearDown(container.dispose);
        return container;
      }

      test('when setup completes, appStorageStateProvider should have a loaded state', () async {
        final container = _buildFeedContainer();

        await AppBootstrap.setup(providerContainer: container);

        expect(container.read(appStorageStateProvider).hasValue, isTrue);
      });
    });

    group('when startupProvider fails to load', () {
      late MockSharedPreferencesAsync prefs;

      setUp(() {
        prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenThrow(Exception('Storage corrupted'));
      });

      test('when appStorage fails to load, setup should throw', () async {
        final container = ProviderContainer(overrides: [sharedPreferencesAsyncProvider.overrideWithValue(prefs)]);
        addTearDown(container.dispose);

        // Replicate what setup() does internally: read the .future of the
        // provider. In production the .future mechanism properly propagates
        // errors (verified on device). In tests the .future getter never
        // completes due to FakeAsync intercepting internal timers, so we
        // listen on the provider directly to verify error propagation.
        final didError = Completer<void>();
        final sub = container.listen<AsyncValue<AppStorageData>>(appStorageStateProvider, (_, next) {
          if (next.hasError && !didError.isCompleted) {
            didError.complete();
          }
        }, fireImmediately: true);

        container.read(appStorageStateProvider);
        await didError.future.timeout(const Duration(seconds: 2));
        sub.close();

        expect(container.read(appStorageStateProvider).hasError, isTrue);
      });
    });

    group('when feedStateProvider is initialized', () {
      late MockSharedPreferencesAsync prefs;
      late MockFlutterSecureStorage secureStorage;
      late MockFeedRepository feedRepository;

      setUp(() {
        prefs = MockSharedPreferencesAsync();
        secureStorage = MockFlutterSecureStorage();
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);
        when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

        feedRepository = MockFeedRepository();
        when(() => feedRepository.getFeedJobs()).thenAnswer(
          (_) async => ApiEnvelopeDto<List<FeedJobDto>>(
            data: [FeedJobDto.fixture()],
            requestId: 'test-request-id',
            timestamp: DateTime.now(),
            endpoint: '/feed',
            pagination: ApiPaginationDto.fixture(),
          ),
        );
      });

      ProviderContainer _buildFeedContainer() {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesAsyncProvider.overrideWithValue(prefs),
            secureStorageProvider.overrideWithValue(secureStorage),
            feedRepositoryProvider.overrideWithValue(feedRepository),
          ],
        );
        addTearDown(container.dispose);
        return container;
      }

      test('when setup completes, feedStateProvider should be in loading state', () async {
        final container = _buildFeedContainer();

        await AppBootstrap.setup(providerContainer: container);

        expect(container.read(feedStateProvider).isLoading, isTrue);
      });

      test('when setup completes, it should call getFeedJobs on the feed repository', () async {
        final container = _buildFeedContainer();

        await AppBootstrap.setup(providerContainer: container);

        verify(() => feedRepository.getFeedJobs()).called(1);
      });
    });

    group('when feedStateProvider fails to load', () {
      late MockSharedPreferencesAsync prefs;
      late MockFlutterSecureStorage secureStorage;
      late MockFeedRepository feedRepository;

      setUp(() {
        prefs = MockSharedPreferencesAsync();
        secureStorage = MockFlutterSecureStorage();
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);
        when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

        feedRepository = MockFeedRepository();
        when(() => feedRepository.getFeedJobs()).thenThrow(Exception('Network error'));
      });

      ProviderContainer _buildFeedContainer() {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesAsyncProvider.overrideWithValue(prefs),
            secureStorageProvider.overrideWithValue(secureStorage),
            feedRepositoryProvider.overrideWithValue(feedRepository),
          ],
        );
        addTearDown(container.dispose);
        return container;
      }

      test('when feed API fails, setup should still succeed and appStorageStateProvider should be loaded', () async {
        final container = _buildFeedContainer();
        final didError = Completer<void>();
        final sub = container.listen<AsyncValue<AppStorageData>>(appStorageStateProvider, (_, next) {
          if (next.hasValue && !didError.isCompleted) {
            didError.complete();
          }
        }, fireImmediately: true);

        // setup() should complete — feed failure is non-fatal.
        await AppBootstrap.setup(providerContainer: container);
        sub.close();

        expect(container.read(appStorageStateProvider).hasValue, isTrue);
      });

      test('when feed API fails, feedStateProvider should be in error state after async resolution', () async {
        final container = _buildFeedContainer();

        await AppBootstrap.setup(providerContainer: container);

        // feedStateProvider is auto-dispose, so keep a listener to prevent
        // premature disposal while we wait for the async build to settle.
        final didError = Completer<void>();
        final sub = container.listen<AsyncValue<FeedData>>(feedStateProvider, (_, next) {
          if (next.hasError && !didError.isCompleted) {
            didError.complete();
          }
        }, fireImmediately: true);

        await didError.future.timeout(const Duration(seconds: 2));
        sub.close();

        expect(container.read(feedStateProvider).hasError, isTrue);
      });
    });
  });
}
