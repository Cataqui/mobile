part of 'qui_tiktok_feed.dart';

/// Controls a [QuiTikTokFeed] from parent code.
///
/// Call [dispose] when the controller itself is no longer needed.
class QuiTikTokFeedController {
  _QuiTikTokFeedControllerClient? _client;

  final List<void Function(QuiTikTokFeedNotification)> _notificationListeners = [];

  /// Whether this controller is attached to a [QuiTikTokFeed].
  bool get hasClients => _client != null;

  /// Advances to the next item.
  Future<bool> next() {
    return _client?.nextFromController() ?? Future<bool>.value(false);
  }

  /// Goes back to the previous item.
  Future<bool> previous() {
    return _client?.previousFromController() ?? Future<bool>.value(false);
  }

  /// Registers [listener] to receive [QuiTikTokFeedNotification] events from
  /// the attached feed.
  ///
  /// Listeners are notified whenever the feed commits to a discrete action
  /// (for example, advancing to the next item). The same listener can be
  /// added only once; duplicate registrations are ignored.
  ///
  /// Call [removeNotificationListener] when the listener should stop
  /// receiving events — typically in [State.dispose] of the owning widget.
  void addNotificationListener(void Function(QuiTikTokFeedNotification) listener) {
    if (!_notificationListeners.contains(listener)) {
      _notificationListeners.add(listener);
    }
  }

  /// Removes a previously registered [listener].
  ///
  /// Has no effect if [listener] was never added or already removed. Safe to
  /// call during a notification dispatch (the list is iterated over a copy).
  void removeNotificationListener(void Function(QuiTikTokFeedNotification) listener) {
    _notificationListeners.remove(listener);
  }

  /// Releases resources held by this controller.
  ///
  /// Clears all notification listeners and detaches from any attached feed.
  /// Call this when the controller is no longer needed — typically in
  /// [State.dispose] of the owning widget or in a Riverpod
  /// `ref.onDispose` callback.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  void dispose() {
    _notificationListeners.clear();
    _client = null;
  }

  void _attach(_QuiTikTokFeedControllerClient client) {
    if (_client != null && !identical(_client, client)) {
      throw FlutterError('A QuiTikTokFeedController can only be attached to one QuiTikTokFeed at a time.');
    }

    _client = client;
  }

  void _detach(_QuiTikTokFeedControllerClient client) {
    if (identical(_client, client)) _client = null;
  }

  void _notify(QuiTikTokFeedNotification notification) {
    for (final listener in _notificationListeners.toList()) {
      listener(notification);
    }
  }
}

abstract interface class _QuiTikTokFeedControllerClient {
  Future<bool> nextFromController();
  Future<bool> previousFromController();
}
