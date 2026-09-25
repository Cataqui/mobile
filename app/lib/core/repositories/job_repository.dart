import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:dio/dio.dart';

class JobRepository {
  const JobRepository({required this.authenticatedDio, required this.unauthenticatedDio});

  final Dio authenticatedDio;
  final Dio unauthenticatedDio;

  Future<ApiEnvelopeDto<JobDto>> createJob({
    required String description,
    required double latitude,
    required double longitude,
    required String locationTitle,
    required JobContactMethod contactMethod,
    required String contactIdentifier,
    required String idempotencyKey,
  }) async {
    final response = await authenticatedDio.post<Map<String, Object?>>(
      '/jobs',
      data: <String, Object?>{
        'description': description,
        'location': <String, Object?>{'title': locationTitle, 'latitude': latitude, 'longitude': longitude},
        'contact': <String, Object?>{'method': contactMethod.jsonValue, 'identifier': contactIdentifier},
      },
      options: Options(headers: <String, String>{'Idempotency-Key': idempotencyKey}),
    );

    return ApiEnvelopeDto<JobDto>.fromJson(response.data!, (json) => JobDto.fromJson(json! as Map<String, Object?>));
  }

  Future<ApiEnvelopeDto<JobDto>> getJob({required String jobId}) async {
    // return ApiEnvelopeDto.fixture(data: .fixture());
    final response = await unauthenticatedDio.get<Map<String, Object?>>('/jobs/$jobId');

    return ApiEnvelopeDto<JobDto>.fromJson(response.data!, (json) => JobDto.fromJson(json! as Map<String, Object?>));
  }

  Future<ApiEnvelopeDto<JobContactDto>> getJobContact({required String jobId, required String contactId}) async {
    final response = await unauthenticatedDio.get<Map<String, Object?>>('/jobs/$jobId/contact/$contactId');

    return ApiEnvelopeDto<JobContactDto>.fromJson(
      response.data!,
      (json) => JobContactDto.fromJson(json! as Map<String, Object?>),
    );
  }
}
