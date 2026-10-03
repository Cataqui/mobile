import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/created_notp_intent_dto.dart';
import 'package:cataqui_app/core/dtos/microservice_access_token_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  const AuthRepository({required this.authenticatedDio, required this.unauthenticatedDio});

  final Dio authenticatedDio;
  final Dio unauthenticatedDio;

  Future<ApiEnvelopeDto<CreatedNotpIntentDto>> createNotpIntent({required AuthChannel channel}) async {
    final notpChannel = switch (channel) {
      .whatsapp => 'WHATSAPP',
    };

    final response = await unauthenticatedDio.post<Map<String, Object?>>(
      '/auth/notp/intents',
      data: <String, String>{'channel': notpChannel},
    );

    return ApiEnvelopeDto<CreatedNotpIntentDto>.fromJson(
      response.data!,
      (json) => CreatedNotpIntentDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<NotpIntentExchangeResultDto>> exchangeNotpIntent({required String intentToken}) async {
    final response = await unauthenticatedDio.post<Map<String, Object?>>(
      '/auth/notp/intents/exchange',
      data: <String, String>{'intentToken': intentToken},
    );

    return ApiEnvelopeDto<NotpIntentExchangeResultDto>.fromJson(
      response.data!,
      (json) => NotpIntentExchangeResultDto.fromApiJson(json! as Map<String, Object?>),
    );
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

  Future<void> logoutCurrentSession({required String refreshToken}) async {
    await unauthenticatedDio.post<void>('/auth/sessions/logout', data: <String, String>{'refreshToken': refreshToken});
  }

  Future<ApiEnvelopeDto<MicroserviceAccessTokenDto>> createMapsAccessToken() async {
    final response = await authenticatedDio.post<Map<String, Object?>>('/auth/microservices/maps');

    return ApiEnvelopeDto<MicroserviceAccessTokenDto>.fromJson(
      response.data!,
      (json) => MicroserviceAccessTokenDto.fromJson(json! as Map<String, Object?>),
    );
  }
}
