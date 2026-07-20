part of 'qui_bottom_sheet.dart';

class _QuiBottomSheetSurface<T> extends StatelessWidget {
  const _QuiBottomSheetSurface({required this.route, required this.animation, required this.child});

  static const double _maximumEstimatedBottomCornerRadius = 50;
  static const double _outerMargin = 12;

  static BorderRadius _resolveBorderRadius(MediaQueryData mediaQuery, TargetPlatform platform) {
    const double _defaultBorderRadius = 36;
    final displayCornerRadii = mediaQuery.displayCornerRadii;

    if (displayCornerRadii != null) {
      return BorderRadius.only(
        topLeft: const Radius.circular(_defaultBorderRadius),
        topRight: const Radius.circular(_defaultBorderRadius),
        bottomLeft: Radius.circular(math.max(_defaultBorderRadius, displayCornerRadii.bottomLeft.x - _outerMargin)),
        bottomRight: Radius.circular(math.max(_defaultBorderRadius, displayCornerRadii.bottomRight.x - _outerMargin)),
      );
    }

    if (platform != TargetPlatform.iOS || mediaQuery.size.shortestSide >= 600) {
      return const BorderRadius.all(Radius.circular(_defaultBorderRadius));
    }

    final estimatedDisplayCornerRadius = math.max(
      mediaQuery.viewPadding.top,
      math.max(mediaQuery.viewPadding.left, mediaQuery.viewPadding.right),
    );

    final bottomCornerRadius = math.min(
      _maximumEstimatedBottomCornerRadius,
      math.max(_defaultBorderRadius, estimatedDisplayCornerRadius - _outerMargin),
    );

    return BorderRadius.only(
      topLeft: const Radius.circular(_defaultBorderRadius),
      topRight: const Radius.circular(_defaultBorderRadius),
      bottomLeft: Radius.circular(bottomCornerRadius),
      bottomRight: Radius.circular(bottomCornerRadius),
    );
  }

  final _QuiBottomSheetRoute<T> route;
  final Animation<double> animation;
  final Widget child;

  void _dismiss(BuildContext context) {
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = math.max(0, mediaQuery.size.height - mediaQuery.viewInsets.bottom);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        key: const Key('qui_bottom_sheet_outer_padding'),
        padding: EdgeInsets.fromLTRB(_outerMargin, 0, _outerMargin, mediaQuery.viewInsets.bottom + _outerMargin),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight * _QuiBottomSheetRoute._maximumHeightFraction),
          child: route.scrollable ? _buildScrollableSheet(context) : _buildIntrinsicSheet(context),
        ),
      ),
    );
  }

  Widget _buildScrollableSheet(BuildContext context) {
    final colorScheme = context.qui.colorScheme.bottomSheet;

    return DraggableScrollableSheet(
      controller: route._scrollableController,
      initialChildSize: route._initialScrollableExtent,
      minChildSize: route._initialScrollableExtent,
      maxChildSize: 1,
      expand: false,
      shouldCloseOnMinExtent: false,
      builder: (context, scrollController) => route.buildSheetTransition(
        animation: animation,
        child: _buildSheet(
          context,
          showFixedHandle: false,
          content: Expanded(
            child: CustomScrollView(
              key: const Key('qui_bottom_sheet_scroll_view'),
              controller: scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _QuiBottomSheetHandleDelegate(
                    backgroundColor: colorScheme.background,
                    handleColor: colorScheme.handle,
                  ),
                ),
                SliverSafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverToBoxAdapter(child: child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntrinsicSheet(BuildContext context) {
    return route.buildSheetTransition(
      animation: animation,
      child: _buildSheet(
        context,
        content: Flexible(
          child: SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: child),
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, {required Widget content, bool showFixedHandle = true}) {
    final colorScheme = context.qui.colorScheme.bottomSheet;

    return SizedBox(
      key: route._sheetMeasurementKey,
      width: double.infinity,
      child: _QuiBottomSheetDragSurface(
        route: route,
        child: Semantics(
          onDismiss: () => _dismiss(context),
          child: ClipRSuperellipse(
            borderRadius: _resolveBorderRadius(MediaQuery.of(context), Theme.of(context).platform),
            clipBehavior: Clip.antiAlias,
            child: Material(
              key: const Key('qui_bottom_sheet_surface'),
              color: colorScheme.background,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showFixedHandle) _QuiBottomSheetHandle(color: colorScheme.handle),
                  content,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
