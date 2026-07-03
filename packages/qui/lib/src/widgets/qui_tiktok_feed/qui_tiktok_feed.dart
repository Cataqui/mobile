library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/lottie/qui_lottie.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

part 'qui_tiktok_feed_cached_card.dart';
part 'qui_tiktok_feed_controller.dart';
part 'qui_tiktok_feed_enums.dart';
part 'qui_tiktok_feed_flow_delegate.dart';
part 'qui_tiktok_feed_loading_indicator.dart';
part 'qui_tiktok_feed_preview.dart';
part 'qui_tiktok_feed_types.dart';
part 'qui_tiktok_feed_window.dart';

/// A vertical, full-screen TikTok-style paged feed.
///
/// Swipe **up** → next item; swipe **down** → previous item.
/// Smooth animated transitions with fling-to-commit.
///
/// The parent MUST supply a bounded height (e.g. `Expanded`, `SizedBox`,
/// full-screen `Scaffold` body) — the widget throws [FlutterError] if the
/// vertical constraints are unbounded.
///
/// ```dart
/// QuiTikTokFeed<String>(
///   items: (
///     count: opportunities.length,
///     provider: (i) => opportunities[i],
///     keyBuilder: null,
///   ),
///   builder: (context, item, index) => MyCard(opportunity: item),
///   onNext: (item, index) => print('Left $item behind'),
/// )
/// ```
class QuiTikTokFeed<T> extends StatefulWidget {
  /// Creates a vertical TikTok-style paged feed.
  QuiTikTokFeed({
    required this.items,
    required this.builder,
    super.key,
    this.controller,
    this.loadMoreErrorBuilder,
    this.endBuilder,
    this.spacing = 0,
    this.onSwipeProgress,
    this.onNext,
    this.onPrevious,
    this.onLoadMore,
    this.onMotionStart,
    this.onMotionEnd,
    this.loadMoreThreshold = 1,
    this.loadingMoreOffset = 200,
    this.enableHapticFeedback = true,
  }) : assert(
         loadMoreThreshold >= 0 && loadMoreThreshold <= 1,
         'loadMoreThreshold must be greater than or equal to 0 and less than or equal to 1.',
       ),
       assert(loadingMoreOffset >= 0, 'loadingMoreOffset must be greater than or equal to 0.'),
       assert(spacing >= 0, 'spacing must be greater than or equal to 0.'),
       assert(items.count >= 0, 'items.count must be greater than or equal to 0.');

  /// Items for the feed as a record of `count`, `provider`, and optional
  /// `keyBuilder`.
  ///
  /// ## Fields
  ///
  /// * `count` — total number of items in the feed.
  /// * `provider` — lazy accessor called only for the current and adjacent
  ///   indexes. Must return a non-null item for every valid index in
  ///   `0..count - 1`.
  /// * `keyBuilder` — optional stable identity for an item. See below.
  ///
  /// ## When to provide `keyBuilder`
  ///
  /// Provide `keyBuilder` when items have a **stable identity** that
  /// survives feed mutations — typically a database ID, UUID, or natural
  /// key. Stable keys let the feed preserve each card's underlying
  /// `Element` and `State` as the user swipes between positions and as
  /// pagination inserts or reorders items.
  ///
  /// Without a stable key, the feed falls back to the item **index**. This
  /// is safe for static lists that never change after initial load, but
  /// breaks down when the list mutates: if pagination prepends new items,
  /// every card's index shifts and the `Element` tree reuses the wrong
  /// `State` for each item — causing stale content, lost scroll position,
  /// or visual glitches.
  ///
  /// ### Example: stable IDs
  ///
  /// ```dart
  /// QuiTikTokFeed<Job>(
  ///   items: (
  ///     count: jobs.length,
  ///     provider: (i) => jobs[i],
  ///     keyBuilder: (job, index) => job.id,
  ///   ),
  ///   builder: (context, job, index) => JobCard(job: job),
  /// )
  /// ```
  ///
  /// ## When to omit `keyBuilder`
  ///
  /// Omit `keyBuilder` when items lack a stable identity or when the feed's
  /// item list is immutable after the initial load. The index-based
  /// fallback is lightweight and correct for fixed-length, append-only, or
  /// non-paginated feeds.
  ///
  /// ## Key uniqueness
  ///
  /// Keys returned by `keyBuilder` must be unique across all items in the
  /// feed. Duplicate keys cause undefined behavior in the internal card
  /// cache and may result in stale or mismatched cards being displayed.
  final QuiTikTokFeedItems<T> items;

  /// Builds the widget for each feed item.
  final QuiTikTokFeedItemBuilder<T> builder;

  /// Controls this feed from parent code.
  final QuiTikTokFeedController? controller;

  /// Builds the load-more error card shown at the end of the deck.
  ///
  /// When this builder is non-null, the feed treats pagination as errored and
  /// shows the returned card instead of automatically requesting more items.
  final QuiTikTokFeedLoadMoreErrorBuilder? loadMoreErrorBuilder;

  /// Builds content when pagination ends after all loaded cards are dismissed.
  final WidgetBuilder? endBuilder;

  /// Called whenever the swipe position changes.
  final QuiTikTokFeedProgressCallback? onSwipeProgress;

  /// Called when the feed advances to the next item.
  final QuiTikTokFeedItemCallback<T>? onNext;

  /// Called when the feed goes back to the previous item.
  final QuiTikTokFeedItemCallback<T>? onPrevious;

  /// Called when the current index reaches [loadMoreThreshold].
  final QuiTikTokFeedLoadMoreCallback? onLoadMore;

  /// Called once when a drag or programmatic settle motion begins.
  final VoidCallback? onMotionStart;

  /// Called once after a drag or programmatic settle motion completes.
  final VoidCallback? onMotionEnd;

  /// Loaded-deck progress required to call [onLoadMore].
  final double loadMoreThreshold;

  /// How many pixels the current card lifts up while loading more items.
  ///
  /// When the user is on the last card and [onLoadMore] is in flight, swiping
  /// up reveals the loading indicator below the card. This property controls
  /// how far the card translates upward to make room for the indicator.
  ///
  /// * A value of `0` disables the lift entirely (the card stays in place).
  /// * Larger values push the card higher, creating more visible space for
  ///   the loading animation.
  ///
  /// The dragging feel is always 1:1 with the finger, clamped to this value.
  ///
  /// Defaults to `200` (pixels).
  final double loadingMoreOffset;

  /// Whether the feed emits a soft haptic tick when the next item settles.
  ///
  /// Defaults to `true`. Set to `false` to disable the settle haptic.
  final bool enableHapticFeedback;

  /// Vertical gap between the current card and its adjacent cards.
  ///
  /// The current card always settles at the same position regardless of this
  /// value. Changing [spacing] only adjusts the visible gap to the next and
  /// previous cards during a swipe — the settled card position is preserved.
  ///
  /// Defaults to `0` (cards sit edge-to-edge).
  ///
  /// ```dart
  /// QuiTikTokFeed<String>(
  ///   items: (count: jobs.length, provider: (i) => jobs[i], keyBuilder: null),
  ///   spacing: 12,
  ///   builder: (context, job, index) => JobCard(job: job),
  /// )
  /// ```
  final double spacing;

  @override
  State<QuiTikTokFeed<T>> createState() => _QuiTikTokFeedState<T>();
}

class _QuiTikTokFeedState<T> extends State<QuiTikTokFeed<T>>
    with SingleTickerProviderStateMixin
    implements _QuiTikTokFeedControllerClient {
  static const _settleDuration = Duration(milliseconds: 260);
  static const _commitDuration = Duration(milliseconds: 220);
  static const _swipeThreshold = 0.25;
  static const _flingVelocityThreshold = 700.0;

  late final AnimationController _animationController;

  Animation<double>? _offsetAnimation;
  double _dragOffsetY = 0;
  QuiTikTokFeedAction _lastAction = QuiTikTokFeedAction.next;
  int _currentIndex = 0;
  int? _exhaustedItemCount;
  double _viewportHeight = 1;
  double _viewportWidth = 1;
  double get _commitDistance => _viewportHeight + widget.spacing;
  bool _isLoadingMore = false;
  bool _hasFiredStartHaptic = false;
  bool _isLoadMoreScheduled = false;
  bool _isControllerActionRunning = false;
  bool _isMotionActive = false;
  int _motionGeneration = 0;
  int _activeDragGeneration = 0;
  _QuiTikTokFeedAwaitPhase _awaitPhase = _QuiTikTokFeedAwaitPhase.inactive;
  double _awaitDragProgress = 0;
  bool _isCommitting = false;
  Animation<double>? _loadingLiftAnimation;
  final _disposeCompleter = Completer<void>();
  final Map<Object, _QuiTikTokFeedCachedCard<T>> _cardCache = <Object, _QuiTikTokFeedCachedCard<T>>{};

  final ValueNotifier<double> _dragOffsetNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> _loadingLiftNotifier = ValueNotifier<double>(0);

  bool get _hasCurrentItem => _currentIndex < widget.items.count;
  bool get _shouldShowLoadMoreErrorCard => widget.loadMoreErrorBuilder != null;

  bool get _canEnterAwaitMode => _hasCurrentItem && _currentIndex + 1 >= widget.items.count && _isLoadingMore;

  bool get _isAwaitDeciding => _awaitPhase == _QuiTikTokFeedAwaitPhase.deciding;

  bool get _isAwaitDragging => _awaitPhase == _QuiTikTokFeedAwaitPhase.dragging;

  bool get _isAwaitWaiting => _awaitPhase == _QuiTikTokFeedAwaitPhase.waiting;

  bool get _isAwaitActive => _isAwaitDragging || _isAwaitWaiting;

  bool get _paginationMayBringMore =>
      widget.onLoadMore != null && !_shouldShowLoadMoreErrorCard && _exhaustedItemCount != widget.items.count;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: _settleDuration)
      ..addListener(_syncAnimatedOffset);

    widget.controller?._attach(this);

    _scheduleLoadMoreIfNeeded();
  }

  @override
  void didUpdateWidget(covariant QuiTikTokFeed<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    if (_currentIndex > widget.items.count) {
      _currentIndex = widget.items.count;
      _dragOffsetY = 0;
      _dragOffsetNotifier.value = 0;
    }

    if (widget.items.count > oldWidget.items.count || widget.items.count > (_exhaustedItemCount ?? -1)) {
      _exhaustedItemCount = null;
    }

    if (widget.items.count != oldWidget.items.count) {
      _scheduleLoadMoreIfNeeded();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);

    _animationController
      ..removeListener(_syncAnimatedOffset)
      ..dispose();

    _dragOffsetNotifier.dispose();
    _loadingLiftNotifier.dispose();
    _cardCache.clear();
    _disposeCompleter.complete();

    super.dispose();
  }

  void _syncAnimatedOffset() {
    final offsetAnimation = _offsetAnimation;
    final loadingLiftAnimation = _loadingLiftAnimation;
    if (offsetAnimation != null) {
      _setDragOffset(offsetAnimation.value);
    }

    if (loadingLiftAnimation != null) {
      _loadingLiftNotifier.value = loadingLiftAnimation.value;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isControllerActionRunning) return;

    _animationController.stop(canceled: false);
    _hasFiredStartHaptic = false;
    _activeDragGeneration = _startMotion();

    _handleAwaitDragStart();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isControllerActionRunning) return;

    if (_isAwaitDeciding) {
      _handleAwaitDecisionUpdate(details.delta.dy);
      return;
    }

    if (_isAwaitActive) {
      _handleAwaitDragUpdate(details.delta.dy);
      return;
    }

    _handleRegularDragUpdate(details.delta.dy);
  }

  Future<void> _onVerticalDragEnd(DragEndDetails details) async {
    if (_isControllerActionRunning) return;

    final motionGeneration = _activeDragGeneration;

    try {
      if (_isAwaitDeciding) {
        _resetAwaitPhase();
        return;
      }

      if (_isAwaitActive) {
        await _finishAwaitDrag(details);
        return;
      }

      await _finishRegularDrag(details);
    } finally {
      _endMotion(motionGeneration);
    }
  }

  void _onVerticalDragCancel() {
    if (_isControllerActionRunning) return;

    final motionGeneration = _activeDragGeneration;

    if (_isAwaitDeciding) {
      _resetAwaitPhase();
      _endMotion(motionGeneration);
      return;
    }

    if (_isAwaitActive) {
      _completeCanceledMotion(_exitAwaitDrag(), motionGeneration: motionGeneration);
      return;
    }

    if (_isCommitting) {
      _completeCanceledMotion(_dragOffsetY < 0 ? _commitNext() : _commitPrevious(), motionGeneration: motionGeneration);
      return;
    }

    _completeCanceledMotion(_snapBack(), motionGeneration: motionGeneration);
  }

  void _completeCanceledMotion(Future<void> motion, {required int motionGeneration}) {
    unawaited(
      motion.whenComplete(() {
        if (!mounted) return;
        _endMotion(motionGeneration);
      }),
    );
  }

  void _handleAwaitDragStart() {
    if (!_canEnterAwaitMode) return;

    if (_isAwaitWaiting) {
      setState(() {
        _awaitDragProgress = 1.0;
        _loadingLiftNotifier.value = -widget.loadingMoreOffset;
      });
      return;
    }

    _awaitPhase = _QuiTikTokFeedAwaitPhase.deciding;
  }

  void _handleAwaitDecisionUpdate(double dragDeltaY) {
    if (dragDeltaY == 0) return;

    _awaitPhase = _QuiTikTokFeedAwaitPhase.inactive;

    if (dragDeltaY < 0 && _canEnterAwaitMode) {
      setState(() {
        _awaitPhase = _QuiTikTokFeedAwaitPhase.dragging;
        _loadingLiftNotifier.value = dragDeltaY.clamp(-widget.loadingMoreOffset, 0.0);
        _awaitDragProgress = _progressForLoadingLift(_loadingLiftNotifier.value);
      });
      return;
    }

    _setDragOffset(_dragOffsetY + dragDeltaY);
  }

  void _handleAwaitDragUpdate(double dragDeltaY) {
    _loadingLiftNotifier.value = (_loadingLiftNotifier.value + dragDeltaY).clamp(-widget.loadingMoreOffset, 0.0);
    _awaitDragProgress = _progressForLoadingLift(_loadingLiftNotifier.value);

    _emitStartHapticIfNeeded(shouldEmit: _awaitDragProgress > 0);
    widget.onSwipeProgress?.call(action: QuiTikTokFeedAction.next, percentage: _awaitDragProgress);
  }

  void _handleRegularDragUpdate(double dragDeltaY) {
    _setDragOffset(_dragOffsetY + dragDeltaY);

    _emitStartHapticIfNeeded(shouldEmit: _dragOffsetY < 0);
  }

  void _emitStartHapticIfNeeded({required bool shouldEmit}) {
    if (_hasFiredStartHaptic || !widget.enableHapticFeedback || !shouldEmit) return;

    _hasFiredStartHaptic = true;
    unawaited(HapticFeedback.selectionClick());
  }

  Future<void> _finishAwaitDrag(DragEndDetails details) async {
    final velocity = details.velocity.pixelsPerSecond.dy;

    if (_isAwaitWaiting) {
      await _finishWaitingAwaitDrag(velocity: velocity);
      return;
    }

    if (_shouldCommitAwait(velocity: velocity)) {
      await _commitAwaitDrag();
      return;
    }

    await _exitAwaitDrag();
  }

  Future<void> _finishWaitingAwaitDrag({required double velocity}) async {
    if (_shouldExitWaiting(velocity: velocity)) {
      await _exitAwaitDrag();
      return;
    }

    await _settleBackToAwait();
  }

  Future<void> _finishRegularDrag(DragEndDetails details) async {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final shouldCommit = _shouldCommitSwipe(velocity: velocity);

    if (!shouldCommit) {
      await _snapBack();
      return;
    }

    final isNextSwipe = _isNextSwipe(velocity: velocity);

    if (isNextSwipe && _hasCurrentItem) {
      await _commitNext();
      return;
    }

    if (!isNextSwipe && _currentIndex > 0) {
      await _commitPrevious();
      return;
    }

    await _snapBack();
  }

  bool _shouldCommitSwipe({required double velocity}) {
    final progress = (_dragOffsetY.abs() / _viewportHeight).clamp(0, 1);

    return progress >= _swipeThreshold || velocity.abs() >= _flingVelocityThreshold;
  }

  bool _isNextSwipe({required double velocity}) {
    return _dragOffsetY < 0 || (_dragOffsetY == 0 && velocity < 0);
  }

  bool _shouldCommitAwait({required double velocity}) {
    final metThreshold = _awaitDragProgress >= _swipeThreshold || velocity.abs() >= _flingVelocityThreshold;

    return metThreshold && (_awaitDragProgress > 0 || velocity < 0);
  }

  bool _shouldExitWaiting({required double velocity}) {
    return velocity > 0 || _awaitDragProgress < 0.95;
  }

  Future<void> _commitAwaitDrag() async {
    setState(() => _awaitPhase = _QuiTikTokFeedAwaitPhase.waiting);
    await _animateLoadingLift(to: -widget.loadingMoreOffset, duration: _settleDuration);

    if (!mounted) return;

    setState(() => _loadingLiftNotifier.value = -widget.loadingMoreOffset);
  }

  Future<void> _exitAwaitDrag() async {
    await _animateLoadingLift(to: 0, duration: _settleDuration);

    if (!mounted) return;

    setState(_resetAwaitPhase);
  }

  Future<void> _settleBackToAwait() async {
    await _animateLoadingLift(to: -widget.loadingMoreOffset, duration: _settleDuration);

    if (!mounted) return;

    setState(() {
      _awaitPhase = _QuiTikTokFeedAwaitPhase.waiting;
      _loadingLiftNotifier.value = -widget.loadingMoreOffset;
    });
  }

  Future<void> _commitNext() async {
    if (!_hasCurrentItem) return;

    _isCommitting = true;
    try {
      if (_currentIndex + 1 >= widget.items.count && _paginationMayBringMore) {
        await _enterAwaitModeFromCommit();
        return;
      }

      final item = widget.items.provider(_currentIndex);
      final itemIndex = _currentIndex;

      await _animateTo(-_commitDistance, duration: _commitDuration, curve: Curves.easeOutCubic);

      if (!mounted) return;

      setState(() {
        _currentIndex += 1;
        _dragOffsetY = 0;
      });

      _dragOffsetNotifier.value = 0;

      widget.onNext?.call(item, itemIndex);
      _scheduleLoadMoreIfNeeded();

      if (widget.enableHapticFeedback) {
        unawaited(HapticFeedback.selectionClick());
      }
    } finally {
      _isCommitting = false;
    }
  }

  Future<void> _enterAwaitModeFromCommit() async {
    setState(() {
      _awaitPhase = _QuiTikTokFeedAwaitPhase.waiting;
      _awaitDragProgress = 1.0;
    });

    await _animateIntoAwait();

    if (!mounted) return;

    setState(() {
      _dragOffsetY = 0;
      _loadingLiftNotifier.value = -widget.loadingMoreOffset;
    });

    _dragOffsetNotifier.value = 0;

    _scheduleLoadMoreIfNeeded();
  }

  Future<void> _animateIntoAwait() async {
    await _animateFeedPosition(
      offsetTarget: 0,
      loadingLiftTarget: -widget.loadingMoreOffset,
      duration: _settleDuration,
    );
  }

  Future<void> _commitPrevious() async {
    final itemIndex = _currentIndex;
    final hadRealItem = _hasCurrentItem;

    _isCommitting = true;
    try {
      await _animateTo(_commitDistance, duration: _commitDuration, curve: Curves.easeOutCubic);
    } finally {
      _isCommitting = false;
    }

    if (!mounted) return;

    setState(() {
      _currentIndex -= 1;
      _dragOffsetY = 0;
    });

    _dragOffsetNotifier.value = 0;

    if (hadRealItem) widget.onPrevious?.call(widget.items.provider(itemIndex), itemIndex);
  }

  Future<void> _snapBack() async {
    await _animateTo(0, duration: _settleDuration);
  }

  Future<void> _animateTo(double target, {required Duration duration, Curve curve = Curves.easeOutCubic}) {
    return _animateFeedPosition(offsetTarget: target, duration: duration, curve: curve);
  }

  Future<void> _animateLoadingLift({
    required double to,
    required Duration duration,
    Curve curve = Curves.easeOutCubic,
  }) {
    return _animateFeedPosition(loadingLiftTarget: to, duration: duration, curve: curve);
  }

  Future<void> _animateCommitFromAwait() async {
    await _animateFeedPosition(offsetTarget: -_commitDistance, loadingLiftTarget: 0, duration: _commitDuration);
  }

  Future<void> _animateFeedPosition({
    required Duration duration,
    double? offsetTarget,
    double? loadingLiftTarget,
    Curve curve = Curves.easeOutCubic,
  }) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      _applyAnimationTargets(offsetTarget: offsetTarget, loadingLiftTarget: loadingLiftTarget);
      return Future<void>.value();
    }

    final shouldAnimateOffset = offsetTarget != null && _dragOffsetY != offsetTarget;
    final shouldAnimateLoadingLift = loadingLiftTarget != null && _loadingLiftNotifier.value != loadingLiftTarget;

    if (!shouldAnimateOffset && !shouldAnimateLoadingLift) {
      _applyAnimationTargets(offsetTarget: offsetTarget, loadingLiftTarget: loadingLiftTarget);
      return Future<void>.value();
    }

    _offsetAnimation = _offsetAnimationForTarget(
      shouldAnimate: shouldAnimateOffset,
      target: offsetTarget,
      curve: curve,
    );
    _loadingLiftAnimation = _loadingLiftAnimationForTarget(
      shouldAnimate: shouldAnimateLoadingLift,
      target: loadingLiftTarget,
      curve: curve,
    );

    _animationController
      ..duration = duration
      ..reset();

    return Future.any([_animationController.forward(), _disposeCompleter.future]);
  }

  Animation<double> _doubleAnimation({required double from, required double to, required Curve curve}) {
    return Tween<double>(begin: from, end: to).chain(CurveTween(curve: curve)).animate(_animationController);
  }

  Animation<double>? _offsetAnimationForTarget({
    required bool shouldAnimate,
    required double? target,
    required Curve curve,
  }) {
    if (!shouldAnimate || target == null) return null;

    return _doubleAnimation(from: _dragOffsetY, to: target, curve: curve);
  }

  Animation<double>? _loadingLiftAnimationForTarget({
    required bool shouldAnimate,
    required double? target,
    required Curve curve,
  }) {
    if (!shouldAnimate || target == null) return null;

    return _doubleAnimation(from: _loadingLiftNotifier.value, to: target, curve: curve);
  }

  void _applyAnimationTargets({required double? offsetTarget, required double? loadingLiftTarget}) {
    if (offsetTarget != null) _setDragOffset(offsetTarget);
    if (loadingLiftTarget != null) _loadingLiftNotifier.value = loadingLiftTarget;
  }

  void _resetAwaitPhase() {
    _awaitPhase = _QuiTikTokFeedAwaitPhase.inactive;
    _awaitDragProgress = 0;
    _loadingLiftNotifier.value = 0;
  }

  double _progressForLoadingLift(double loadingLiftOffset) {
    if (widget.loadingMoreOffset == 0) return 0;

    return (-loadingLiftOffset / widget.loadingMoreOffset).clamp(0.0, 1.0);
  }

  void _setDragOffset(double value) {
    final action = value == 0
        ? _lastAction
        : value < 0
        ? QuiTikTokFeedAction.next
        : QuiTikTokFeedAction.previous;

    _lastAction = action;
    _dragOffsetY = value;
    _dragOffsetNotifier.value = value;

    widget.onSwipeProgress?.call(action: action, percentage: (value.abs() / _viewportHeight).clamp(0, 1));
  }

  int _startMotion() {
    _motionGeneration += 1;
    if (_isMotionActive) return _motionGeneration;

    _isMotionActive = true;
    widget.onMotionStart?.call();
    return _motionGeneration;
  }

  void _endMotion(int generation) {
    if (!_isMotionActive || generation != _motionGeneration) return;

    _isMotionActive = false;
    widget.onMotionEnd?.call();
  }

  void _retryLoadMore() {
    _exhaustedItemCount = null;
    _startLoadMore();
  }

  void _scheduleLoadMoreIfNeeded() {
    if (!_shouldLoadMore || _isLoadMoreScheduled) return;

    _isLoadMoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoadMoreScheduled = false;
      if (!mounted || !_shouldLoadMore) return;

      _startLoadMore();
    });
  }

  bool get _shouldLoadMore {
    final onLoadMore = widget.onLoadMore;

    if (onLoadMore == null ||
        widget.items.count == 0 ||
        _shouldShowLoadMoreErrorCard ||
        _isLoadingMore ||
        _exhaustedItemCount == widget.items.count) {
      return false;
    }

    final loadedProgress = (_currentIndex + 1) / widget.items.count;
    return loadedProgress >= widget.loadMoreThreshold;
  }

  Future<void> _startLoadMore() async {
    final onLoadMore = widget.onLoadMore;
    if (onLoadMore == null || _isLoadingMore) return;

    final itemCountBeforeLoad = widget.items.count;

    setState(() => _isLoadingMore = true);

    try {
      await onLoadMore();
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _exhaustedItemCount = itemCountBeforeLoad;
          _resetAwaitPhase();
        });
      }

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'qui',
          context: ErrorDescription('while loading more QuiTikTokFeed items'),
        ),
      );
      return;
    }

    if (!mounted) return;

    final hadItemsGrowth = widget.items.count > itemCountBeforeLoad;

    setState(() {
      _isLoadingMore = false;
      if (!hadItemsGrowth) {
        _exhaustedItemCount = itemCountBeforeLoad;
      }
    });

    if (_isAwaitWaiting && mounted) {
      unawaited(_navigateFromAwait());
    }
  }

  Future<void> _navigateFromAwait() async {
    if (!mounted) return;

    _isControllerActionRunning = true;
    final motionGeneration = _startMotion();
    final item = widget.items.provider(_currentIndex);
    final itemIndex = _currentIndex;

    try {
      setState(() {
        _awaitPhase = _QuiTikTokFeedAwaitPhase.inactive;
        _awaitDragProgress = 0;
      });

      await _animateCommitFromAwait();

      if (!mounted) return;

      setState(() {
        _currentIndex += 1;
        _dragOffsetY = 0;
      });

      _dragOffsetNotifier.value = 0;
      _loadingLiftNotifier.value = 0;

      widget.onNext?.call(item, itemIndex);
      _scheduleLoadMoreIfNeeded();

      if (widget.enableHapticFeedback) {
        unawaited(HapticFeedback.selectionClick());
      }
    } finally {
      if (mounted) {
        _endMotion(motionGeneration);
        _isControllerActionRunning = false;
      }
    }
  }

  void _enterAwaitModeFromController() {
    setState(() {
      _awaitPhase = _QuiTikTokFeedAwaitPhase.waiting;
      _awaitDragProgress = 1.0;
      _loadingLiftNotifier.value = -widget.loadingMoreOffset;
    });
  }

  @override
  Future<bool> nextFromController() async {
    if (_isControllerActionRunning || !_hasCurrentItem) return false;

    _animationController.stop(canceled: false);
    _isControllerActionRunning = true;
    final motionGeneration = _startMotion();

    try {
      if (_canEnterAwaitMode) {
        _enterAwaitModeFromController();
        return mounted;
      }

      await _commitNext();
    } finally {
      _endMotion(motionGeneration);
      if (mounted) {
        _isControllerActionRunning = false;
      }
    }

    return mounted;
  }

  @override
  Future<bool> previousFromController() async {
    if (_isControllerActionRunning || _currentIndex == 0) return false;

    _animationController.stop(canceled: false);
    _isControllerActionRunning = true;
    final motionGeneration = _startMotion();

    try {
      await _commitPrevious();
    } finally {
      _endMotion(motionGeneration);
      if (mounted) {
        _isControllerActionRunning = false;
      }
    }

    return mounted;
  }

  _QuiTikTokFeedCachedCard<T> _cardFor({required int index}) {
    final item = widget.items.provider(index);
    final itemKey = widget.items.keyBuilder?.call(item, index) ?? index;
    final cachedCard = _cardCache[itemKey];

    if (cachedCard != null && cachedCard.item == item && cachedCard.index == index) {
      return cachedCard;
    }

    final card = _QuiTikTokFeedCachedCard<T>(
      item: item,
      itemKey: itemKey,
      index: index,
      child: KeyedSubtree(key: ValueKey<Object>(itemKey), child: widget.builder(context, item, index)),
    );

    _cardCache[itemKey] = card;
    return card;
  }

  void _retainCardWindow({
    required _QuiTikTokFeedCachedCard<T>? previousCard,
    required _QuiTikTokFeedCachedCard<T>? currentCard,
    required _QuiTikTokFeedCachedCard<T>? nextCard,
  }) {
    final retainedKeys = <Object>{
      if (previousCard != null) previousCard.itemKey,
      if (currentCard != null) currentCard.itemKey,
      if (nextCard != null) nextCard.itemKey,
    };

    _cardCache.removeWhere((key, value) => !retainedKeys.contains(key));
  }

  void _ensureBoundedHeight(BoxConstraints constraints) {
    if (constraints.hasBoundedHeight) return;

    throw FlutterError(
      'Vertical viewport was given unbounded height.\n'
      'QuiTikTokFeed requires its parent widget to have a bounded '
      'height.\n'
      'When the parent widget does not have a bounded height, the feed '
      'cannot determine how large to make its pages. Consider wrapping '
      'the QuiTikTokFeed with an Expanded, a SizedBox, or ensuring the '
      'parent provides bounded constraints.',
    );
  }

  void _syncViewportSize(BoxConstraints constraints) {
    _viewportHeight = constraints.maxHeight;
    _viewportWidth = constraints.maxWidth;
  }

  _QuiTikTokFeedWindow<T> _feedWindowFor(BuildContext context) {
    final nextIndex = _currentIndex + 1;
    final hasNextItem = nextIndex < widget.items.count;
    final previousCard = _currentIndex > 0 ? _cardFor(index: _currentIndex - 1) : null;
    final currentCard = _hasCurrentItem ? _cardFor(index: _currentIndex) : null;
    final nextCard = hasNextItem ? _cardFor(index: nextIndex) : null;

    _retainCardWindow(previousCard: previousCard, currentCard: currentCard, nextCard: nextCard);

    return _QuiTikTokFeedWindow<T>(
      previousCard: previousCard,
      currentCard: currentCard,
      nextCard: nextCard,
      paginationCard: _hasCurrentItem ? _buildPaginationCard(context) : null,
      terminalCard: _hasCurrentItem ? null : _buildTerminalCard(context),
    );
  }

  bool _hasGestureTarget(_QuiTikTokFeedWindow<T> feedWindow) {
    return feedWindow.currentCard != null || feedWindow.previousCard != null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureBoundedHeight(constraints);
        _syncViewportSize(constraints);

        return _buildGestureLayer(_feedWindowFor(context));
      },
    );
  }

  Widget _buildGestureLayer(_QuiTikTokFeedWindow<T> feedWindow) {
    final isGestureActive = _hasGestureTarget(feedWindow);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: isGestureActive ? _onVerticalDragStart : null,
      onVerticalDragUpdate: isGestureActive ? _onVerticalDragUpdate : null,
      onVerticalDragEnd: isGestureActive ? _onVerticalDragEnd : null,
      onVerticalDragCancel: isGestureActive ? _onVerticalDragCancel : null,
      child: _buildFlow(feedWindow),
    );
  }

  Widget _buildFlow(_QuiTikTokFeedWindow<T> feedWindow) {
    return Flow(
      clipBehavior: Clip.none,
      delegate: _QuiTikTokFeedFlowDelegate(
        offsetListenable: _dragOffsetNotifier,
        loadingLiftListenable: _loadingLiftNotifier,
        viewportHeight: _viewportHeight,
        viewportWidth: _viewportWidth,
        spacing: widget.spacing,
        hasPreviousCard: feedWindow.previousCard != null,
        hasNextCard: feedWindow.nextCard != null || feedWindow.paginationCard != null,
        isAwaitMode: _isAwaitActive,
        loadingMoreOffset: widget.loadingMoreOffset,
      ),
      children: [
        _buildCurrentFlowChild(feedWindow),
        _buildNextFlowChild(feedWindow),
        _buildPreviousFlowChild(feedWindow),
        _QuiTikTokFeedLoadingIndicator(visible: _isAwaitActive),
      ],
    );
  }

  Widget _buildCurrentFlowChild(_QuiTikTokFeedWindow<T> feedWindow) {
    final currentCard = feedWindow.currentCard;
    if (currentCard != null) return _retainedCard(card: currentCard);

    final terminalCard = feedWindow.terminalCard;
    if (terminalCard != null) return _retainedTerminalCard(child: terminalCard);

    return const SizedBox.shrink(key: ValueKey('qui_tiktok_feed_empty_current'));
  }

  Widget _buildNextFlowChild(_QuiTikTokFeedWindow<T> feedWindow) {
    final nextCard = feedWindow.nextCard;
    if (nextCard != null) return _retainedCard(card: nextCard);

    final paginationCard = feedWindow.paginationCard;
    if (paginationCard != null) return _retainedTerminalCard(child: paginationCard);

    return const SizedBox.shrink(key: ValueKey('qui_tiktok_feed_empty_next'));
  }

  Widget _buildPreviousFlowChild(_QuiTikTokFeedWindow<T> feedWindow) {
    final previousCard = feedWindow.previousCard;
    if (previousCard != null) return _retainedCard(card: previousCard);

    return const SizedBox.shrink(key: ValueKey('qui_tiktok_feed_empty_previous'));
  }

  Widget _retainedCard({required _QuiTikTokFeedCachedCard<T> card}) {
    return RepaintBoundary(key: ValueKey('qui_tiktok_feed_card_${card.itemKey}'), child: card.child);
  }

  Widget _retainedTerminalCard({required Widget child}) {
    return KeyedSubtree(key: const ValueKey('qui_tiktok_feed_terminal_card'), child: child);
  }

  Widget _buildTerminalCard(BuildContext context) {
    if (_shouldShowLoadMoreErrorCard) return _loadMoreErrorBuilderCard(context);

    return widget.endBuilder?.call(context) ?? const SizedBox.shrink();
  }

  Widget? _buildPaginationCard(BuildContext context) {
    if (_isLoadingMore) return null;

    if (_shouldShowLoadMoreErrorCard) return _loadMoreErrorBuilderCard(context);

    final hasNextItem = _currentIndex + 1 < widget.items.count;
    if (!hasNextItem && _exhaustedItemCount == widget.items.count) {
      return widget.endBuilder?.call(context);
    }

    return null;
  }

  Widget _loadMoreErrorBuilderCard(BuildContext context) {
    final loadMoreErrorBuilder = widget.loadMoreErrorBuilder;
    if (loadMoreErrorBuilder == null) return const SizedBox.shrink();

    return loadMoreErrorBuilder(context, _retryLoadMore);
  }
}

@Preview(name: 'QuiTikTokFeed', group: 'Decks')
Widget quiTikTokFeedPreview() {
  const previewOpportunities = [
    _PreviewOpportunity(
      title: 'Garcom para hoje',
      place: 'Pinheiros',
      pay: r'R$ 180',
      time: '18h - 23h',
      color: Color(0xFFFF4A4B),
    ),
    _PreviewOpportunity(
      title: 'Ajuda em evento',
      place: 'Vila Madalena',
      pay: r'R$ 240',
      time: 'Sabado',
      color: Color(0xFF00A896),
    ),
    _PreviewOpportunity(
      title: 'Entrega rapida',
      place: 'Bela Vista',
      pay: r'R$ 65',
      time: 'Agora',
      color: Color(0xFF3D5A80),
    ),
  ];

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: const Color(0xFFF6F4F1),
      body: SafeArea(
        child: QuiTikTokFeed<_PreviewOpportunity>(
          items: (count: previewOpportunities.length, provider: (int i) => previewOpportunities[i], keyBuilder: null),
          builder: (context, opportunity, index) {
            return _PreviewOpportunityCard(opportunity: opportunity);
          },
          endBuilder: (context) {
            return const Center(child: Text('Sem oportunidades por aqui'));
          },
        ),
      ),
    ),
  );
}
