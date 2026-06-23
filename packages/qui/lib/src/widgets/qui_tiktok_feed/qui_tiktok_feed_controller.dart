part of 'qui_tiktok_feed.dart';

/// Controls a [QuiTikTokFeed] from parent code.
class QuiTikTokFeedController {
  _QuiTikTokFeedControllerClient? _client;

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

  void _attach(_QuiTikTokFeedControllerClient client) {
    assert(
      _client == null || identical(_client, client),
      'A QuiTikTokFeedController can only be attached to one QuiTikTokFeed at a time.',
    );

    _client = client;
  }

  void _detach(_QuiTikTokFeedControllerClient client) {
    if (identical(_client, client)) _client = null;
  }
}

abstract interface class _QuiTikTokFeedControllerClient {
  Future<bool> nextFromController();
  Future<bool> previousFromController();
}
