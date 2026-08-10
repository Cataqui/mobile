import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/dtos/registered_auth_intent_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  const AuthRepository({required this.dio, this.exchangeIntentTimeout = const Duration(seconds: 30)});

  final Dio dio;
  final Duration exchangeIntentTimeout;

  Future<ApiEnvelopeDto<RegisteredAuthIntentDto>> registerInboundMessageAuthIntent({
    required AuthChannel channel,
  }) async {
    final inboundMessageAuthChannel = switch (channel) {
      AuthChannel.whatsapp => 'WHATSAPP',
    };

    final response = await dio.post<Map<String, Object?>>(
      '/auth/inbound-message/intents',
      data: <String, String>{'channel': inboundMessageAuthChannel},
    );

    return ApiEnvelopeDto<RegisteredAuthIntentDto>.fromJson(
      response.data!,
      (json) => RegisteredAuthIntentDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<IssuedAuthSessionDto>> exchangeInboundMessageAuthIntent({required String intentToken}) async {
    final exchangeStopwatch = Stopwatch()..start();

    while (true) {
      final response = await dio.post<Map<String, Object?>>(
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

          if (exchangeStopwatch.elapsed >= exchangeIntentTimeout) {
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
}
