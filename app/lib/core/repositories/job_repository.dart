import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:dio/dio.dart';

class JobRepository {
  const JobRepository({required this.authenticatedDio, required this.unauthenticatedDio});

  final Dio authenticatedDio;
  final Dio unauthenticatedDio;

  Future<ApiEnvelopeDto<JobDraftDto>> createDraft({required String description}) async {
    final response = await authenticatedDio.post<Map<String, Object?>>(
      '/jobs/drafts',
      data: <String, String>{'description': description},
    );

    return ApiEnvelopeDto<JobDraftDto>.fromJson(
      response.data!,
      (json) => JobDraftDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<JobDto>> getJob({required String jobId}) async {
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
