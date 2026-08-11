import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:dio/dio.dart';

class FeedRepository {
  const FeedRepository({required this.unauthenticatedDio});

  final Dio unauthenticatedDio;

  Future<ApiEnvelopeDto<List<FeedJobDto>>> getFeedJobs({String? cursor}) async {
    final response = await unauthenticatedDio.get<Map<String, Object?>>(
      '/feed',
      queryParameters: <String, Object?>{if (cursor != null) 'cursor': cursor},
    );

    return ApiEnvelopeDto<List<FeedJobDto>>.fromJson(
      response.data!,
      (json) => (json! as List<Object?>).map((item) => FeedJobDto.fromJson(item! as Map<String, Object?>)).toList(),
    );
  }
}
