part of 'qui_bottom_sheet.dart';

class _QuiBottomSheetHandleDelegate extends SliverPersistentHeaderDelegate {
  _QuiBottomSheetHandleDelegate({required this.backgroundColor, required this.handleColor})
    : _child = ColoredBox(
        color: backgroundColor,
        child: _QuiBottomSheetHandle(color: handleColor),
      );

  final Color backgroundColor;
  final Color handleColor;
  final Widget _child;

  @override
  double get minExtent => 32;

  @override
  double get maxExtent => 32;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _child;
  }

  @override
  bool shouldRebuild(_QuiBottomSheetHandleDelegate oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor || handleColor != oldDelegate.handleColor;
  }
}
