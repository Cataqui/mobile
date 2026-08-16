import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_job_data.freezed.dart';

@freezed
abstract class CreateJobData with _$CreateJobData {
  const factory CreateJobData({
    String? descriptionText,
    String? jobId,
    @Default('0') String paymentAmount,
    @Default(false) bool isCreatingDraft,
  }) = _CreateJobData;
}
