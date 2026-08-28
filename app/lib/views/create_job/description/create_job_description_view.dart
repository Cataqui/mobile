import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/enums/create_job_morph_tag.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class CreateJobDescriptionView extends ConsumerStatefulWidget {
  const CreateJobDescriptionView({super.key});

  static const topEdgeFadeHeight = 180.0;
  static const surfaceHorizontalMargin = 3.0;
  static const surfaceContentPadding = 20.0;
  static const titleHeight = 21.0;
  static const promptTopPadding = 50.0;
  static const navigationButtonSize = 44.0;
  static const continueButtonSize = 53.0;
  static const continueButtonBottomPadding = 20.0;

  @override
  ConsumerState<CreateJobDescriptionView> createState() => _CreateJobDescriptionViewState();
}

class _CreateJobDescriptionViewState extends ConsumerState<CreateJobDescriptionView> with RouteAware {
  final ScrollController _descriptionScrollController = ScrollController();
  late final MateoTextController _descriptionTextController;
  late final VisibilityController _continueButtonVisibilityController;
  late final RouteObserver<ModalRoute<void>> _routeObserver;
  ModalRoute<void>? _subscribedRoute;
  double _keyboardInsetBefore = 0;
  bool _shouldPreserveKeyboardInset = false;
  bool _hasReturned = false;
  bool _hasRestoredKeyboardInset = false;

  void _handleContinueVisibility(CreateJobData createJobData) {
    if (createJobData.descriptionText?.trim().isNotEmpty ?? false) {
      _continueButtonVisibilityController.show();
      return;
    }

    _continueButtonVisibilityController.hide();
  }

  void _handleDescriptionChanged(String descriptionText) {
    ref.read(createJobStateProvider.notifier).setDescription(descriptionText);
  }

  Future<void> _createDraftAndContinue(BuildContext context) async {
    if (ref.read(createJobStateProvider).isCreatingDraft) return;

    final i18n = ref.read(translationProvider);
    final descriptionLength = ref.read(createJobStateProvider).descriptionText?.trim().length ?? 0;

    if (descriptionLength < 10) {
      ref
          .read(appToastProvider)
          .maybeShowError(context, error: null, message: i18n.createJob.description.tooShortError);
      return;
    }

    if (descriptionLength > 10000) {
      ref
          .read(appToastProvider)
          .maybeShowError(
            context,
            error: null,
            message: i18n.createJob.description.tooLongError(characterCount: descriptionLength),
          );

      return;
    }

    try {
      final draft = await ref.read(createJobStateProvider.notifier).createDraft();
      if (!context.mounted) return;
      final descriptionScrollOffset = _descriptionScrollController.hasClients
          ? _descriptionScrollController.offset
          : null;
      final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

      if (keyboardInset > 0) {
        setState(() {
          _keyboardInsetBefore = keyboardInset;
          _shouldPreserveKeyboardInset = true;
          _hasReturned = false;
          _hasRestoredKeyboardInset = false;
        });
      }

      _descriptionTextController.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      if (!context.mounted) return;

      if (descriptionScrollOffset != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_descriptionScrollController.hasClients) return;
          _descriptionScrollController.jumpTo(
            descriptionScrollOffset.clamp(
              _descriptionScrollController.position.minScrollExtent,
              _descriptionScrollController.position.maxScrollExtent,
            ),
          );
        });
      }

      unawaited(CreateJobLocationRoute(jobId: draft.jobId).push<void>(context));
    } on Object catch (error) {
      if (context.mounted) {
        ref.read(appToastProvider).maybeShowError(context, error: error, message: i18n.createJob.createDraftError);
      }
    }
  }

  void _subscribeToRoute() {
    final route = ModalRoute.of(context);
    if (_subscribedRoute == route) return;

    _routeObserver.unsubscribe(this);
    _subscribedRoute = route;
    if (route != null) _routeObserver.subscribe(this, route);
  }

  @override
  void initState() {
    super.initState();
    final descriptionText = ref.read(createJobStateProvider).descriptionText;

    _descriptionTextController = MateoTextController(text: descriptionText);
    _continueButtonVisibilityController = VisibilityController();
    _routeObserver = ref.read(routeObserverProvider);
    _handleContinueVisibility(ref.read(createJobStateProvider));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToRoute();

    if (!_shouldPreserveKeyboardInset || !_hasReturned) return;
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      _hasRestoredKeyboardInset = true;
      return;
    }
    if (!_hasRestoredKeyboardInset) return;

    _shouldPreserveKeyboardInset = false;
    _hasReturned = false;
    _hasRestoredKeyboardInset = false;
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    _descriptionScrollController.dispose();
    _descriptionTextController.dispose();

    super.dispose();
  }

  @override
  void didPopNext() {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    setState(() {
      _hasReturned = true;
      _hasRestoredKeyboardInset = keyboardInset > 0;
    });
    _descriptionTextController.focus();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final isCreatingDraft = ref.watch(createJobStateProvider.select((createJobData) => createJobData.isCreatingDraft));
    final edgeFadeStyle = MateoEdgeFadeStyle(color: context.mateo.colorScheme.bottomSheet.background);
    final bottomEdgeFadeStyle = edgeFadeStyle.resolve(context, position: MateoEdgeFadePosition.bottom);
    final bottomEdgeFadeHeight = bottomEdgeFadeStyle.mainAxisExtent!;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final effectiveKeyboardInset = _shouldPreserveKeyboardInset
        ? math.max(_keyboardInsetBefore, keyboardInset)
        : keyboardInset;
    final bottomSafeInset = math.max(MediaQuery.viewPaddingOf(context).bottom, effectiveKeyboardInset);

    ref.listen<CreateJobData>(createJobStateProvider, (_, createJobData) {
      _handleContinueVisibility(createJobData);
    });

    return Padding(
      key: const ValueKey('create_job_description_view'),
      padding: const EdgeInsets.symmetric(horizontal: CreateJobDescriptionView.surfaceHorizontalMargin),
      child: Align(
        alignment: AlignmentGeometry.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.92,
          widthFactor: 1,
          child: MateoView(
            key: const ValueKey('create_job_scaffold'),
            backgroundColor: Colors.transparent,
            edgeFade: null,
            extendBodyBehindHeader: true,
            extendBodyBehindFooter: true,
            header: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: MateoViewHeader(
                title: i18n.createJob.description.title,
                leading: MateoFloatingActionButton(
                  key: const ValueKey('create_job_location_back_button'),
                  onPressed: context.pop,
                  semanticLabel: i18n.createJob.location.backButtonSemanticLabel,
                  borderSide: BorderSide.none,
                  size: 44,
                  iconSize: 17,
                  iconBuilder: (state) {
                    return MateoIcon.cross(width: state.iconSize, height: state.iconSize, color: state.foregroundColor);
                  },
                ),
              ),
            ),
            footer: Align(
              alignment: AlignmentGeometry.bottomRight,
              child: MorphForeground(
                key: const ValueKey('create_job_continue_foreground'),
                child: ControlledVisibility(
                  key: const ValueKey('create_job_continue_visibility'),
                  controller: _continueButtonVisibilityController,
                  showDuration: const Duration(milliseconds: 240),
                  hideDuration: const Duration(milliseconds: 160),
                  showTransition: _buildContinueShowTransition,
                  hideTransition: _buildContinueHideTransition,
                  unmount: true,
                  child: MateoFloatingActionButton(
                    key: const ValueKey('create_job_continue_button'),
                    onPressed: () => _createDraftAndContinue(context),
                    semanticLabel: i18n.createJob.continueButtonSemanticLabel,
                    backgroundColor: context.mateo.palette.accent[9],
                    foregroundColor: context.mateo.palette.accent[1],
                    borderSide: BorderSide.none,
                    size: CreateJobDescriptionView.continueButtonSize,
                    iconSize: 22,
                    iconBuilder: (state) => MateoIcon.arrowRight(
                      key: const ValueKey('create_job_continue_icon'),
                      width: state.iconSize,
                      height: state.iconSize,
                      color: state.foregroundColor,
                    ),
                  ),
                ),
              ),
            ),
            bodySurfaceBuilder: (context, content) {
              return Morph(
                tag: CreateJobMorphTag.surface,
                curve: Curves.easeOutCubic,
                duration: const Duration(milliseconds: 200),
                switchTransition: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Container(
                  key: const ValueKey('create_job_description_surface'),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: context.mateo.colorScheme.bottomSheet.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: content,
                ),
              );
            },
            body: MorphDescendant(
              key: const ValueKey('create_job_prompt_fades'),
              flightBehavior: MorphDescendantFlightBehavior.snapshot,
              child: MateoTextArea(
                key: const ValueKey('create_job_prompt_text_area'),
                controller: _descriptionTextController,
                scrollController: _descriptionScrollController,
                placeholder: i18n.createJob.description.placeholder,
                autofocus: true,
                textStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: context.mateo.colorScheme.text.primary,
                ),
                contentPadding: const EdgeInsets.fromLTRB(
                  CreateJobDescriptionView.surfaceContentPadding,
                  CreateJobDescriptionView.surfaceContentPadding +
                      CreateJobDescriptionView.titleHeight +
                      CreateJobDescriptionView.promptTopPadding,
                  CreateJobDescriptionView.surfaceContentPadding,
                  CreateJobDescriptionView.surfaceContentPadding,
                ),
                protectedBottomInset: math.max(
                  0,
                  bottomSafeInset +
                      CreateJobDescriptionView.continueButtonBottomPadding +
                      CreateJobDescriptionView.continueButtonSize -
                      bottomEdgeFadeHeight,
                ),
                topEdgeFadeStyle: edgeFadeStyle.copyWith(mainAxisExtent: CreateJobDescriptionView.topEdgeFadeHeight),
                bottomEdgeFadeStyle: bottomEdgeFadeStyle,
                editable: !isCreatingDraft,
                unfocusOnTapOutside: false,
                onChanged: _handleDescriptionChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueShowTransition(Widget child, Animation<double> animation) {
    final scale = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));
    final opacity = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

    return ScaleTransition(
      key: const ValueKey('create_job_continue_show_scale'),
      scale: scale,
      child: FadeTransition(opacity: opacity, child: child),
    );
  }

  Widget _buildContinueHideTransition(Widget child, Animation<double> animation) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInCubic);
    final scale = Tween<double>(begin: 0.8, end: 1).animate(curvedAnimation);

    return ScaleTransition(
      key: const ValueKey('create_job_continue_hide_scale'),
      scale: scale,
      child: FadeTransition(opacity: curvedAnimation, child: child),
    );
  }
}
