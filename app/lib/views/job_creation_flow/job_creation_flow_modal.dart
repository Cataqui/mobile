import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_data.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'steps/job_creation_flow_description_step.dart';
part 'steps/job_creation_flow_step.dart';

class JobCreationFlowModal extends ConsumerStatefulWidget {
  const JobCreationFlowModal({super.key});

  static const topEdgeFadeHeight = 80.0;

  static Future<void> show(BuildContext context) async {
    await MateoBottomSheet.show<void>(
      context,
      child: const JobCreationFlowModal(),
      draggable: false,
      resistance: false,
      shouldDismiss: (source) => source == MateoBottomSheetDismissSource.closeButton,
    );
  }

  @override
  ConsumerState<JobCreationFlowModal> createState() => _JobCreationFlowModalState();
}

class _JobCreationFlowModalState extends ConsumerState<JobCreationFlowModal> {
  late final SequenceController _sequenceController;
  late final ControlledVisibilityController _continueVisibilityController;
  late final List<_JobCreationFlowStep> _steps;

  _JobCreationFlowStep get _activeStep => _steps[_sequenceController.index];

  void _handleContinueVisibility(bool shouldShowContinue) {
    if (shouldShowContinue) {
      _continueVisibilityController.show();
      return;
    }

    _continueVisibilityController.hide();
  }

  void _handleStepChanged() {
    setState(() {});
    _handleContinueVisibility(_activeStep.shouldShowContinue(ref.read(jobCreationFlowStateProvider)));
  }

  @override
  void initState() {
    super.initState();
    _sequenceController = SequenceController()..addListener(_handleStepChanged);
    _continueVisibilityController = ControlledVisibilityController();
    _steps = const [_JobCreationFlowDescriptionStep(key: ValueKey('job_creation_flow_description_step'))];

    _handleContinueVisibility(_activeStep.shouldShowContinue(ref.read(jobCreationFlowStateProvider)));
  }

  @override
  void dispose() {
    _sequenceController
      ..removeListener(_handleStepChanged)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    ref.listen<JobCreationFlowData>(jobCreationFlowStateProvider, (_, flowData) {
      _handleContinueVisibility(_activeStep.shouldShowContinue(flowData));
    });

    return Stack(
      children: [
        Positioned.fill(
          child: Sequence(
            key: const ValueKey('job_creation_flow_sequence'),
            controller: _sequenceController,
            children: _steps,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: ControlledVisibility(
            key: const ValueKey('job_creation_flow_continue_visibility'),
            controller: _continueVisibilityController,
            showDuration: const Duration(milliseconds: 240),
            hideDuration: const Duration(milliseconds: 160),
            showTransition: _buildContinueShowTransition,
            hideTransition: _buildContinueHideTransition,
            unmount: true,
            child: MateoFloatingActionButton(
              key: const ValueKey('job_creation_flow_continue_button'),
              onPressed: () {
                _activeStep.continueFlow(context: context, ref: ref, sequenceController: _sequenceController);
              },
              semanticLabel: i18n.jobCreationFlow.continueButtonSemanticLabel,
              backgroundColor: context.mateo.palette.primary[9],
              foregroundColor: context.mateo.palette.primary[1],
              borderSide: BorderSide.none,
              iconBuilder: (state) => MateoIcon.arrowRight(
                key: const ValueKey('job_creation_flow_continue_icon'),
                width: state.iconSize,
                height: state.iconSize,
                color: state.foregroundColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueShowTransition(Widget child, Animation<double> animation) {
    final scale = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));
    final opacity = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

    return ScaleTransition(
      key: const ValueKey('job_creation_flow_continue_show_scale'),
      scale: scale,
      child: FadeTransition(opacity: opacity, child: child),
    );
  }

  Widget _buildContinueHideTransition(Widget child, Animation<double> animation) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInCubic);
    final scale = Tween<double>(begin: 0.8, end: 1).animate(curvedAnimation);

    return ScaleTransition(
      key: const ValueKey('job_creation_flow_continue_hide_scale'),
      scale: scale,
      child: FadeTransition(opacity: curvedAnimation, child: child),
    );
  }
}
