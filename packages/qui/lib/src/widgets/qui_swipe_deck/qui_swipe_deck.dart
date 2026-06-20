library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';

part 'qui_swipe_deck_action.dart';
part 'qui_swipe_deck_card_drag_state.dart';
part 'qui_swipe_deck_controller.dart';
part 'qui_swipe_deck_types.dart';

/// A generic Tinder-style swipe deck for arbitrary item widgets.
///
/// The widget renders one active item at a time. Swiping left dismisses the
/// item and advances to the next entry. Swiping right calls [onAccept] and
/// snaps the same item back to the center.
class QuiSwipeDeck<T> extends StatefulWidget {
  /// Creates a swipeable generic deck.
  const QuiSwipeDeck({
    required this.itemCount,
    required this.itemProvider,
    required this.builder,
    super.key,
    this.controller,
    this.loadingMoreBuilder,
    this.buildLoadMoreError,
    this.endBuilder,
    this.onSwipeProgress,
    this.onDismiss,
    this.onAccept,
    this.onLoadMore,
    this.dismissThreshold = 0.35,
    this.acceptThreshold = 0.35,
    this.loadMoreThreshold = 1,
    this.maxRotation = 0.18,
    this.enableHapticFeedback = true,
  }) : assert(
         dismissThreshold > 0 && dismissThreshold <= 1,
         'dismissThreshold must be greater than 0 and less than or equal to 1.',
       ),
       assert(
         acceptThreshold > 0 && acceptThreshold <= 1,
         'acceptThreshold must be greater than 0 and less than or equal to 1.',
       ),
       assert(
         loadMoreThreshold >= 0 && loadMoreThreshold <= 1,
         'loadMoreThreshold must be greater than or equal to 0 and less than or equal to 1.',
       ),
       assert(itemCount >= 0, 'itemCount must be greater than or equal to 0.'),
       assert(maxRotation >= 0, 'maxRotation must be greater than or equal to 0.');

  /// Number of items available to the swipe deck.
  final int itemCount;

  /// Lazily provides an item by index.
  ///
  /// Only the current item and, when available, the next item are requested.
  final QuiSwipeDeckItemProvider<T> itemProvider;

  /// Builds each item widget.
  final QuiSwipeDeckItemBuilder<T> builder;

  /// Controls this swipe deck from parent code.
  final QuiSwipeDeckController? controller;

  /// Builds the loading card shown while more items are loading.
  final WidgetBuilder? loadingMoreBuilder;

  /// Builds the load-more error card shown at the end of the deck.
  ///
  /// When null, loading more is treated as error-free.
  /// If provided, it treats as having a load-more error immediately.
  final QuiSwipeDeckLoadMoreErrorBuilder? buildLoadMoreError;

  /// Builds content when pagination ends after all loaded cards are dismissed.
  final WidgetBuilder? endBuilder;

  /// Called whenever the swipe position changes.
  final QuiSwipeDeckProgressCallback? onSwipeProgress;

  /// Called after a left dismiss completes and the deck advances.
  final QuiSwipeDeckItemCallback<T>? onDismiss;

  /// Called when a right accept is released past the threshold.
  final QuiSwipeDeckItemCallback<T>? onAccept;

  /// Called when the current index reaches [loadMoreThreshold].
  final QuiSwipeDeckLoadMoreCallback? onLoadMore;

  /// Percentage of the widget width required to dismiss left.
  final double dismissThreshold;

  /// Percentage of the widget width required to accept right.
  final double acceptThreshold;

  /// Loaded-deck progress required to call [onLoadMore].
  final double loadMoreThreshold;

  /// Maximum card rotation in radians while dragging.
  final double maxRotation;

  /// Whether the deck emits soft haptic ticks while the user drags a card.
  ///
  /// Defaults to `true`. Set to `false` to disable all drag haptics.
  final bool enableHapticFeedback;

  @override
  State<QuiSwipeDeck<T>> createState() => _QuiSwipeDeckState<T>();
}

class _QuiSwipeDeckState<T> extends State<QuiSwipeDeck<T>>
    with SingleTickerProviderStateMixin
    implements _QuiSwipeDeckControllerClient {
  static const _settleDuration = Duration(milliseconds: 260);
  static const _dismissDuration = Duration(milliseconds: 220);

  late final AnimationController _animationController;

  Animation<Offset>? _positionAnimation;
  Offset _dragOffset = Offset.zero;
  QuiSwipeDeckAction _lastAction = QuiSwipeDeckAction.dismiss;
  int _currentIndex = 0;
  int? _exhaustedItemCount;
  double _lastKnownWidth = 1;
  bool _isLoadingMore = false;
  bool _isLoadMoreScheduled = false;
  bool _isControllerActionRunning = false;
  int _lastHapticStep = -1;
  final ValueNotifier<_QuiSwipeDeckCardDragState> _dragStateNotifier = ValueNotifier<_QuiSwipeDeckCardDragState>(
    const _QuiSwipeDeckCardDragState(offset: Offset.zero, action: QuiSwipeDeckAction.dismiss, currentIndex: 0),
  );

  bool get _hasCurrentItem => _currentIndex < widget.itemCount;
  bool get _hasLoadMoreError => widget.buildLoadMoreError != null;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: _settleDuration)
      ..addListener(_syncAnimatedPosition);
    widget.controller?._attach(this);
    _scheduleLoadMoreIfNeeded();
  }

  @override
  void didUpdateWidget(covariant QuiSwipeDeck<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    if (_currentIndex > widget.itemCount) {
      _currentIndex = widget.itemCount;
      _dragOffset = Offset.zero;
      _dragStateNotifier.value = _QuiSwipeDeckCardDragState(
        offset: Offset.zero,
        action: _lastAction,
        currentIndex: _currentIndex,
      );
    }

    if (widget.itemCount > oldWidget.itemCount || widget.itemCount > (_exhaustedItemCount ?? -1)) {
      _exhaustedItemCount = null;
    }

    if (widget.itemCount != oldWidget.itemCount) {
      _scheduleLoadMoreIfNeeded();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);

    _animationController
      ..removeListener(_syncAnimatedPosition)
      ..dispose();

    _dragStateNotifier.dispose();

    super.dispose();
  }

  void _syncAnimatedPosition() {
    final positionAnimation = _positionAnimation;
    if (positionAnimation == null) return;

    _setDragOffset(positionAnimation.value);
  }

  void _onPanStart(DragStartDetails details) {
    if (_isControllerActionRunning) return;

    _animationController.stop();
    _lastHapticStep = -1;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isControllerActionRunning) return;

    _setDragOffset(_dragOffset + details.delta);

    if (widget.enableHapticFeedback) {
      final progress = _horizontalPercentage(_dragOffset.dx);
      const stepSize = 0.08;
      final currentStep = (progress / stepSize).floor();
      if (currentStep != _lastHapticStep) {
        _lastHapticStep = currentStep;
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_isControllerActionRunning) return;
    if (!_hasCurrentItem) return;

    final item = widget.itemProvider(_currentIndex);
    final itemIndex = _currentIndex;
    final horizontalPercentage = _horizontalPercentage(_dragOffset.dx);

    if (_dragOffset.dx < 0 && horizontalPercentage >= widget.dismissThreshold) {
      await _completeDismiss(item: item, itemIndex: itemIndex);
      return;
    }

    if (_dragOffset.dx > 0 && horizontalPercentage >= widget.acceptThreshold) {
      widget.onAccept?.call(item, itemIndex);

      await _animateTo(Offset.zero, duration: _settleDuration);
      return;
    }

    await _animateTo(Offset.zero, duration: _settleDuration);
  }

  Future<void> _dismissCurrentItem() {
    final endX = -_lastKnownWidth * 1.25;
    final endY = _dragOffset.dy + _dragOffset.dy.sign * 24;

    return _animateTo(Offset(endX, endY), duration: _dismissDuration, curve: Curves.easeIn);
  }

  Future<void> _completeDismiss({required T item, required int itemIndex}) async {
    await _dismissCurrentItem();

    if (!mounted) return;

    setState(() {
      _currentIndex += 1;
      _dragOffset = Offset.zero;
    });

    _dragStateNotifier.value = _QuiSwipeDeckCardDragState(
      offset: Offset.zero,
      action: _lastAction,
      currentIndex: _currentIndex,
    );

    widget.onDismiss?.call(item, itemIndex);
    _scheduleLoadMoreIfNeeded();
  }

  Future<void> _animateTo(Offset target, {required Duration duration, Curve curve = Curves.easeOutCubic}) {
    final begin = _dragOffset;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      _setDragOffset(target);

      return Future<void>.value();
    }

    _positionAnimation = Tween<Offset>(
      begin: begin,
      end: target,
    ).chain(CurveTween(curve: curve)).animate(_animationController);

    _animationController
      ..duration = duration
      ..reset();

    return _animationController.forward();
  }

  void _setDragOffset(Offset value) {
    final action = value.dx == 0
        ? _lastAction
        : value.dx > 0
        ? QuiSwipeDeckAction.accept
        : QuiSwipeDeckAction.dismiss;

    _lastAction = action;
    _dragOffset = value;
    _dragStateNotifier.value = _QuiSwipeDeckCardDragState(offset: value, action: action, currentIndex: _currentIndex);

    widget.onSwipeProgress?.call(action: action, percentage: _horizontalPercentage(value.dx));
  }

  double _horizontalPercentage(double horizontalOffset) => (horizontalOffset.abs() / _lastKnownWidth).clamp(0, 1);

  double _rotationForDrag(QuiSwipeDeckAction action, double progress) {
    final direction = switch (action) {
      QuiSwipeDeckAction.dismiss => -1,
      QuiSwipeDeckAction.accept => 1,
    };

    return direction * math.min(progress, 1) * widget.maxRotation;
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
        widget.itemCount == 0 ||
        _hasLoadMoreError ||
        _isLoadingMore ||
        _exhaustedItemCount == widget.itemCount) {
      return false;
    }

    final loadedProgress = (_currentIndex + 1) / widget.itemCount;
    return loadedProgress >= widget.loadMoreThreshold;
  }

  Future<void> _startLoadMore() async {
    final onLoadMore = widget.onLoadMore;
    if (onLoadMore == null || _isLoadingMore) return;

    final itemCountBeforeLoad = widget.itemCount;

    setState(() => _isLoadingMore = true);

    await onLoadMore();

    if (!mounted) return;

    setState(() {
      _isLoadingMore = false;
      if (widget.itemCount <= itemCountBeforeLoad) {
        _exhaustedItemCount = itemCountBeforeLoad;
      }
    });
  }

  @override
  Future<bool> dismissFromController() async {
    if (_isControllerActionRunning || !_hasCurrentItem) return false;

    final item = widget.itemProvider(_currentIndex);
    final itemIndex = _currentIndex;

    _animationController.stop();
    _isControllerActionRunning = true;

    try {
      await _completeDismiss(item: item, itemIndex: itemIndex);
    } finally {
      if (mounted) {
        _isControllerActionRunning = false;
      }
    }

    return mounted;
  }

  @override
  Future<bool> acceptFromController() {
    if (_isControllerActionRunning || !_hasCurrentItem) return Future<bool>.value(false);

    final item = widget.itemProvider(_currentIndex);
    final itemIndex = _currentIndex;

    _animationController.stop();
    _isControllerActionRunning = true;

    try {
      widget.onAccept?.call(item, itemIndex);
    } finally {
      _isControllerActionRunning = false;
    }

    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCurrentItem) return _buildTerminalCard(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastKnownWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final nextIndex = _currentIndex + 1;
        final hasNextItem = nextIndex < widget.itemCount;
        final paginationCard = _buildPaginationCard(context);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: ValueListenableBuilder<_QuiSwipeDeckCardDragState>(
            valueListenable: _dragStateNotifier,
            builder: (context, state, child) {
              final progress = _horizontalPercentage(state.offset.dx);
              final nextScale = 0.96 + (0.04 * progress);

              return Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  if (hasNextItem)
                    _positionedCard(index: nextIndex, scale: nextScale, translate: Offset.zero, rotate: 0)
                  else if (paginationCard != null)
                    Transform.scale(scale: nextScale, child: paginationCard),
                  _positionedCard(
                    index: state.currentIndex,
                    scale: 1,
                    translate: state.offset,
                    rotate: _rotationForDrag(state.action, progress),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _positionedCard({
    required int index,
    required double scale,
    required Offset translate,
    required double rotate,
  }) {
    final transformMatrix = Matrix4.identity()
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(translate.dx, translate.dy, 0, 1)
      ..rotateZ(rotate);

    return RepaintBoundary(
      key: ValueKey('qui_swipe_deck_slot_$index'),
      child: Transform(
        transform: transformMatrix,
        alignment: Alignment.center,
        child: KeyedSubtree(
          key: ValueKey('qui_swipe_deck_card_$index'),
          child: widget.builder(context, widget.itemProvider(index), index),
        ),
      ),
    );
  }

  Widget _buildTerminalCard(BuildContext context) {
    if (_hasLoadMoreError) return _buildLoadMoreErrorCard(context);

    if (_isLoadingMore) return _buildLoadingCard(context);

    return widget.endBuilder?.call(context) ?? const SizedBox.shrink();
  }

  Widget? _buildPaginationCard(BuildContext context) {
    if (_hasLoadMoreError) return _buildLoadMoreErrorCard(context);
    if (_isLoadingMore) return _buildLoadingCard(context);

    return null;
  }

  Widget _buildLoadingCard(BuildContext context) {
    return widget.loadingMoreBuilder?.call(context) ?? const Center(child: CircularProgressIndicator());
  }

  Widget _buildLoadMoreErrorCard(BuildContext context) {
    return widget.buildLoadMoreError!(context, _retryLoadMore);
  }
}

@Preview(name: 'QuiSwipeDeck', group: 'Decks')
Widget quiSwipeDeckPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: const Color(0xFFF6F4F1),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 340,
            height: 460,
            child: QuiSwipeDeck<_PreviewOpportunity>(
              itemCount: _previewOpportunities.length,
              itemProvider: (index) => _previewOpportunities[index],
              builder: (context, opportunity, index) {
                return _PreviewOpportunityCard(opportunity: opportunity);
              },
              endBuilder: (context) {
                return const Center(child: Text('Sem oportunidades por aqui'));
              },
            ),
          ),
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
