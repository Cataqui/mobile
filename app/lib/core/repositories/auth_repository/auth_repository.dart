import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/created_notp_intent_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  const AuthRepository({required this.authDio});

  final Dio authDio;

  Future<ApiEnvelopeDto<CreatedNotpIntentDto>> createNotpIntent({required AuthChannel channel}) async {
    final notpChannel = switch (channel) {
      .whatsapp => 'WHATSAPP',
    };

    final response = await authDio.post<Map<String, Object?>>(
      '/notp/intents',
      data: <String, String>{'channel': notpChannel},
    );

    return ApiEnvelopeDto<CreatedNotpIntentDto>.fromJson(
      response.data!,
      (json) => CreatedNotpIntentDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<NotpIntentExchangeResultDto>> exchangeNotpIntent({required String intentToken}) async {
    final response = await authDio.post<Map<String, Object?>>(
      '/notp/intents/exchange',
      data: <String, String>{'intentToken': intentToken},
    );

    return ApiEnvelopeDto<NotpIntentExchangeResultDto>.fromJson(
      response.data!,
      (json) => NotpIntentExchangeResultDto.fromApiJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<IssuedAuthSessionDto>> refreshSession({required String refreshToken}) async {
    final response = await authDio.post<Map<String, Object?>>(
      '/sessions/refresh',
      data: <String, String>{'refreshToken': refreshToken},
    );

    return ApiEnvelopeDto<IssuedAuthSessionDto>.fromJson(
      response.data!,
      (json) => IssuedAuthSessionDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<void> logoutCurrentSession({required String refreshToken}) async {
    await authDio.post<void>('/sessions/logout', data: <String, String>{'refreshToken': refreshToken});
  }
}
