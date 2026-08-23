import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/dtos/microservice_access_token_dto.dart';
import 'package:cataqui_app/core/dtos/registered_auth_intent_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  const AuthRepository({
    required this.authenticatedDio,
    required this.unauthenticatedDio,
    this.exchangeIntentTimeout = const Duration(seconds: 30),
  });

  final Dio authenticatedDio;
  final Dio unauthenticatedDio;
  final Duration exchangeIntentTimeout;

  Future<ApiEnvelopeDto<RegisteredAuthIntentDto>> registerInboundMessageAuthIntent({
    required AuthChannel channel,
  }) async {
    final inboundMessageAuthChannel = switch (channel) {
      AuthChannel.whatsapp => 'WHATSAPP',
    };

    final response = await unauthenticatedDio.post<Map<String, Object?>>(
      '/auth/inbound-message/intents',
      data: <String, String>{'channel': inboundMessageAuthChannel},
    );

    return ApiEnvelopeDto<RegisteredAuthIntentDto>.fromJson(
      response.data!,
      (json) => RegisteredAuthIntentDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<IssuedAuthSessionDto>> exchangeInboundMessageAuthIntent({
    required String intentToken,
    Future<void>? timeoutStart,
  }) async {
    final exchangeStopwatch = Stopwatch();

    if (timeoutStart == null) {
      exchangeStopwatch.start();
    } else {
      unawaited(timeoutStart.then((_) => exchangeStopwatch.start()));
    }

    while (true) {
      final response = await unauthenticatedDio.post<Map<String, Object?>>(
        '/auth/inbound-message/intents/exchange',
        data: <String, String>{'intentToken': intentToken},
      );

      final envelope = ApiEnvelopeDto<AuthIntentExchangeResultDto>.fromJson(
        response.data!,
        (json) => AuthIntentExchangeResultDto.fromApiJson(json! as Map<String, Object?>),
      );

      switch (envelope.data) {
        case PendingAuthIntentExchangeDto(:final retryAfterSeconds):
          await Future<void>.delayed(Duration(seconds: retryAfterSeconds));

          if (exchangeStopwatch.isRunning && exchangeStopwatch.elapsed >= exchangeIntentTimeout) {
            throw TimeoutException(
              'Auth intent exchange did not complete within $exchangeIntentTimeout.',
              exchangeIntentTimeout,
            );
          }

        case final IssuedAuthSessionDto issuedSession:
          return ApiEnvelopeDto<IssuedAuthSessionDto>(
            data: issuedSession,
            requestId: envelope.requestId,
            timestamp: envelope.timestamp,
            endpoint: envelope.endpoint,
            pagination: envelope.pagination,
          );
      }
    }
  }

  Future<ApiEnvelopeDto<IssuedAuthSessionDto>> refreshSession({required String refreshToken}) async {
    final response = await unauthenticatedDio.post<Map<String, Object?>>(
      '/auth/sessions/refresh',
      data: <String, String>{'refreshToken': refreshToken},
    );

    return ApiEnvelopeDto<IssuedAuthSessionDto>.fromJson(
      response.data!,
      (json) => IssuedAuthSessionDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<MicroserviceAccessTokenDto>> createGeosearchAccessToken() async {
    final response = await authenticatedDio.post<Map<String, Object?>>('/auth/microservices/geosearch');

    return ApiEnvelopeDto<MicroserviceAccessTokenDto>.fromJson(
      response.data!,
      (json) => MicroserviceAccessTokenDto.fromJson(json! as Map<String, Object?>),
    );
  }
}
