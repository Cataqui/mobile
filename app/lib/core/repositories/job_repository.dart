import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:dio/dio.dart';

class JobRepository {
  const JobRepository({required this.dio});

  final Dio dio;

  Future<ApiEnvelopeDto<JobDto>> getJob({required String jobId, required AppLocale locale}) async {
    final response = await dio.get<Map<String, Object?>>(
      '/job/$jobId',
      options: Options(headers: <String, String>{
        'accept-language': locale.languageTag,
      }),
    );

    return ApiEnvelopeDto<JobDto>.fromJson(
      response.data!,
      (json) => JobDto.fromJson(json! as Map<String, Object?>),
    );
  }
}
