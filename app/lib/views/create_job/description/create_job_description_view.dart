import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/enums/create_job_morph_tag.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class CreateJobDescriptionView extends ConsumerStatefulWidget {
  const CreateJobDescriptionView({super.key});

  static const topEdgeFadeHeight = 140.0;
  static const surfaceHorizontalMargin = 3.0;
  static const surfaceContentPadding = 20.0;
  static const titleHeight = 21.0;
  static const promptTopPadding = 50.0;
  static const navigationButtonSize = 44.0;

  @override
  ConsumerState<CreateJobDescriptionView> createState() => _CreateJobDescriptionViewState();
}

class _CreateJobDescriptionViewState extends ConsumerState<CreateJobDescriptionView> with RouteAware {
  final ScrollController _descriptionScrollController = ScrollController();
  late final MateoTextInputController _descriptionTextController;
  late final ControlledVisibilityController _continueButtonVisibilityController;
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
    if (descriptionText.isNotEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (ref.read(createJobStateProvider).descriptionText?.isNotEmpty ?? false)) return;
      if (_descriptionScrollController.hasClients) _descriptionScrollController.jumpTo(0);
    });
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

      unawaited(CreateJobPaymentRoute(jobId: draft.jobId).push<void>(context));
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

    _descriptionTextController = MateoTextInputController(text: descriptionText);
    _continueButtonVisibilityController = ControlledVisibilityController();
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

    return Scaffold(
      key: const ValueKey('create_job_scaffold'),
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Builder(
        builder: (context) => Padding(
          key: const ValueKey('create_job_description_view'),
          padding: const EdgeInsets.symmetric(horizontal: CreateJobDescriptionView.surfaceHorizontalMargin),
          child: Align(
            alignment: AlignmentGeometry.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.92,
              widthFactor: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Morph(
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
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Stack(
                          key: const ValueKey('create_job_prompt_fades'),
                          children: [
                            Positioned.fill(
                              child: MorphDescendant(
                                flightBehavior: MorphDescendantFlightBehavior.snapshot,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final centeredCaretDy =
                                        (CreateJobDescriptionView.topEdgeFadeHeight +
                                            constraints.maxHeight -
                                            bottomEdgeFadeHeight) /
                                        2;
                                    final bottomPaddingForCenteredCaret = constraints.maxHeight - centeredCaretDy;
                                    final minimumBottomPadding =
                                        bottomEdgeFadeHeight + CreateJobDescriptionView.surfaceContentPadding;

                                    return SingleChildScrollView(
                                      key: const ValueKey('create_job_prompt_scroll_view'),
                                      controller: _descriptionScrollController,
                                      child: Padding(
                                        key: const ValueKey('create_job_description_view_content'),
                                        padding: EdgeInsets.fromLTRB(
                                          CreateJobDescriptionView.surfaceContentPadding,
                                          CreateJobDescriptionView.surfaceContentPadding +
                                              CreateJobDescriptionView.titleHeight +
                                              CreateJobDescriptionView.promptTopPadding,
                                          CreateJobDescriptionView.surfaceContentPadding,
                                          math.max(bottomPaddingForCenteredCaret, minimumBottomPadding),
                                        ),
                                        child: Material(
                                          child: MateoTextInput(
                                            controller: _descriptionTextController,
                                            placeholder: i18n.createJob.description.placeholder,
                                            variant: MateoTextInputVariant.quiet,
                                            multiline: true,
                                            autofocus: true,
                                            textStyle: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                              color: context.mateo.colorScheme.text.primary,
                                            ),
                                            keyboardType: TextInputType.multiline,
                                            scrollPadding: EdgeInsets.only(
                                              top: centeredCaretDy,
                                              bottom: bottomPaddingForCenteredCaret,
                                            ),
                                            editable: !isCreatingDraft,
                                            unfocusOnTapOutside: false,
                                            onChanged: _handleDescriptionChanged,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              key: const ValueKey('create_job_top_edge_fade_layer'),
                              top: 0,
                              left: 0,
                              right: 0,
                              child: MateoEdgeFade(
                                key: const ValueKey('create_job_top_edge_fade'),
                                position: MateoEdgeFadePosition.top,
                                style: edgeFadeStyle
                                    .resolve(context, position: MateoEdgeFadePosition.top)
                                    .copyWith(mainAxisExtent: CreateJobDescriptionView.topEdgeFadeHeight),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: MateoEdgeFade(
                                key: const ValueKey('create_job_bottom_edge_fade'),
                                position: MateoEdgeFadePosition.bottom,
                                style: bottomEdgeFadeStyle,
                              ),
                            ),
                            Positioned(
                              right: CreateJobDescriptionView.surfaceContentPadding,
                              bottom: bottomSafeInset + 28,
                              child: MorphDescendant(
                                flightBehavior: MorphDescendantFlightBehavior.snapshot,
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
                                    backgroundColor: context.mateo.palette.primary[9],
                                    foregroundColor: context.mateo.palette.primary[1],
                                    borderSide: BorderSide.none,
                                    size: 53,
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

                            Positioned(
                              top:
                                  CreateJobDescriptionView.surfaceContentPadding +
                                  (CreateJobDescriptionView.navigationButtonSize -
                                          CreateJobDescriptionView.titleHeight) /
                                      2,
                              left: CreateJobDescriptionView.surfaceContentPadding,
                              right: CreateJobDescriptionView.surfaceContentPadding,
                              height: CreateJobDescriptionView.titleHeight,
                              child: Align(
                                alignment: AlignmentGeometry.center,
                                child: Text(
                                  i18n.createJob.description.title,
                                  key: const ValueKey('create_job_title'),
                                  style: TextStyle(
                                    color: context.mateo.colorScheme.text.primary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: CreateJobDescriptionView.surfaceContentPadding,
                    left: CreateJobDescriptionView.surfaceContentPadding,
                    child: Morph(
                      tag: CreateJobMorphTag.navigationButton,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: MateoFloatingActionButton(
                        key: const ValueKey('create_job_close_button'),
                        size: CreateJobDescriptionView.navigationButtonSize,
                        tapTargetSize: CreateJobDescriptionView.navigationButtonSize,
                        iconSize: 16,
                        semanticLabel: MaterialLocalizations.of(context).closeButtonLabel,
                        iconBuilder: (state) => MateoIcon.cross(
                          width: state.iconSize,
                          height: state.iconSize,
                          color: state.foregroundColor,
                        ),
                        onPressed: context.pop,
                      ),
                    ),
                  ),
                ],
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
