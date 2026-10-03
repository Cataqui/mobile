import 'dart:async';

import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final class JobLocationImagePrefetcher {
  JobLocationImagePrefetcher({required this.cacheManager, this.prepareImage});

  final BaseCacheManager cacheManager;
  final Future<void> Function(StaticMapRequest request)? prepareImage;
  final Map<String, bool> _activeKeys = {};
  final Map<String, bool> _attemptedKeys = {};
  List<({StaticMapRequest request, bool decode})> _pending = [];
  bool _disposed = false;

  void update({required List<StaticMapRequest> requests, List<StaticMapRequest> decodedRequests = const []}) {
    if (_disposed) return;
    assert(decodedRequests.isEmpty || prepareImage != null, 'Decoded prefetch requires image preparation.');
    final desiredKeys = {
      ...requests.map((request) => request.cacheKey),
      ...decodedRequests.map((request) => request.cacheKey),
    };
    _attemptedKeys.removeWhere((key, _) => !desiredKeys.contains(key));
    final queuedKeys = <String>{};
    _pending =
        [
          for (final request in decodedRequests) (request: request, decode: true),
          for (final request in requests) (request: request, decode: false),
        ].where((task) {
          final key = task.request.cacheKey;
          if ((_activeKeys[key] ?? false) || (_attemptedKeys[key] ?? false)) return false;
          if (!task.decode && (_activeKeys.containsKey(key) || _attemptedKeys.containsKey(key))) return false;
          return queuedKeys.add(key);
        }).toList();
    _startPending();
  }

  void dispose() {
    _disposed = true;
    _pending.clear();
    _attemptedKeys.clear();
  }

  void _startPending() {
    while (!_disposed && _activeKeys.length < 2 && _pending.isNotEmpty) {
      final index = _pending.indexWhere((task) => !_activeKeys.containsKey(task.request.cacheKey));
      if (index < 0) return;
      final task = _pending.removeAt(index);
      _activeKeys[task.request.cacheKey] = task.decode;
      _attemptedKeys[task.request.cacheKey] = task.decode;
      unawaited(_prefetch(request: task.request, decode: task.decode));
    }
  }

  Future<void> _prefetch({required StaticMapRequest request, required bool decode}) async {
    try {
      if (decode) {
        await prepareImage!(request);
        return;
      }
      await cacheManager.getSingleFile(request.url, key: request.cacheKey);
    } on Exception {
      // Speculative failures leave error feedback and retries to the visible map.
    } finally {
      _activeKeys.remove(request.cacheKey);
      _startPending();
    }
  }
}
