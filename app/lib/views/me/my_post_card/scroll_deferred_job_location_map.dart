part of 'my_post_card.dart';

class _ScrollDeferredJobLocationMap extends StatefulWidget {
  const _ScrollDeferredJobLocationMap({required this.map});

  final JobLocationMap map;

  @override
  State<_ScrollDeferredJobLocationMap> createState() => _ScrollDeferredJobLocationMapState();
}

class _ScrollDeferredJobLocationMapState extends State<_ScrollDeferredJobLocationMap> {
  ScrollPosition? _scrollPosition;
  bool _hasShownMap = false;

  void _showMapWhenScrollingStops() {
    if (_scrollPosition?.isScrollingNotifier.value ?? true) return;

    _scrollPosition?.isScrollingNotifier.removeListener(_showMapWhenScrollingStops);
    _scrollPosition = null;
    setState(() => _hasShownMap = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasShownMap) return;

    final scrollable = Scrollable.maybeOf(context, axis: .horizontal);
    if (scrollable == null) {
      _scrollPosition?.isScrollingNotifier.removeListener(_showMapWhenScrollingStops);
      _scrollPosition = null;
      _hasShownMap = true;
      return;
    }

    final scrollPosition = scrollable.position;
    if (!Scrollable.recommendDeferredLoadingForContext(context, axis: .horizontal)) {
      _scrollPosition?.isScrollingNotifier.removeListener(_showMapWhenScrollingStops);
      _scrollPosition = null;
      _hasShownMap = true;
      return;
    }

    if (_scrollPosition == scrollPosition) return;
    _scrollPosition?.isScrollingNotifier.removeListener(_showMapWhenScrollingStops);
    _scrollPosition = scrollPosition;
    scrollPosition.isScrollingNotifier.addListener(_showMapWhenScrollingStops);
  }

  @override
  void dispose() {
    _scrollPosition?.isScrollingNotifier.removeListener(_showMapWhenScrollingStops);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasShownMap) return widget.map;
    return ColoredBox(key: const ValueKey('me_post_deferred_map'), color: MateoTheme.of(context).palette.neutral[2]);
  }
}
