import 'package:cataqui_app/core/dtos/account_metadata_dto.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:dio/dio.dart';

class MeRepository {
  const MeRepository({required this.authenticatedDio});

  final Dio authenticatedDio;

  Future<ApiEnvelopeDto<AccountMetadataDto>> getMetadata() async {
    final response = await authenticatedDio.get<Map<String, Object?>>('/me/metadata');

    return ApiEnvelopeDto<AccountMetadataDto>.fromJson(
      response.data!,
      (json) => AccountMetadataDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<AccountMetadataDto>> updateMetadata({bool? onboardingCompleted}) async {
    final response = await authenticatedDio.patch<Map<String, Object?>>(
      '/me/metadata',
      data: <String, Object?>{if (onboardingCompleted != null) 'onboardingCompleted': onboardingCompleted},
    );

    return ApiEnvelopeDto<AccountMetadataDto>.fromJson(
      response.data!,
      (json) => AccountMetadataDto.fromJson(json! as Map<String, Object?>),
    );
  }
}
