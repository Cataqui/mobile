part of '../job_creation_flow_modal.dart';

abstract class _JobCreationFlowStep extends ConsumerStatefulWidget {
  const _JobCreationFlowStep({required this.continueInProgressListenable, super.key});

  final ValueListenable<bool> continueInProgressListenable;

  bool shouldShowContinueButton(JobCreationFlowData flowData);

  Future<({bool proceed})> tryContinue(BuildContext context, WidgetRef ref);

  Future<void> continueFlow({
    required BuildContext context,
    required WidgetRef ref,
    required SequenceController sequenceController,
  }) async {
    final result = await tryContinue(context, ref);

    if (!result.proceed || !context.mounted) return;
    sequenceController.next();
  }
}
