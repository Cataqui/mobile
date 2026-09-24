import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:cataqui_app/core/dtos/user_job.dart';
import 'package:cataqui_app/core/dtos/user_profile_dto.dart';
import 'package:dio/dio.dart';

class UserRepository {
  const UserRepository({required this.authenticatedDio});

  final Dio authenticatedDio;

  Future<ApiEnvelopeDto<List<UserJob>>> getMyPostedJobs({String? cursor}) async {
    final response = await authenticatedDio.get<Map<String, Object?>>(
      '/users/me/jobs',
      queryParameters: <String, Object?>{if (cursor != null) 'cursor': cursor},
    );

    return ApiEnvelopeDto<List<UserJob>>.fromJson(
      response.data!,
      (json) => (json! as List<Object?>).map((item) => UserJob.fromJson(item! as Map<String, Object?>)).toList(),
    );
  }

  Future<ApiEnvelopeDto<UserProfileDto>> getMyProfile() async {
    final response = await authenticatedDio.get<Map<String, Object?>>('/users/me');

    return ApiEnvelopeDto<UserProfileDto>.fromJson(
      response.data!,
      (json) => UserProfileDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<List<SavedContactDto>>> getContacts() async {
    final response = await authenticatedDio.get<Map<String, Object?>>('/users/me/contacts');

    // return ApiEnvelopeDto.fixture(
    //   data: [
    //     SavedContactDto.fixture(),
    //     SavedContactDto.fixture(),
    //     SavedContactDto.fixture(),
    //     SavedContactDto.fixture(),
    //     SavedContactDto.fixture(),
    //     SavedContactDto.fixture(),
    //     SavedContactDto.fixture(),
    //     SavedContactDto.fixture(),
    //   ],
    // );
    return ApiEnvelopeDto<List<SavedContactDto>>.fromJson(response.data!, (json) {
      return (json! as List<Object?>).map((item) => SavedContactDto.fromJson(item! as Map<String, Object?>)).toList();
    });
  }
}
