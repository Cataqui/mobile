import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_job_state.g.dart';

@riverpod
class CreateJobState extends _$CreateJobState {
  @override
  CreateJobData build() => CreateJobData(currencyHint: ref.read(translationProvider).mainCurrencyCode);

  Future<JobDraftDto> createDraft() async {
    final descriptionText = state.descriptionText;

    if (descriptionText == null) throw StateError('A description is required to create a job draft.');
    if (state.isCreatingDraft) throw StateError('A job draft is already being created.');

    state = state.copyWith(isCreatingDraft: true);

    try {
      final response = await ref.read(jobRepositoryProvider).createDraft(description: descriptionText);
      final draft = response.data;
      if (ref.mounted) {
        state = state.copyWith(jobId: draft.jobId);
      }

      return draft;
    } finally {
      if (ref.mounted) state = state.copyWith(isCreatingDraft: false);
    }
  }

  void setDescription(String descriptionText) {
    final normalizedDescriptionText = descriptionText.isEmpty ? null : descriptionText;
    if (state.descriptionText == normalizedDescriptionText) return;

    state = state.copyWith(descriptionText: normalizedDescriptionText);
  }

  void setCurrencyHint(String currencyHint) {
    if (state.currencyHint == currencyHint) return;

    state = state.copyWith(currencyHint: currencyHint);
  }

  void setPaymentAmount(String paymentAmount) {
    if (state.paymentAmount == paymentAmount) return;

    state = state.copyWith(paymentAmount: paymentAmount);
  }
}
