part of 'qui_bottom_sheet.dart';

class _QuiBottomSheetHandle extends StatelessWidget {
  const _QuiBottomSheetHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Center(
        child: SizedBox(
          key: const Key('qui_bottom_sheet_handle'),
          width: 36,
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.all(Radius.circular(999))),
          ),
        ),
      ),
    );
  }
}
