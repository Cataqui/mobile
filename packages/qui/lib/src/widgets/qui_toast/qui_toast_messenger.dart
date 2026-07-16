part of 'qui_toast.dart';

/// Manages [QuiToast] entries and keeps them above navigator-owned overlays.
///
/// [QuiApp.router] auto-injects a [QuiToastMessenger] above the navigator so
/// toasts always paint above the needed surface. [QuiToast.show] finds the nearest
/// [QuiToastMessenger] via the provided [BuildContext].
///
/// ```dart
/// QuiToast.show(context, message: 'Something went wrong');
/// ```
///
/// See also:
///  * [QuiToast.show], the API that inserts toast messages into this messenger.
///  * [QuiApp.router], which auto-injects this messenger.
class QuiToastMessenger extends StatefulWidget {
  /// Creates a toast messenger around [child].
  ///
  /// The [child] subtree renders below toast overlay entries.
  const QuiToastMessenger({required this.child, super.key});

  /// The subtree that renders below toast overlay entries.
  final Widget child;

  @override
  State<QuiToastMessenger> createState() => QuiToastMessengerState();

  /// Finds the nearest [QuiToastMessengerState] ancestor of [context].
  ///
  /// Returns null if no messenger is mounted above [context].
  static QuiToastMessengerState? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_QuiToastMessengerScope>();
    return scope?._state;
  }
}

class QuiToastMessengerState extends State<QuiToastMessenger> {
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  late final OverlayEntry _childEntry = OverlayEntry(builder: (_) => widget.child);

  _QuiToastPresentation? _activePresentation;

  /// The overlay this messenger renders toast entries into.
  OverlayState? get overlay => _overlayKey.currentState;

  /// Removes the currently active toast, if any.
  void dismissActive() {
    _activePresentation?.remove();
    _activePresentation = null;
  }

  @override
  void didUpdateWidget(QuiToastMessenger oldWidget) {
    super.didUpdateWidget(oldWidget);
    _childEntry.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    return _QuiToastMessengerScope(
      state: this,
      child: Overlay(key: _overlayKey, initialEntries: [_childEntry]),
    );
  }
}

class _QuiToastMessengerScope extends InheritedWidget {
  const _QuiToastMessengerScope({required this._state, required super.child});

  final QuiToastMessengerState _state;

  @override
  bool updateShouldNotify(_QuiToastMessengerScope old) => _state != old._state;
}
