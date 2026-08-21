import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/enums/create_job_morph_tag.dart';
import 'package:cataqui_app/widgets/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class CreateJobLocationView extends ConsumerStatefulWidget {
  const CreateJobLocationView({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<CreateJobLocationView> createState() => _CreateJobLocationViewState();
}

class _CreateJobLocationViewState extends ConsumerState<CreateJobLocationView> {
  final MateoTextController _searchTextController = MateoTextController();

  Color get _curvedArrowColor => switch (Theme.of(context).brightness) {
    Brightness.light => context.mateo.palette.neutral[5],
    Brightness.dark => throw UnsupportedError('CreateJobLocationView does not support dark mode.'),
  };

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return MateoView(
      backgroundColor: Colors.transparent,
      edgeFade: (top: null, bottom: MateoEdgeFadeStyle(color: context.mateo.colorScheme.background)),
      extendBodyBehindFooter: true,
      header: MateoViewHeader(
        title: i18n.createJob.location.title,
        leading: MateoFloatingActionButton(
          key: const ValueKey('create_job_location_back_button'),
          onPressed: context.pop,
          semanticLabel: i18n.createJob.location.backButtonSemanticLabel,
          backgroundColor: context.mateo.colorScheme.bottomSheet.background,
          foregroundColor: context.mateo.colorScheme.text.primary,
          borderSide: BorderSide.none,
          size: 50,
          iconSize: 20,
          iconBuilder: (state) =>
              MateoIcon.arrowLeft(width: state.iconSize, height: state.iconSize, color: state.foregroundColor),
        ),
      ),
      footer: MorphForeground(
        key: const ValueKey('create_job_location_search_foreground'),
        child: MateoTextField(
          key: const ValueKey('create_job_location_search_field'),
          controller: _searchTextController,
          placeholder: i18n.createJob.location.searchPlaceholder,
          variant: MateoTextFieldVariant.search,
          textInputAction: TextInputAction.search,
          onChanged: (_) {},
        ),
      ),
      bodySurfaceBuilder: (context, content) {
        return Morph(
          tag: CreateJobMorphTag.surface,
          curve: Curves.fastOutSlowIn,
          switchTransition: (child, animation) => FadeTransition(opacity: animation, child: child),
          switchThreshold: 0.2,
          child: Container(
            key: const ValueKey('create_job_location_surface'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.mateo.colorScheme.background,
              borderRadius: BorderRadius.circular(40),
            ),
            child: content,
          ),
        );
      },
      body: _buildContent(i18n),
    );
  }

  Widget _buildContent(Translations i18n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        key: const ValueKey('create_job_location_view_content'),
        children: [
          const SizedBox(height: 20),
          const UseCurrentLocationButton(key: ValueKey('create_job_current_location_button')),
          const SizedBox(height: 20),
          Expanded(
            child: Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Motion.list(
                      effects: const [
                        MoveMotionEffect(
                          begin: Offset(0, 30),
                          end: Offset.zero,
                          curve: Curves.easeOutCubic,
                          delay: Duration(milliseconds: 300),
                        ),
                        FadeInMotionEffect(curve: Curves.easeOutCubic, delay: Duration(milliseconds: 300)),
                      ],
                      child: Text(
                        i18n.createJob.location.emptyGuidance,
                        key: const ValueKey('create_job_location_empty_guidance'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.mateo.colorScheme.text.tertiary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
                    ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 150),
                        child: $Lotties.curvedArrowDraw(
                          key: const ValueKey('create_job_location_curved_arrow'),
                          height: 124,
                          duration: const Duration(milliseconds: 900),
                          playback: LottiePlayback.once,
                          delay: const Duration(milliseconds: 400),
                          overrides: CurvedArrowDrawOverrides(
                            rightArrowheadColor: _curvedArrowColor,
                            leftArrowheadColor: _curvedArrowColor,
                            continuousMainPathColor: _curvedArrowColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
