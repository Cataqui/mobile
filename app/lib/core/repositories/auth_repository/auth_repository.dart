import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/registered_auth_intent_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  const AuthRepository({required this.dio});

  final Dio dio;

  Future<ApiEnvelopeDto<RegisteredAuthIntentDto>> registerAuthIntent({required AuthChannel channel}) async {
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
}
