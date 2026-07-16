part of 'qui_toast.dart';

class _QuiToastPresentation {
  const _QuiToastPresentation({required this.entry});

  final OverlayEntry entry;

  void remove() {
    if (!entry.mounted) return;

    entry.remove();
  }
}
