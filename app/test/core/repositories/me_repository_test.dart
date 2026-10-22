import 'package:cataqui_app/core/dtos/account_metadata_dto.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/me_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockDio authenticatedDio;
  late MeRepository repository;

  setUp(() {
    authenticatedDio = MockDio();
    repository = MeRepository(authenticatedDio: authenticatedDio);
    when(() => authenticatedDio.get<Map<String, Object?>>('/me/metadata')).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: <String, Object?>{
          'data': <String, Object?>{'onboardingCompleted': false},
          'requestId': 'get-metadata-request',
          'timestamp': '2026-10-22T12:00:00.000Z',
          'endpoint': '/v1/me/metadata',
        },
        requestOptions: RequestOptions(path: '/me/metadata'),
      ),
    );
    when(() => authenticatedDio.patch<Map<String, Object?>>('/me/metadata', data: any(named: 'data'))).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: <String, Object?>{
          'data': <String, Object?>{'onboardingCompleted': true},
          'requestId': 'update-metadata-request',
          'timestamp': '2026-10-22T13:00:00.000Z',
          'endpoint': '/v1/me/metadata',
        },
        requestOptions: RequestOptions(path: '/me/metadata'),
      ),
    );
  });

  group('MeRepository', () {
    group('getMetadata', () {
      test('when requesting metadata, it should GET and parse the complete response envelope', () async {
        final envelope = await repository.getMetadata();

        verify(() => authenticatedDio.get<Map<String, Object?>>('/me/metadata')).called(1);
        expect(
          envelope,
          ApiEnvelopeDto<AccountMetadataDto>(
            data: AccountMetadataDto.fixture().copyWith(onboardingCompleted: false),
            requestId: 'get-metadata-request',
            timestamp: DateTime.parse('2026-10-22T12:00:00.000Z'),
            endpoint: '/v1/me/metadata',
          ),
        );
      });

      test('when the request fails, it should propagate the Dio exception', () async {
        final exception = DioException(requestOptions: RequestOptions(path: '/me/metadata'));
        when(() => authenticatedDio.get<Map<String, Object?>>('/me/metadata')).thenThrow(exception);

        await expectLater(repository.getMetadata(), throwsA(same(exception)));
      });
    });

    group('updateMetadata', () {
      for (final onboardingCompleted in [true, false]) {
        test('when updating onboardingCompleted=$onboardingCompleted, it should PATCH the exact value', () async {
          await repository.updateMetadata(onboardingCompleted: onboardingCompleted);

          verify(
            () => authenticatedDio.patch<Map<String, Object?>>(
              '/me/metadata',
              data: <String, Object?>{'onboardingCompleted': onboardingCompleted},
            ),
          ).called(1);
        });
      }

      test('when no value is supplied, it should send an empty PATCH body', () async {
        await repository.updateMetadata();

        verify(() => authenticatedDio.patch<Map<String, Object?>>('/me/metadata', data: <String, Object?>{})).called(1);
      });

      test('when receiving metadata, it should parse the server response and complete envelope', () async {
        final envelope = await repository.updateMetadata(onboardingCompleted: false);

        expect(
          envelope,
          ApiEnvelopeDto<AccountMetadataDto>(
            data: AccountMetadataDto.fixture().copyWith(onboardingCompleted: true),
            requestId: 'update-metadata-request',
            timestamp: DateTime.parse('2026-10-22T13:00:00.000Z'),
            endpoint: '/v1/me/metadata',
          ),
        );
      });

      test('when the request fails, it should propagate the Dio exception', () async {
        final exception = DioException(requestOptions: RequestOptions(path: '/me/metadata'));
        when(
          () => authenticatedDio.patch<Map<String, Object?>>('/me/metadata', data: any(named: 'data')),
        ).thenThrow(exception);

        await expectLater(repository.updateMetadata(onboardingCompleted: true), throwsA(same(exception)));
      });
    });
  });

  group('meRepositoryProvider', () {
    test('when reading the provider, it should inject the authenticated Dio', () {
      final container = ProviderContainer(
        overrides: [authenticatedCataquiApiV1DioProvider.overrideWithValue(authenticatedDio)],
      );
      addTearDown(container.dispose);

      expect(container.read(meRepositoryProvider).authenticatedDio, same(authenticatedDio));
    });
  });
}
