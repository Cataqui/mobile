part of 'qui_swipe_deck.dart';

/// Controls a [QuiSwipeDeck] from parent code.
class QuiSwipeDeckController {
  _QuiSwipeDeckControllerClient? _client;

  /// Whether this controller is attached to a [QuiSwipeDeck].
  bool get hasClients => _client != null;

  /// Dismisses the current item and advances the deck.
  Future<bool> dismiss() {
    return _client?.dismissFromController() ?? Future<bool>.value(false);
  }

  /// Accepts the current item without advancing the deck.
  Future<bool> accept() {
    return _client?.acceptFromController() ?? Future<bool>.value(false);
  }

  void _attach(_QuiSwipeDeckControllerClient client) {
    assert(
      _client == null || identical(_client, client),
      'A QuiSwipeDeckController can only be attached to one QuiSwipeDeck at a time.',
    );

    _client = client;
  }

  void _detach(_QuiSwipeDeckControllerClient client) {
    if (identical(_client, client)) {
      _client = null;
    }
  }
}

abstract interface class _QuiSwipeDeckControllerClient {
  Future<bool> dismissFromController();
  Future<bool> acceptFromController();
}
