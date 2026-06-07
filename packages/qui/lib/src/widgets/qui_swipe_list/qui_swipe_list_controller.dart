part of 'qui_swipe_list.dart';

/// Controls a [QuiSwipeList] from parent code.
class QuiSwipeListController {
  _QuiSwipeListControllerClient? _client;

  /// Whether this controller is attached to a [QuiSwipeList].
  bool get hasClients => _client != null;

  /// Dismisses the current item and advances the list.
  Future<bool> dismiss() {
    return _client?.dismissFromController() ?? Future<bool>.value(false);
  }

  /// Accepts the current item without advancing the list.
  Future<bool> accept() {
    return _client?.acceptFromController() ?? Future<bool>.value(false);
  }

  void _attach(_QuiSwipeListControllerClient client) {
    assert(
      _client == null || identical(_client, client),
      'A QuiSwipeListController can only be attached to one QuiSwipeList at a time.',
    );

    _client = client;
  }

  void _detach(_QuiSwipeListControllerClient client) {
    if (identical(_client, client)) {
      _client = null;
    }
  }
}

abstract interface class _QuiSwipeListControllerClient {
  Future<bool> dismissFromController();
  Future<bool> acceptFromController();
}
