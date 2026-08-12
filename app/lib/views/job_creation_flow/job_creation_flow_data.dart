import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_creation_flow_data.freezed.dart';

@freezed
abstract class JobCreationFlowData with _$JobCreationFlowData {
  const factory JobCreationFlowData({String? descriptionText}) = _JobCreationFlowData;
}
