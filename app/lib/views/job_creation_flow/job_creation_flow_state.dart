import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'job_creation_flow_state.g.dart';

@riverpod
class JobCreationFlowState extends _$JobCreationFlowState {
  @override
  JobCreationFlowData build() => const JobCreationFlowData();

  void setDescription(String descriptionText) {
    final normalizedDescriptionText = descriptionText.isEmpty ? null : descriptionText;
    if (state.descriptionText == normalizedDescriptionText) return;

    state = state.copyWith(descriptionText: normalizedDescriptionText);
  }
}
