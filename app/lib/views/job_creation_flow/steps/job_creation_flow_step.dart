part of '../job_creation_flow_modal.dart';

abstract class _JobCreationFlowStep extends ConsumerStatefulWidget {
  const _JobCreationFlowStep({super.key});

  bool shouldShowContinue(JobCreationFlowData flowData);

  bool canContinue(JobCreationFlowData flowData);

  void showCannotContinueFeedback(BuildContext context, WidgetRef ref);

  void continueFlow({
    required BuildContext context,
    required WidgetRef ref,
    required SequenceController sequenceController,
  }) {
    final flowData = ref.read(jobCreationFlowStateProvider);

    if (!canContinue(flowData)) {
      showCannotContinueFeedback(context, ref);
      return;
    }

    sequenceController.next();
  }
}
