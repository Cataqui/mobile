import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'job_creation_flow_state.g.dart';

@riverpod
class JobCreationFlowState extends _$JobCreationFlowState {
  @override
  JobCreationFlowData build() => const JobCreationFlowData();

  Future<JobDraftDto> createDraft() async {
    final descriptionText = state.descriptionText;

    if (descriptionText == null) {
      throw StateError('A description is required to create a job draft.');
    }

    final response = await ref.read(jobRepositoryProvider).createDraft(description: descriptionText);
    return response.data;
  }

  void setDescription(String descriptionText) {
    final normalizedDescriptionText = descriptionText.isEmpty ? null : descriptionText;
    if (state.descriptionText == normalizedDescriptionText) return;

    state = state.copyWith(descriptionText: normalizedDescriptionText);
  }
}
