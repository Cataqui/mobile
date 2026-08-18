import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_job_state.g.dart';

@riverpod
class CreateJobState extends _$CreateJobState {
  @override
  CreateJobData build() => CreateJobData(currencyCode: ref.read(translationProvider).mainCurrencyCode);

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

  void setCurrencyCode(String currencyCode) {
    if (state.currencyCode == currencyCode) return;

    state = state.copyWith(currencyCode: currencyCode);
  }

  void setPaymentMinimumAmount(String paymentMinimumAmount) {
    if (state.paymentMinimumAmount == paymentMinimumAmount) return;

    state = state.copyWith(paymentMinimumAmount: paymentMinimumAmount);
  }

  void setPaymentMaximumAmount(String paymentMaximumAmount) {
    if (state.paymentMaximumAmount == paymentMaximumAmount) return;

    state = state.copyWith(paymentMaximumAmount: paymentMaximumAmount);
  }

  void setPaymentType(JobPaymentType paymentType) {
    if (state.paymentType == paymentType) return;

    state = state.copyWith(paymentType: paymentType);
  }
}
