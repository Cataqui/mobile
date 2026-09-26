import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:cataqui_app/views/me/my_post/post_activation_slide_action/post_activation_landing_curve.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class PostActivationSlideAction extends ConsumerStatefulWidget {
  const PostActivationSlideAction({required this.jobId, required this.status, super.key});

  final String jobId;
  final JobStatus status;

  @override
  ConsumerState<PostActivationSlideAction> createState() => _PostActivationSlideActionState();
}

class _PostActivationSlideActionState extends ConsumerState<PostActivationSlideAction>
    with SingleTickerProviderStateMixin {
  static const _trackHeight = 62.0;
  static const _thumbDiameter = 52.0;
  static const _thumbInset = (_trackHeight - _thumbDiameter) / 2;
  static const _labelInset = 20.0;
  static const _settleDuration = Duration(milliseconds: 360);

  late final AnimationController _fillAnimationController = AnimationController(vsync: this)
    ..addListener(_onFillChanged);
  late JobStatus _visualStatus = widget.status;
  bool _isRequesting = false;
  bool _isReturning = false;
  bool _isDragging = false;
  double _lastHapticProgress = 0;

  JobStatus get _targetStatus => switch (_visualStatus) {
    JobStatus.active => JobStatus.archived,
    JobStatus.archived => JobStatus.active,
    JobStatus.unknown => throw UnsupportedError('Unknown job status has no slide action.'),
  };

  Color _colorForStatus(JobStatus status) {
    final theme = MateoTheme.of(context);
    if (status == JobStatus.archived) return theme.colorScheme.buttons.primary.success.background;

    return switch (theme.brightness) {
      Brightness.light => theme.palette.red[9],
      Brightness.dark => throw UnsupportedError('PostActivationSlideAction does not support dark mode.'),
    };
  }

  Color get _fillColor => _isReturning
      ? Color.lerp(_colorForStatus(_targetStatus), _colorForStatus(_visualStatus), 1 - _fillAnimationController.value)!
      : _colorForStatus(_visualStatus);

  double get _arrowRotation {
    if (_isReturning) {
      return _visualStatus == JobStatus.active
          ? math.pi * (1 - _fillAnimationController.value)
          : math.pi * _fillAnimationController.value;
    }
    return _visualStatus == JobStatus.active ? math.pi : 0;
  }

  void _onFillChanged() {
    final progress = _fillAnimationController.value;
    if (progress == _lastHapticProgress) return;
    _lastHapticProgress = progress;
    if (_isReturning) return;
    unawaited(HapticFeedback.selectionClick());
  }

  void _startDrag(DragStartDetails details, double trackWidth) {
    if (_isRequesting || _isReturning) return;

    final x = details.localPosition.dx;
    _isDragging = _visualStatus == JobStatus.archived
        ? x <= _thumbInset + _thumbDiameter + 20
        : x >= trackWidth - _thumbInset - _thumbDiameter - 20;
  }

  void _updateDrag(DragUpdateDetails details, double trackWidth) {
    if (!_isDragging || _isRequesting || _isReturning) return;

    final travel = trackWidth - _thumbDiameter - 2 * _thumbInset;
    if (travel <= 0) return;
    final direction = _visualStatus == JobStatus.archived ? 1 : -1;
    _fillAnimationController.value = (_fillAnimationController.value + details.delta.dx * direction / travel).clamp(
      0.0,
      1.0,
    );
    if (_fillAnimationController.value == 1) {
      _isDragging = false;
      unawaited(_submit());
    }
  }

  void _endDrag() {
    if (!_isDragging) return;
    _isDragging = false;
    unawaited(_resetFill());
  }

  Future<void> _resetFill() async {
    if (MediaQuery.disableAnimationsOf(context)) {
      _fillAnimationController.value = 0;
      return;
    }
    await _fillAnimationController.animateBack(0, duration: _settleDuration, curve: const PostActivationLandingCurve());
  }

  Future<void> _submit() async {
    if (_isRequesting || _isReturning) return;
    final targetStatus = _targetStatus;
    setState(() => _isRequesting = true);

    try {
      await ref.read(myPostStateProvider(widget.jobId).notifier).changeStatus(status: targetStatus);
      if (!mounted) return;

      unawaited(HapticFeedback.successNotification());
      setState(() {
        _visualStatus = targetStatus;
        _isRequesting = false;
        _isReturning = true;
      });
      await _resetFill();
      if (mounted) setState(() => _isReturning = false);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      final i18n = ref.read(translationProvider).me.myPost.activationSlide;
      ref
          .read(appToastProvider)
          .maybeShowError(
            context,
            error: error,
            message: targetStatus == JobStatus.active ? i18n.activateError : i18n.archiveError,
          );
      await _resetFill();
    }
  }

  Future<void> _completeSemanticsAction() async {
    if (_isRequesting || _isReturning) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fillAnimationController.value = 1;
    } else {
      await _fillAnimationController.animateTo(1, duration: _settleDuration, curve: const PostActivationLandingCurve());
    }
    if (mounted) await _submit();
  }

  @override
  void didUpdateWidget(covariant PostActivationSlideAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isRequesting && !_isReturning && widget.status != oldWidget.status) {
      _visualStatus = widget.status;
      _fillAnimationController.value = 0;
    }
  }

  @override
  void dispose() {
    _fillAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MateoTheme.of(context);
    final i18n = ref.watch(translationProvider).me.myPost.activationSlide;
    final label = _visualStatus == JobStatus.archived ? i18n.activate : i18n.archive;

    return Semantics(
      button: true,
      enabled: !_isRequesting && !_isReturning,
      label: label,
      value: _isRequesting ? i18n.loading : null,
      onTap: _isRequesting || _isReturning ? null : _completeSemanticsAction,
      child: ExcludeSemantics(
        child: MateoSurface(
          key: const ValueKey('post_activation_slide_action'),
          width: const .fill(),
          shape: const .capsule(),
          color: theme.colorScheme.background,
          elevation: .new(level: 1),
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: _trackHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                return GestureDetector(
                  behavior: .opaque,
                  onHorizontalDragStart: (details) => _startDrag(details, trackWidth),
                  onHorizontalDragUpdate: (details) => _updateDrag(details, trackWidth),
                  onHorizontalDragEnd: (_) => _endDrag(),
                  onHorizontalDragCancel: _endDrag,
                  child: AnimatedBuilder(
                    animation: _fillAnimationController,
                    builder: (context, _) {
                      final progress = _fillAnimationController.value;
                      final thumbTravel = trackWidth - _thumbDiameter - 2 * _thumbInset;
                      final thumbOffset = _isReturning ? 0.0 : thumbTravel * progress;
                      final thumbLeft =
                          _thumbInset + (_visualStatus == JobStatus.archived ? thumbOffset : thumbTravel - thumbOffset);

                      return DecoratedBox(
                        decoration: ShapeDecoration(
                          color: theme.colorScheme.skeleton.bone,
                          shape: const MateoRoundedShapeBorder.capsule(),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: _thumbInset,
                              left: _visualStatus == JobStatus.archived ? _thumbInset : null,
                              right: _visualStatus == JobStatus.active ? _thumbInset : null,
                              width: _thumbDiameter + thumbTravel * progress,
                              height: _thumbDiameter,
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  color: _fillColor,
                                  shape: const MateoRoundedShapeBorder.capsule(),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: _visualStatus == JobStatus.archived
                                  ? math.min(thumbLeft + _thumbDiameter + 16, trackWidth - _labelInset)
                                  : _labelInset,
                              right: _visualStatus == JobStatus.active
                                  ? math.min(trackWidth - thumbLeft + _labelInset, trackWidth - _labelInset)
                                  : _labelInset,
                              child: Opacity(
                                opacity: 1 - progress,
                                child: Align(
                                  alignment: .centerLeft,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: .ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: .w600,
                                      color: theme.colorScheme.text.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: _thumbInset,
                              left: thumbLeft,
                              width: _thumbDiameter,
                              height: _thumbDiameter,
                              child: Center(
                                child: _isRequesting
                                    ? MateoLoadingIndicator(
                                        presentation: .circular(
                                          size: 24,
                                          color: theme.colorScheme.buttons.primary.success.foreground,
                                        ),
                                      )
                                    : Transform.rotate(
                                        angle: _arrowRotation,
                                        child: MateoIcon(
                                          .arrowRight,
                                          size: 26,
                                          color: theme.colorScheme.buttons.primary.success.foreground,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
