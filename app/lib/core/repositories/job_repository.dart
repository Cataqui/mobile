import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:dio/dio.dart';

class JobRepository {
  const JobRepository({required this.authenticatedDio, required this.unauthenticatedDio});

  final Dio authenticatedDio;
  final Dio unauthenticatedDio;

  Future<ApiEnvelopeDto<JobDraftDto>> createDraft({required String description}) async {
    return ApiEnvelopeDto.fixture(data: JobDraftDto.fixture());
    final response = await authenticatedDio.post<Map<String, Object?>>(
      '/jobs/drafts',
      data: <String, String>{'description': description},
    );

    return ApiEnvelopeDto<JobDraftDto>.fromJson(
      response.data!,
      (json) => JobDraftDto.fromJson(json! as Map<String, Object?>),
    );
  }

  Future<ApiEnvelopeDto<JobDraftDto>> updateDraft({
    required String jobId,
    String? description,
    ({JobContactMethod contactMethod, String identifier})? contact,
    ({
      String? street,
      String neighborhood,
      String city,
      String state,
      String country,
      double latitude,
      double longitude,
    })?
    location,
    JobType? type,
    ({
      JobPaymentType type,
      num? minAmount,
      num? maxAmount,
      String? note,
      JobPaymentAmountPeriod amountPeriod,
      String currency,
    })?
    payment,
  }) async {
    var paymentMinimumAmount = payment?.minAmount;
    var paymentMaximumAmount = payment?.maxAmount;

    if (paymentMinimumAmount != null && paymentMaximumAmount != null && paymentMaximumAmount < paymentMinimumAmount) {
      final originalPaymentMinimumAmount = paymentMinimumAmount;
      paymentMinimumAmount = paymentMaximumAmount;
      paymentMaximumAmount = originalPaymentMinimumAmount;
    }

    final response = await authenticatedDio.patch<Map<String, Object?>>(
      '/jobs/drafts/$jobId',
      data: <String, Object?>{
        if (description != null) 'description': description,
        if (contact != null)
          'contact': <String, Object?>{
            'contactMethod': contact.contactMethod.jsonValue,
            'identifier': contact.identifier,
          },
        if (location != null)
          'location': <String, Object?>{
            if (location.street != null) 'street': location.street,
            'neighborhood': location.neighborhood,
            'city': location.city,
            'state': location.state,
            'country': location.country,
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
        if (type != null) 'type': type.jsonValue,
        if (payment != null)
          'payment': <String, Object?>{
            'type': payment.type.jsonValue,
            if (paymentMinimumAmount != null) 'minAmount': paymentMinimumAmount,
            if (paymentMaximumAmount != null) 'maxAmount': paymentMaximumAmount,
            if (payment.note != null) 'note': payment.note,
            'amountPeriod': payment.amountPeriod.jsonValue,
            'currency': payment.currency,
          },
      },
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
