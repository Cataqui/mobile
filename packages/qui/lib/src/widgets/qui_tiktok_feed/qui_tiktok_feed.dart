library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';

part 'qui_tiktok_feed_action.dart';
part 'qui_tiktok_feed_controller.dart';
part 'qui_tiktok_feed_drag_state.dart';
part 'qui_tiktok_feed_types.dart';

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
///   items: (count: opportunities.length, provider: (i) => opportunities[i]),
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
    this.loadingMoreBuilder,
    this.loadMoreErrorBuilder,
    this.endBuilder,
    this.onSwipeProgress,
    this.onNext,
    this.onPrevious,
    this.onLoadMore,
    this.loadMoreThreshold = 1,
    this.enableHapticFeedback = true,
  }) : assert(
         loadMoreThreshold >= 0 && loadMoreThreshold <= 1,
         'loadMoreThreshold must be greater than or equal to 0 and less than or equal to 1.',
       ),
       assert(items.count >= 0, 'items.count must be greater than or equal to 0.');

  /// Items for the feed as a record of count and lazy provider.
  ///
  /// The provider is only called for the current and adjacent indexes.
  final ({int count, T Function(int index) provider}) items;

  /// Builds the widget for each feed item.
  final Widget Function(BuildContext context, T item, int index) builder;

  /// Controls this feed from parent code.
  final QuiTikTokFeedController? controller;

  /// Builds the loading card shown while more items are loading.
  final WidgetBuilder? loadingMoreBuilder;

  /// Builds the load-more error card shown at the end of the deck.
  ///
  /// When null, loading more is treated as error-free.
  /// If provided, it treats as having a load-more error immediately.
  final Widget Function(BuildContext context, VoidCallback retry)? loadMoreErrorBuilder;

  /// Builds content when pagination ends after all loaded cards are dismissed.
  final WidgetBuilder? endBuilder;

  /// Called whenever the swipe position changes.
  final void Function({required QuiTikTokFeedAction action, required double percentage})? onSwipeProgress;

  /// Called when the feed advances to the next item.
  final QuiTikTokFeedItemCallback<T>? onNext;

  /// Called when the feed goes back to the previous item.
  final QuiTikTokFeedItemCallback<T>? onPrevious;

  /// Called when the current index reaches [loadMoreThreshold].
  final Future<void> Function()? onLoadMore;

  /// Loaded-deck progress required to call [onLoadMore].
  final double loadMoreThreshold;

  /// Whether the feed emits a soft haptic tick when the next item settles.
  ///
  /// Defaults to `true`. Set to `false` to disable the settle haptic.
  final bool enableHapticFeedback;

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
  bool _isLoadingMore = false;
  bool _hasFiredStartHaptic = false;
  bool _isLoadMoreScheduled = false;
  bool _isControllerActionRunning = false;
  final _disposeCompleter = Completer<void>();

  final ValueNotifier<_QuiTikTokFeedDragState> _dragStateNotifier = ValueNotifier<_QuiTikTokFeedDragState>(
    const _QuiTikTokFeedDragState(offsetY: 0, action: QuiTikTokFeedAction.next, currentIndex: 0),
  );

  bool get _hasCurrentItem => _currentIndex < widget.items.count;
  bool get _hasLoadMoreError => widget.loadMoreErrorBuilder != null;

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
      _dragStateNotifier.value = _QuiTikTokFeedDragState(offsetY: 0, action: _lastAction, currentIndex: _currentIndex);
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

    _dragStateNotifier.dispose();
    _disposeCompleter.complete();

    super.dispose();
  }

  void _syncAnimatedOffset() {
    final offsetAnimation = _offsetAnimation;
    if (offsetAnimation == null) return;

    _setDragOffset(offsetAnimation.value);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isControllerActionRunning) return;

    _animationController.stop();
    _hasFiredStartHaptic = false;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isControllerActionRunning) return;

    _setDragOffset(_dragOffsetY + details.delta.dy);

    if (!_hasFiredStartHaptic &&
        widget.enableHapticFeedback &&
        _dragOffsetY < 0) {
      _hasFiredStartHaptic = true;
      unawaited(HapticFeedback.selectionClick());
    }
  }

  Future<void> _onVerticalDragEnd(DragEndDetails details) async {
    if (_isControllerActionRunning) return;

    final velocity = details.velocity.pixelsPerSecond.dy;
    final progress = (_dragOffsetY.abs() / _viewportHeight).clamp(0, 1);
    final upIntent = _dragOffsetY < 0 || (_dragOffsetY == 0 && velocity < 0);
    final metThreshold = progress >= _swipeThreshold || velocity.abs() >= _flingVelocityThreshold;

    if (!metThreshold) {
      await _snapBack();
      return;
    }

    if (upIntent && _hasCurrentItem) {
      await _commitNext();
      return;
    }

    if (!upIntent && _currentIndex > 0) {
      await _commitPrevious();
      return;
    }

    await _snapBack();
  }

  Future<void> _commitNext() async {
    if (!_hasCurrentItem) return;

    final item = widget.items.provider(_currentIndex);
    final itemIndex = _currentIndex;

    await _animateTo(-_viewportHeight, duration: _commitDuration, curve: Curves.easeIn);

    if (!mounted) return;

    setState(() {
      _currentIndex += 1;
      _dragOffsetY = 0;
    });

    _dragStateNotifier.value = _QuiTikTokFeedDragState(offsetY: 0, action: _lastAction, currentIndex: _currentIndex);

    widget.onNext?.call(item, itemIndex);
    _scheduleLoadMoreIfNeeded();

    if (widget.enableHapticFeedback) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  Future<void> _commitPrevious() async {
    final itemIndex = _currentIndex;
    final hadRealItem = _hasCurrentItem;

    await _animateTo(_viewportHeight, duration: _commitDuration, curve: Curves.easeIn);

    if (!mounted) return;

    setState(() {
      _currentIndex -= 1;
      _dragOffsetY = 0;
    });

    _dragStateNotifier.value = _QuiTikTokFeedDragState(offsetY: 0, action: _lastAction, currentIndex: _currentIndex);

    if (hadRealItem) widget.onPrevious?.call(widget.items.provider(itemIndex), itemIndex);
  }

  Future<void> _snapBack() async {
    await _animateTo(0, duration: _settleDuration);
  }

  Future<void> _animateTo(double target, {required Duration duration, Curve curve = Curves.easeOutCubic}) {
    final begin = _dragOffsetY;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations || begin == target) {
      _setDragOffset(target);
      return Future<void>.value();
    }

    _offsetAnimation = Tween<double>(
      begin: begin,
      end: target,
    ).chain(CurveTween(curve: curve)).animate(_animationController);

    _animationController
      ..duration = duration
      ..reset();

    return Future.any([_animationController.forward(), _disposeCompleter.future]);
  }

  void _setDragOffset(double value) {
    final action = value == 0
        ? _lastAction
        : value < 0
        ? QuiTikTokFeedAction.next
        : QuiTikTokFeedAction.previous;

    _lastAction = action;
    _dragOffsetY = value;
    _dragStateNotifier.value = _QuiTikTokFeedDragState(offsetY: value, action: action, currentIndex: _currentIndex);

    widget.onSwipeProgress?.call(action: action, percentage: (value.abs() / _viewportHeight).clamp(0, 1));
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
        _hasLoadMoreError ||
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

    await onLoadMore();

    if (!mounted) return;

    setState(() {
      _isLoadingMore = false;
      if (widget.items.count <= itemCountBeforeLoad) {
        _exhaustedItemCount = itemCountBeforeLoad;
      }
    });
  }

  @override
  Future<bool> nextFromController() async {
    if (_isControllerActionRunning || !_hasCurrentItem) return false;

    _animationController.stop();
    _isControllerActionRunning = true;

    try {
      await _commitNext();
    } finally {
      if (mounted) {
        _isControllerActionRunning = false;
      }
    }

    return mounted;
  }

  @override
  Future<bool> previousFromController() async {
    if (_isControllerActionRunning || _currentIndex == 0) return false;

    _animationController.stop();
    _isControllerActionRunning = true;

    try {
      await _commitPrevious();
    } finally {
      if (mounted) {
        _isControllerActionRunning = false;
      }
    }

    return mounted;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
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

        _viewportHeight = constraints.maxHeight;

        final nextIndex = _currentIndex + 1;
        final hasNextItem = nextIndex < widget.items.count;
        final paginationCard = _hasCurrentItem ? _buildPaginationCard(context) : null;
        final terminalCard = _hasCurrentItem ? null : _buildTerminalCard(context);
        final isGestureActive = _hasCurrentItem || _currentIndex > 0;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: isGestureActive ? _onVerticalDragStart : null,
          onVerticalDragUpdate: isGestureActive ? _onVerticalDragUpdate : null,
          onVerticalDragEnd: isGestureActive ? _onVerticalDragEnd : null,
          child: ValueListenableBuilder<_QuiTikTokFeedDragState>(
            valueListenable: _dragStateNotifier,
            builder: (context, state, child) {
              final offsetY = state.offsetY;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (offsetY > 0 && _currentIndex > 0)
                    _positionedCard(index: _currentIndex - 1, translateY: offsetY - _viewportHeight),
                  if (offsetY <= 0 && _hasCurrentItem) ...[
                    if (hasNextItem)
                      _positionedCard(index: nextIndex, translateY: offsetY + _viewportHeight)
                    else if (paginationCard != null)
                      _positionedTerminalCard(translateY: offsetY + _viewportHeight, child: paginationCard),
                  ],
                  if (_hasCurrentItem)
                    _positionedCard(index: state.currentIndex, translateY: offsetY)
                  else
                    _positionedTerminalCard(translateY: offsetY, child: terminalCard!),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _positionedCard({required int index, required double translateY}) {
    return RepaintBoundary(
      key: ValueKey('qui_tiktok_feed_card_$index'),
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: KeyedSubtree(
          key: ValueKey('qui_tiktok_feed_content_$index'),
          child: widget.builder(context, widget.items.provider(index), index),
        ),
      ),
    );
  }

  Widget _positionedTerminalCard({required double translateY, required Widget child}) {
    return Transform.translate(offset: Offset(0, translateY), child: child);
  }

  Widget _buildTerminalCard(BuildContext context) {
    if (_hasLoadMoreError) return _loadMoreErrorBuilderCard(context);
    if (_isLoadingMore) return _buildLoadingCard(context);

    return widget.endBuilder?.call(context) ?? const SizedBox.shrink();
  }

  Widget? _buildPaginationCard(BuildContext context) {
    if (_hasLoadMoreError) return _loadMoreErrorBuilderCard(context);
    if (_isLoadingMore) return _buildLoadingCard(context);

    final hasNextItem = _currentIndex + 1 < widget.items.count;
    if (!hasNextItem && _exhaustedItemCount == widget.items.count) {
      return widget.endBuilder?.call(context);
    }

    return null;
  }

  Widget _buildLoadingCard(BuildContext context) {
    return widget.loadingMoreBuilder?.call(context) ?? const Center(child: CircularProgressIndicator());
  }

  Widget _loadMoreErrorBuilderCard(BuildContext context) {
    return widget.loadMoreErrorBuilder!(context, _retryLoadMore);
  }
}

@Preview(name: 'QuiTikTokFeed', group: 'Decks')
Widget quiTikTokFeedPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: const Color(0xFFF6F4F1),
      body: SafeArea(
        child: QuiTikTokFeed<_PreviewOpportunity>(
          items: (count: _previewOpportunities.length, provider: (i) => _previewOpportunities[i]),
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

const _previewOpportunities = [
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

class _PreviewOpportunity {
  const _PreviewOpportunity({
    required this.title,
    required this.place,
    required this.pay,
    required this.time,
    required this.color,
  });

  final String title;
  final String place;
  final String pay;
  final String time;
  final Color color;
}

class _PreviewOpportunityCard extends StatelessWidget {
  const _PreviewOpportunityCard({required this.opportunity});

  final _PreviewOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: opportunity.color, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
            ),
            const Spacer(),
            Text(
              opportunity.pay,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: opportunity.color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              opportunity.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 18),
                const SizedBox(width: 6),
                Text(opportunity.place),
                const SizedBox(width: 16),
                const Icon(Icons.schedule_rounded, size: 18),
                const SizedBox(width: 6),
                Text(opportunity.time),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
