part of '../job_creation_flow_modal.dart';

class _JobCreationFlowDescriptionStep extends _JobCreationFlowStep {
  const _JobCreationFlowDescriptionStep({super.key});

  @override
  ConsumerState<_JobCreationFlowDescriptionStep> createState() => _JobCreationFlowDescriptionStepState();

  @override
  bool shouldShowContinue(JobCreationFlowData flowData) => flowData.descriptionText?.trim().isNotEmpty ?? false;

  @override
  bool canContinue(JobCreationFlowData flowData) => (flowData.descriptionText?.trim().length ?? 0) >= 10;

  @override
  void showCannotContinueFeedback(BuildContext context, WidgetRef ref) {
    final i18n = ref.read(translationProvider);
    MateoToast.show(context, message: i18n.jobCreationFlow.steps.description.tooShortError, type: MateoToastType.error);
  }
}

class _JobCreationFlowDescriptionStepState extends ConsumerState<_JobCreationFlowDescriptionStep> {
  late final MateoTextInputController _descriptionController;

  void _setDescription(String descriptionText) {
    ref.read(jobCreationFlowStateProvider.notifier).setDescription(descriptionText);
  }

  @override
  void initState() {
    super.initState();
    final descriptionText = ref.read(jobCreationFlowStateProvider).descriptionText;

    _descriptionController = MateoTextInputController(text: descriptionText);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final edgeFadeStyle = MateoEdgeFadeStyle(color: context.mateo.colorScheme.bottomSheet.background).resolve(context);
    final bottomEdgeFadeHeight = edgeFadeStyle.height!;

    return Stack(
      key: const ValueKey('job_creation_flow_description_step_stack'),
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            key: const ValueKey('job_creation_flow_prompt_scroll_view'),
            padding: EdgeInsets.only(top: JobCreationFlowModal.topEdgeFadeHeight - 35, bottom: bottomEdgeFadeHeight),
            child: MateoTextInput(
              controller: _descriptionController,
              placeholder: i18n.jobCreationFlow.steps.description.placeholder,
              variant: MateoTextInputVariant.quiet,
              multiline: true,
              autofocus: true,
              textStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: context.mateo.colorScheme.text.primary,
              ),
              keyboardType: TextInputType.multiline,
              scrollPadding: EdgeInsets.only(bottom: bottomEdgeFadeHeight),
              onChanged: _setDescription,
            ),
          ),
        ),
        Positioned(
          key: const ValueKey('job_creation_flow_top_edge_fade_layer'),
          top: 0,
          left: 0,
          right: 0,
          child: MateoEdgeFade(
            key: const ValueKey('job_creation_flow_top_edge_fade'),
            position: MateoEdgeFadePosition.top,
            style: edgeFadeStyle.copyWith(height: JobCreationFlowModal.topEdgeFadeHeight),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MateoEdgeFade(
            key: const ValueKey('job_creation_flow_bottom_edge_fade'),
            position: MateoEdgeFadePosition.bottom,
            style: edgeFadeStyle,
          ),
        ),
        Positioned(
          key: const ValueKey('job_creation_flow_title_layer'),
          top: 0,
          left: 0,
          child: SizedBox(
            height: 44,
            child: Align(
              alignment: AlignmentGeometry.centerLeft,
              child: Text(
                i18n.jobCreationFlow.steps.description.title,
                key: const ValueKey('job_creation_flow_title'),
                style: TextStyle(
                  color: context.mateo.colorScheme.text.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
