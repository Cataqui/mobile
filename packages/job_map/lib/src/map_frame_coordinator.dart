import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:job_map/src/job_map_scene.dart';
import 'package:job_map/src/map_frame.dart';
import 'package:job_map/src/map_frame_engine.dart';
import 'package:job_map/src/map_frame_engine_types.dart';
import 'package:job_map/src/map_render_budget.dart';
import 'package:job_map/src/map_viewport_motion.dart';

@immutable
final class MapSceneDemand {
  const MapSceneDemand({
    required this.scene,
    required this.visibleFraction,
    required this.distanceFromCurrent,
    this.distanceFromArrival,
  }) : assert(visibleFraction >= 0 && visibleFraction <= 1, 'visibleFraction must be between zero and one'),
       assert(distanceFromArrival == null || distanceFromArrival >= 0, 'distanceFromArrival must be non-negative');

  final JobMapScene scene;
  final double visibleFraction;
  final int distanceFromCurrent;
  final int? distanceFromArrival;
}

final class MapRouteLease {
  MapRouteLease._({
    required this.allowSlowScrollCapture,
    required this.predictDistantMaps,
    required this.skipIntermediateMapsOnRapidScroll,
  });

  final bool allowSlowScrollCapture;
  final bool predictDistantMaps;
  final bool skipIntermediateMapsOnRapidScroll;
}

final class MapFrameCoordinator extends ChangeNotifier with WidgetsBindingObserver {
  MapFrameCoordinator({
    required this.engine,
    required int maxCachedBytes,
    this.renderBudget,
    this.retryDelay = const Duration(seconds: 2),
    @visibleForTesting this._readElapsedTime,
  }) : _maxCachedBytes = maxCachedBytes,
       assert(maxCachedBytes > 0, 'maxCachedBytes must be positive'),
       assert(engine.rendererSlotCount > 0, 'rendererSlotCount must be positive') {
    WidgetsBinding.instance.addObserver(this);
    engine.setFrameFinalListener(_onFrameFinal);
    engine.setFrameProgressListener(_onFrameProgress);
    engine.setRendererResetListener(invalidateFrames);
    renderBudget?.addListener(_onRenderBudgetChanged);
  }

  final MapFrameEngine engine;
  final MapRenderBudget? renderBudget;
  final Duration retryDelay;
  final int _maxCachedBytes;
  final Duration Function()? _readElapsedTime;

  final Map<
    MapRouteLease,
    ({
      bool visible,
      List<MapSceneDemand> demands,
      int direction,
      int activation,
      MapViewportMotion motion,
      bool predictDistantMaps,
      bool skipIntermediateMapsOnRapidScroll,
    })
  >
  _routes = {};
  final Set<MapRouteLease> _scrollingRoutes = {};
  final LinkedHashMap<JobMapScene, MapFrame> _fullFrames = LinkedHashMap<JobMapScene, MapFrame>();
  final LinkedHashMap<JobMapScene, MapFrame> _previewFrames = LinkedHashMap<JobMapScene, MapFrame>();
  final Map<
    int,
    ({
      int requestId,
      JobMapScene scene,
      JobMapScene renderScene,
      bool qualityRefinement,
      bool awaitingFinal,
      int routeActivation,
      int direction,
    })
  >
  _activeRenders = {};
  final Map<int, JobMapScene> _rendererScenes = {};
  final Map<int, ({MapFrame full, MapFrame preview})> _pendingQualityFrames = {};
  final Map<JobMapScene, JobMapScene> _qualityAttempts = {};
  final Map<int, Timer> _finalizationTimers = {};
  final Map<int, MapFrameFinalEvent> _earlyFinalNotifications = {};
  final Map<int, int> _frameHolds = {};
  final Map<int, MapFrame> _retiredFrames = {};
  final Set<JobMapScene> _partialScenes = {};
  final Set<JobMapScene> _finalizationTimedOutScenes = {};
  final Set<JobMapScene> _failedScenes = {};
  final Map<JobMapScene, int> _failureCounts = {};
  final Map<JobMapScene, Timer> _retryTimers = {};
  final Set<Future<void>> _pendingRenders = {};
  final Set<Future<void>> _pendingReleases = {};
  final Stopwatch _viewportClock = Stopwatch()..start();
  final Set<int> _completedRendererSlots = {};
  Timer? _scrollMotionIdleTimer;
  Duration? _firstFrameLatency;
  Duration? _lastRapidRetargetAt;
  int? _lastRapidRetargetActivation;
  int _nextRequestId = 0;
  int _nextActivation = 0;
  int _cachedBytes = 0;
  bool _scheduled = false;
  bool _isDisposed = false;
  bool _wasBackgrounded = false;
  bool _nativeScrollActive = false;
  bool _nativeReadyPreviewAllowed = false;

  int get cachedBytes => _cachedBytes + _retiredFrames.values.fold(0, (bytes, frame) => bytes + frame.byteCount);
  int get maxCachedBytes => renderBudget?.cacheBytes ?? _maxCachedBytes;
  int get prefetchDepth => renderBudget?.maxOffscreenPrefetchScenes ?? 6;

  int predictTravelCards(MapRouteLease lease, {required double position}) {
    final route = _routes[lease];
    if (route == null) return 0;
    route.motion.update(position: position, timestamp: _elapsedTime);
    if (!_scrollingRoutes.contains(lease)) return 0;
    return route.motion.distanceAfter(_firstFrameLatency ?? const Duration(milliseconds: 400));
  }

  MapRouteLease openRouteLease({
    bool visible = true,
    bool allowSlowScrollCapture = false,
    bool predictDistantMaps = true,
    bool skipIntermediateMapsOnRapidScroll = false,
  }) {
    final lease = MapRouteLease._(
      allowSlowScrollCapture: allowSlowScrollCapture,
      predictDistantMaps: predictDistantMaps,
      skipIntermediateMapsOnRapidScroll: skipIntermediateMapsOnRapidScroll,
    );
    _routes[lease] = (
      visible: visible,
      demands: const [],
      direction: 0,
      activation: ++_nextActivation,
      motion: MapViewportMotion(),
      predictDistantMaps: lease.predictDistantMaps,
      skipIntermediateMapsOnRapidScroll: lease.skipIntermediateMapsOnRapidScroll,
    );
    _syncNativeScrollActivity();
    _schedule();
    return lease;
  }

  void setRouteScrolling(MapRouteLease lease, bool scrolling) {
    if (!_routes.containsKey(lease)) return;
    final changed = scrolling ? _scrollingRoutes.add(lease) : _scrollingRoutes.remove(lease);
    if (!changed) return;
    _routes[lease]!.motion.reset();
    if (!scrolling) {
      _lastRapidRetargetAt = null;
      _lastRapidRetargetActivation = null;
    }
    if (scrolling && _activeRouteScrolling) _cancelQualityRefinements();
    _syncNativeScrollActivity();
    _schedule();
  }

  void setRouteVisible(MapRouteLease lease, bool visible) {
    final route = _routes[lease];
    if (route == null || route.visible == visible) return;
    _routes[lease] = (
      visible: visible,
      demands: route.demands,
      direction: route.direction,
      activation: visible ? ++_nextActivation : route.activation,
      motion: route.motion..reset(),
      predictDistantMaps: route.predictDistantMaps,
      skipIntermediateMapsOnRapidScroll: route.skipIntermediateMapsOnRapidScroll,
    );
    if (visible) {
      _clearFailures();
      _cancelQualityRefinements(scenes: _visibleScenes());
    }
    _syncNativeScrollActivity();
    _schedule();
  }

  void updateViewport(
    MapRouteLease lease, {
    required List<MapSceneDemand> demands,
    required int direction,
    double? position,
  }) {
    assert(direction >= -1 && direction <= 1, 'direction must be -1, zero, or 1');
    final route = _routes[lease];
    if (route == null) return;
    if (position != null) route.motion.update(position: position, timestamp: _elapsedTime);
    final basemapDemands = [
      for (final demand in demands)
        MapSceneDemand(
          scene: demand.scene.basemap,
          visibleFraction: demand.visibleFraction,
          distanceFromCurrent: demand.distanceFromCurrent,
          distanceFromArrival: demand.distanceFromArrival,
        ),
    ];
    final oldScenes = route.demands.map((demand) => demand.scene).toSet();
    final newScenes = basemapDemands.map((demand) => demand.scene).toSet();
    final previouslyVisible = {
      for (final demand in route.demands)
        if (demand.visibleFraction > 0) demand.scene,
    };
    if (direction != route.direction || !setEquals(oldScenes, newScenes)) {
      _clearFailures();
    } else {
      for (final demand in basemapDemands) {
        if (demand.visibleFraction == 0 || previouslyVisible.contains(demand.scene)) continue;
        if (!_failedScenes.remove(demand.scene)) continue;
        _failureCounts.remove(demand.scene);
        _retryTimers.remove(demand.scene)?.cancel();
      }
    }
    _routes[lease] = (
      visible: route.visible,
      demands: List<MapSceneDemand>.unmodifiable(basemapDemands),
      direction: direction,
      activation: route.activation,
      motion: route.motion,
      predictDistantMaps: route.predictDistantMaps,
      skipIntermediateMapsOnRapidScroll: route.skipIntermediateMapsOnRapidScroll,
    );
    _cancelQualityRefinements(scenes: _visibleScenes().difference(previouslyVisible));
    _syncNativeScrollActivity();
    _schedule();
  }

  void closeRouteLease(MapRouteLease lease) {
    if (_routes.remove(lease) == null) return;
    _scrollingRoutes.remove(lease);
    _syncNativeScrollActivity();
    if (_routes.isEmpty) {
      for (final scene in _fullFrames.keys.toList(growable: false)) {
        _evictFull(scene);
      }
      for (final scene in _previewFrames.keys.toList(growable: false)) {
        _evictPreview(scene);
      }
      _clearFailures();
      _clearFinalizationTimers();
      _activeRenders.removeWhere((_, render) => render.awaitingFinal);
      for (final requestId in _pendingQualityFrames.keys.toList()) {
        _discardQualityFrames(requestId);
      }
      _qualityAttempts.clear();
      _clearEarlyFinalNotifications();
      _partialScenes.clear();
      _finalizationTimedOutScenes.clear();
      notifyListeners();
    }
    _schedule();
  }

  MapFrame? frameFor(JobMapScene scene) {
    final basemap = scene.basemap;
    final full = _fullFrames.remove(basemap);
    if (full != null) _fullFrames[basemap] = full;
    final preview = _previewFrames.remove(basemap);
    if (preview != null) _previewFrames[basemap] = preview;
    return full ?? preview;
  }

  bool isSceneVisible(JobMapScene scene) =>
      _activeRoute?.demands.any((demand) => demand.scene == scene.basemap && demand.visibleFraction > 0) ?? false;

  void retainFrame(MapFrame frame) {
    if (_isDisposed) return;
    _frameHolds.update(frame.textureId, (count) => count + 1, ifAbsent: () => 1);
  }

  void releaseFrame(MapFrame frame) {
    if (_isDisposed) return;
    final count = _frameHolds[frame.textureId];
    if (count == null) return;
    if (count > 1) {
      _frameHolds[frame.textureId] = count - 1;
      return;
    }
    _frameHolds.remove(frame.textureId);
    final retired = _retiredFrames.remove(frame.textureId);
    if (retired != null) _release(retired);
  }

  Future<bool> waitForPreparedScenes({required int count, required Duration timeout}) {
    assert(count > 0, 'count must be positive');
    final ready = Completer<bool>();

    void checkReady() {
      if (ready.isCompleted) return;
      final scenes = _plannedScenes().take(count);
      if (scenes.isEmpty) return;
      if (scenes.every((scene) => _fullFrames.containsKey(scene) || _previewFrames.containsKey(scene))) {
        ready.complete(true);
      }
    }

    addListener(checkReady);
    final timeoutTimer = Timer(timeout, () => ready.complete(false));
    checkReady();
    return ready.future.whenComplete(() {
      timeoutTimer.cancel();
      removeListener(checkReady);
    });
  }

  void trimMemory() {
    final pinned = _visibleScenes();
    var changed = false;
    for (final scene in _fullFrames.keys.toList(growable: false)) {
      if (pinned.contains(scene)) continue;
      changed = _evictFull(scene) || changed;
    }
    for (final scene in _previewFrames.keys.toList(growable: false)) {
      if (pinned.contains(scene)) continue;
      changed = _evictPreview(scene) || changed;
    }
    if (changed) notifyListeners();
  }

  void invalidateFrames() {
    _activeRenders.clear();
    for (final requestId in _pendingQualityFrames.keys.toList()) {
      _discardQualityFrames(requestId);
    }
    _qualityAttempts.clear();
    _clearFinalizationTimers();
    _clearEarlyFinalNotifications();
    _partialScenes.clear();
    _finalizationTimedOutScenes.clear();
    _clearFailures();
    for (final scene in _fullFrames.keys.toList(growable: false)) {
      _evictFull(scene);
    }
    for (final scene in _previewFrames.keys.toList(growable: false)) {
      _evictPreview(scene);
    }
    notifyListeners();
    _schedule();
  }

  Duration get _elapsedTime => _readElapsedTime?.call() ?? _viewportClock.elapsed;

  void _clearFailures() {
    _failedScenes.clear();
    _failureCounts.clear();
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
  }

  void _syncNativeScrollActivity() {
    MapRouteLease? activeLease;
    var activeActivation = -1;
    for (final entry in _routes.entries) {
      if (!entry.value.visible || entry.value.activation <= activeActivation) continue;
      activeLease = entry.key;
      activeActivation = entry.value.activation;
    }
    final scrolling = activeLease != null && _scrollingRoutes.contains(activeLease);
    final motion = activeLease == null ? null : _routes[activeLease]!.motion;
    final scrollActive =
        scrolling && (!activeLease.allowSlowScrollCapture || motion!.shouldDeferFullCapture(at: _elapsedTime));
    final allowReadyPreview =
        scrolling &&
        scrollActive &&
        activeLease.skipIntermediateMapsOnRapidScroll &&
        !motion!.shouldDeferFullCapture(at: _elapsedTime);
    _scrollMotionIdleTimer?.cancel();
    _scrollMotionIdleTimer = null;
    if (scrollActive && activeLease.allowSlowScrollCapture && motion!.lastUpdateAt != null) {
      _scrollMotionIdleTimer = Timer(MapViewportMotion.stationaryWindow, () {
        _scrollMotionIdleTimer = null;
        _syncNativeScrollActivity();
        _schedule();
      });
    }
    renderBudget?.setActive(activeLease != null && _routes[activeLease]!.demands.isNotEmpty);
    if (_nativeScrollActive == scrollActive && _nativeReadyPreviewAllowed == allowReadyPreview) return;
    _nativeScrollActive = scrollActive;
    _nativeReadyPreviewAllowed = allowReadyPreview;
    unawaited(
      engine
          .setScrollActive(scrollActive, allowReadyPreview: allowReadyPreview)
          .catchError((Object _, StackTrace __) {}),
    );
  }

  void _clearFinalizationTimers() {
    for (final timer in _finalizationTimers.values) {
      timer.cancel();
    }
    _finalizationTimers.clear();
  }

  void _onRenderBudgetChanged() {
    for (final entry in _activeRenders.entries.toList()) {
      final active = entry.value;
      if (!active.qualityRefinement) continue;
      final target = active.scene.withRenderQuality(renderBudget!.quality);
      if (active.renderScene.nativeScale <= target.nativeScale &&
          active.renderScene.widthPx <= target.widthPx &&
          active.renderScene.heightPx <= target.heightPx &&
          _cachedBytes + active.renderScene.estimatedCachedBytes <= maxCachedBytes) {
        continue;
      }
      _activeRenders.remove(entry.key);
      _finalizationTimers.remove(entry.key)?.cancel();
      _discardEarlyFinalNotification(active.requestId);
      _qualityAttempts.remove(active.scene);
      _discardQualityFrames(active.requestId);
    }
    if (_trimToBudget()) notifyListeners();
    _schedule();
  }

  void _discardEarlyFinalNotification(int requestId) {
    final event = _earlyFinalNotifications.remove(requestId);
    if (event == null) return;
    _release(event.full);
    _release(event.preview);
  }

  void _clearEarlyFinalNotifications() {
    for (final requestId in _earlyFinalNotifications.keys.toList()) {
      _discardEarlyFinalNotification(requestId);
    }
  }

  void _onFrameFinal(MapFrameFinalEvent event) {
    final active = _activeRenders[event.rendererSlot];
    if (active == null || active.requestId != event.requestId) {
      _release(event.full);
      _release(event.preview);
      return;
    }
    if (!active.awaitingFinal) {
      _earlyFinalNotifications[event.requestId] = event;
      return;
    }
    _finalizationTimers.remove(event.rendererSlot)?.cancel();
    _activeRenders.remove(event.rendererSlot);
    _discardQualityFrames(event.requestId);
    _partialScenes.remove(active.scene);
    _finalizationTimedOutScenes.remove(active.scene);
    _publishFrames(active.scene, (full: event.full, preview: event.preview));
    _schedule();
  }

  void _onFrameProgress(MapFrameFinalEvent event) {
    final active = _activeRenders[event.rendererSlot];
    if (active == null || active.requestId != event.requestId || !active.awaitingFinal || active.qualityRefinement) {
      _release(event.full);
      _release(event.preview);
      return;
    }
    _publishFrames(active.scene, (full: event.full, preview: event.preview));
  }

  ({
    bool visible,
    List<MapSceneDemand> demands,
    int direction,
    int activation,
    MapViewportMotion motion,
    bool predictDistantMaps,
    bool skipIntermediateMapsOnRapidScroll,
  })?
  get _activeRoute {
    ({
      bool visible,
      List<MapSceneDemand> demands,
      int direction,
      int activation,
      MapViewportMotion motion,
      bool predictDistantMaps,
      bool skipIntermediateMapsOnRapidScroll,
    })?
    route;
    for (final candidate in _routes.values) {
      if (!candidate.visible) continue;
      if (route == null || candidate.activation > route.activation) route = candidate;
    }
    return route;
  }

  bool get _activeRouteScrolling {
    final route = _activeRoute;
    if (route == null) return false;
    return _scrollingRoutes.any((lease) => _routes[lease]?.activation == route.activation);
  }

  void _cancelQualityRefinements({Set<JobMapScene>? scenes}) {
    for (final entry in _activeRenders.entries.toList()) {
      final active = entry.value;
      if (!active.qualityRefinement || (scenes != null && !scenes.contains(active.scene))) continue;
      _activeRenders.remove(entry.key);
      _finalizationTimers.remove(entry.key)?.cancel();
      _discardEarlyFinalNotification(active.requestId);
      _discardQualityFrames(active.requestId);
      _qualityAttempts.remove(active.scene);
    }
  }

  List<MapSceneDemand> _rankedDemands() {
    final route = _activeRoute;
    if (route == null) return const [];

    final ranked = List<MapSceneDemand>.of(route.demands);
    MapSceneDemand? predictedDemand;
    final predictedDistance = route.motion.distanceAfter(_firstFrameLatency ?? const Duration(milliseconds: 400));
    if (route.predictDistantMaps && _nativeScrollActive && predictedDistance.abs() >= 2) {
      for (final demand in ranked) {
        if (demand.distanceFromCurrent.sign != route.direction) continue;
        if (predictedDemand == null ||
            (demand.distanceFromCurrent - predictedDistance).abs() <
                (predictedDemand.distanceFromCurrent - predictedDistance).abs()) {
          predictedDemand = demand;
        }
      }
    }
    if (route.motion.isFastTransitAt(at: _elapsedTime) && route.skipIntermediateMapsOnRapidScroll) {
      final arrivalDemands = ranked.where((demand) => demand.distanceFromArrival != null).toList();
      if (defaultTargetPlatform == .iOS &&
          (arrivalDemands.any((demand) => demand.distanceFromCurrent.abs() >= 2) ||
              (predictedDemand != null && predictedDistance.abs() >= 3))) {
        ranked.removeWhere(
          (demand) =>
              demand.visibleFraction > 0 &&
              demand.distanceFromArrival == null &&
              demand != predictedDemand &&
              !_fullFrames.containsKey(demand.scene) &&
              !_previewFrames.containsKey(demand.scene),
        );
      }
      if (arrivalDemands.isNotEmpty) {
        ranked.removeWhere((demand) => demand.visibleFraction == 0 && demand.distanceFromArrival == null);
      } else if (predictedDemand != null && predictedDistance.abs() >= 3) {
        final targetDistance = predictedDemand.distanceFromCurrent;
        ranked.removeWhere(
          (demand) => demand.visibleFraction == 0 && (demand.distanceFromCurrent - targetDistance).abs() > 1,
        );
      } else {
        ranked.removeWhere((demand) => demand.visibleFraction == 0 && demand.distanceFromCurrent.abs() > 2);
      }
    }
    return ranked..sort((first, second) {
      final firstArrivalDistance = first.distanceFromArrival;
      final secondArrivalDistance = second.distanceFromArrival;
      if (firstArrivalDistance != null || secondArrivalDistance != null) {
        if (firstArrivalDistance == null) return 1;
        if (secondArrivalDistance == null) return -1;
        final arrivalOrder = firstArrivalDistance.compareTo(secondArrivalDistance);
        if (arrivalOrder != 0) return arrivalOrder;
      }
      final firstPredicted = first == predictedDemand;
      final secondPredicted = second == predictedDemand;
      if (firstPredicted != secondPredicted) return firstPredicted ? -1 : 1;
      final firstVisible = first.visibleFraction > 0;
      final secondVisible = second.visibleFraction > 0;
      if (firstVisible != secondVisible) return firstVisible ? -1 : 1;
      if (firstVisible) {
        final visibilityOrder = second.visibleFraction.compareTo(first.visibleFraction);
        if (visibilityOrder != 0) return visibilityOrder;
      }
      final firstAdjacent = first.distanceFromCurrent.abs() == 1;
      final secondAdjacent = second.distanceFromCurrent.abs() == 1;
      if (firstAdjacent != secondAdjacent) return firstAdjacent ? -1 : 1;
      final firstAhead = route.direction != 0 && first.distanceFromCurrent.sign == route.direction;
      final secondAhead = route.direction != 0 && second.distanceFromCurrent.sign == route.direction;
      if (firstAhead != secondAhead) return firstAhead ? -1 : 1;
      return first.distanceFromCurrent.abs().compareTo(second.distanceFromCurrent.abs());
    });
  }

  List<JobMapScene> _plannedScenes() {
    final scenes = <JobMapScene>[];
    final seen = <JobMapScene>{};
    var plannedBytes = 0;
    var offscreenWork = 0;
    final prefetchLimit = renderBudget?.maxOffscreenPrefetchScenes;
    for (final demand in _rankedDemands()) {
      if (seen.contains(demand.scene)) continue;
      final cached = (_fullFrames[demand.scene]?.byteCount ?? 0) + (_previewFrames[demand.scene]?.byteCount ?? 0);
      final active = _activeRenders.values.where((render) => render.scene == demand.scene).firstOrNull;
      final reserved = active?.renderScene ?? _coldRenderScene(demand.scene);
      var frameBytes = cached > 0 ? cached : reserved.estimatedCachedBytes;
      final offscreen = demand.visibleFraction == 0 && demand.distanceFromArrival != 0;
      if (offscreen && active == null && plannedBytes + frameBytes > maxCachedBytes) {
        final retainedBytes = cached > 0 ? cached : reserved.estimatedPreviewBytes;
        final previewBudget = math.max(maxCachedBytes, _pinnedFrameBytes + retainedBytes);
        if (renderBudget?.quality != .compact || plannedBytes + retainedBytes > previewBudget) continue;
        // Keep one small upcoming image even when a previously sharp visible
        // map alone exceeds the soft pressure budget. Release the temporary full.
        frameBytes = retainedBytes;
      }
      if (offscreen && cached == 0) {
        if (active == null && prefetchLimit != null && offscreenWork >= prefetchLimit) continue;
        offscreenWork++;
      }
      seen.add(demand.scene);
      scenes.add(demand.scene);
      plannedBytes += frameBytes;
    }
    return scenes;
  }

  int get _pinnedFrameBytes => _visibleScenes().fold(
    0,
    (bytes, scene) => bytes + ((_fullFrames[scene] ?? _previewFrames[scene])?.byteCount ?? 0),
  );

  JobMapScene _coldRenderScene(JobMapScene scene) => switch (renderBudget?.quality) {
    .compact => scene.withRenderQuality(.compact),
    .balanced || .sharp || null => scene,
  };

  Set<JobMapScene> _visibleScenes() => {
    for (final demand in _activeRoute?.demands ?? const <MapSceneDemand>[])
      if (demand.visibleFraction > 0) demand.scene,
  };

  void _schedule() {
    if (_scheduled || _isDisposed) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (!_isDisposed) _drain();
    });
  }

  void _drain() {
    final visible = _visibleScenes();
    if (_activeRouteScrolling) _cancelQualityRefinements();
    final planned = _plannedScenes();
    final plannedSet = planned.toSet();
    _failedScenes.removeWhere((scene) => !plannedSet.contains(scene));
    // An early image is not a prepared neighbor until Google finishes its labels.
    final adjacent = {
      for (final demand in _activeRoute?.demands ?? const <MapSceneDemand>[])
        if (demand.distanceFromCurrent.abs() == 1) demand.scene,
    };
    _finalizationTimedOutScenes.removeWhere((scene) => !visible.contains(scene) && !adjacent.contains(scene));
    final work = <JobMapScene>[];
    final refinements = <JobMapScene>[];
    var hasColdWork = false;
    for (final scene in planned) {
      if (_failedScenes.contains(scene)) continue;
      final hasFull = _fullFrames.containsKey(scene);
      final hasPreview = _previewFrames.containsKey(scene);
      final needsFrame = !hasFull && (!hasPreview || (visible.contains(scene) && !_nativeScrollActive));
      final needsNearbyFinal =
          (visible.contains(scene) || adjacent.contains(scene)) &&
          !_nativeScrollActive &&
          _partialScenes.contains(scene) &&
          !_finalizationTimedOutScenes.contains(scene);
      if (!needsFrame && !needsNearbyFinal) continue;
      if (!hasFull && !hasPreview) {
        hasColdWork = true;
        work.add(scene);
      } else if (needsNearbyFinal ||
          _activeRenders.values.any((active) => active.scene == scene && active.awaitingFinal)) {
        work.add(scene);
      } else {
        refinements.add(scene);
      }
    }
    work.addAll(refinements);
    JobMapScene? qualityScene;
    JobMapScene? qualityRenderScene;
    final quality = renderBudget?.quality;
    if (work.isEmpty &&
        _activeRenders.isEmpty &&
        !_nativeScrollActive &&
        !_activeRouteScrolling &&
        quality != null &&
        quality != .compact) {
      for (final scene in planned) {
        final frame = _fullFrames[scene];
        if (frame == null || _partialScenes.contains(scene)) continue;
        final target = scene.withRenderQuality(quality);
        if (target.nativeScale <= frame.scene.nativeScale &&
            target.widthPx <= frame.scene.widthPx &&
            target.heightPx <= frame.scene.heightPx) {
          continue;
        }
        if (_qualityAttempts[scene] == target) continue;
        // The old image stays visible until the new capture is complete.
        if (_cachedBytes + target.estimatedCachedBytes > maxCachedBytes) continue;
        qualityScene = scene;
        qualityRenderScene = target;
        work.add(scene);
        break;
      }
    }
    final concurrentRenders = renderBudget?.concurrentRenders ?? engine.rendererSlotCount;
    if (engine.rendererSlotCount > 1 && work.length > 1) {
      final visibleWork = work
          .skip(1)
          .where((scene) => visible.contains(scene) && (!hasColdWork || !refinements.contains(scene)));
      if (!visible.contains(work.first) && visibleWork.isNotEmpty) {
        final scene = visibleWork.first;
        work
          ..remove(scene)
          ..insert(concurrentRenders > 1 ? 1 : 0, scene);
      }
    }
    final wanted = work.take(concurrentRenders).toList();
    final route = _activeRoute;
    if (route == null) return;
    final rapidRetargetAllowed =
        route.skipIntermediateMapsOnRapidScroll &&
        route.motion.isFastTransitAt(at: _elapsedTime) &&
        concurrentRenders > 1 &&
        (_lastRapidRetargetActivation != route.activation ||
            _lastRapidRetargetAt == null ||
            _elapsedTime - _lastRapidRetargetAt! >= (_firstFrameLatency ?? const Duration(milliseconds: 400)));
    final arrivals = {
      for (final demand in route.demands)
        if (demand.distanceFromArrival == 0) demand.scene,
    };
    for (final scene in wanted) {
      if (_activeRenders.values.any((active) => active.scene == scene)) continue;
      final qualityRefinement = scene == qualityScene;
      final renderScene = qualityRefinement ? qualityRenderScene! : _coldRenderScene(scene);
      final visibleColdRequest =
          visible.contains(scene) && !_fullFrames.containsKey(scene) && !_previewFrames.containsKey(scene);

      int? slot;
      for (var index = 0; _activeRenders.length < concurrentRenders && index < engine.rendererSlotCount; index++) {
        if (_activeRenders.containsKey(index)) continue;
        slot ??= index;
        final previousScene = _rendererScenes[index];
        if (previousScene == null || !renderScene.sharesBasemapWith(previousScene)) continue;
        slot = index;
        break;
      }
      var rapidRetargetSelected = false;
      if (slot == null) {
        for (var index = 0; index < engine.rendererSlotCount; index++) {
          final active = _activeRenders[index];
          if (active != null && !wanted.contains(active.scene)) {
            if (active.awaitingFinal &&
                _activeRenders.values.where((render) => !render.awaitingFinal).length >= concurrentRenders) {
              continue;
            }
            final retainedColdRequest =
                plannedSet.contains(active.scene) &&
                !_fullFrames.containsKey(active.scene) &&
                !_previewFrames.containsKey(active.scene);
            final replacePartialRefinement =
                _partialScenes.contains(active.scene) &&
                (!visible.contains(active.scene) || visibleColdRequest || arrivals.contains(scene));
            final rapidRetarget =
                rapidRetargetAllowed &&
                scene == work.first &&
                !arrivals.contains(scene) &&
                !visible.contains(scene) &&
                !plannedSet.contains(active.scene) &&
                !active.awaitingFinal &&
                !active.qualityRefinement;
            // Finish in-flight cold work before improving a cached map. A
            // settled partial takes the next free slot ahead of new prefetches.
            if ((_nativeScrollActive || arrivals.isNotEmpty || (!visibleColdRequest && retainedColdRequest)) &&
                !active.awaitingFinal &&
                !active.qualityRefinement &&
                !replacePartialRefinement &&
                active.routeActivation == route.activation &&
                active.direction == route.direction &&
                !arrivals.contains(scene) &&
                !rapidRetarget) {
              continue;
            }
            slot = index;
            rapidRetargetSelected = rapidRetarget;
            break;
          }
        }
      }
      if (slot == null) break;
      final previous = _activeRenders[slot];
      if (previous != null) {
        if (rapidRetargetSelected) {
          _lastRapidRetargetAt = _elapsedTime;
          _lastRapidRetargetActivation = route.activation;
        }
        _finalizationTimers.remove(slot)?.cancel();
        _discardEarlyFinalNotification(previous.requestId);
        _discardQualityFrames(previous.requestId);
        if (previous.qualityRefinement) _qualityAttempts.remove(previous.scene);
      }
      final requestId = ++_nextRequestId;
      if (qualityRefinement) _qualityAttempts[scene] = renderScene;
      _rendererScenes[slot] = renderScene;
      _activeRenders[slot] = (
        requestId: requestId,
        scene: scene,
        renderScene: renderScene,
        qualityRefinement: qualityRefinement,
        awaitingFinal: false,
        routeActivation: route.activation,
        direction: route.direction,
      );
      final operation = _render(scene, renderScene: renderScene, requestId: requestId, rendererSlot: slot);
      _pendingRenders.add(operation);
      unawaited(operation.whenComplete(() => _pendingRenders.remove(operation)));
    }
    if (_trimToBudget()) notifyListeners();
  }

  Future<void> _render(
    JobMapScene scene, {
    required JobMapScene renderScene,
    required int requestId,
    required int rendererSlot,
  }) async {
    final firstFrameStartedAt = _elapsedTime;
    try {
      var frames = await engine.render(renderScene, requestId: requestId, rendererSlot: rendererSlot);
      final firstFrameElapsed = _elapsedTime - firstFrameStartedAt;
      final active = _activeRenders[rendererSlot];
      final stillRequested =
          _plannedScenes().contains(scene) ||
          (_nativeScrollActive && active?.routeActivation == _activeRoute?.activation);
      if (_isDisposed || active?.requestId != requestId || !stillRequested) {
        if (active?.requestId == requestId) {
          _activeRenders.remove(rendererSlot);
          _schedule();
        }
        _discardEarlyFinalNotification(requestId);
        _release(frames.full);
        _release(frames.preview);
        return;
      }

      // SDK initialization is a one-time cost, not the time required for the next card.
      if (!_completedRendererSlots.add(rendererSlot) && !active!.qualityRefinement) {
        final previousLatency = _firstFrameLatency;
        _firstFrameLatency = previousLatency == null
            ? firstFrameElapsed
            : Duration(
                microseconds: (previousLatency.inMicroseconds * .75 + firstFrameElapsed.inMicroseconds * .25).round(),
              );
      }
      final earlyFinal = _earlyFinalNotifications.remove(requestId);
      if (earlyFinal != null) {
        _release(frames.full);
        _release(frames.preview);
        frames = (full: earlyFinal.full, preview: earlyFinal.preview, isFinal: true);
      }
      final isFinal = frames.isFinal;
      if (isFinal) {
        _activeRenders.remove(rendererSlot);
        _partialScenes.remove(scene);
        _finalizationTimedOutScenes.remove(scene);
      } else {
        _activeRenders[rendererSlot] = (
          requestId: requestId,
          scene: scene,
          renderScene: renderScene,
          qualityRefinement: active!.qualityRefinement,
          awaitingFinal: true,
          routeActivation: active.routeActivation,
          direction: active.direction,
        );
        if (!active.qualityRefinement) _partialScenes.add(scene);
        _finalizationTimedOutScenes.remove(scene);
        _finalizationTimers[rendererSlot] = Timer(const Duration(seconds: 8), () {
          if (_activeRenders[rendererSlot]?.requestId != requestId) return;
          _activeRenders.remove(rendererSlot);
          _finalizationTimers.remove(rendererSlot);
          if (active.qualityRefinement) {
            _discardQualityFrames(requestId);
          } else {
            _finalizationTimedOutScenes.add(scene);
          }
          _schedule();
        });
      }
      if (active!.qualityRefinement && !isFinal) {
        _pendingQualityFrames[requestId] = (full: frames.full, preview: frames.preview);
      } else {
        _publishFrames(scene, (full: frames.full, preview: frames.preview));
      }
      _schedule();
    } on Object {
      _discardEarlyFinalNotification(requestId);
      if (_activeRenders[rendererSlot]?.requestId != requestId) return;
      final failed = _activeRenders.remove(rendererSlot);
      if (failed?.qualityRefinement ?? false) {
        _discardQualityFrames(requestId);
        _schedule();
        return;
      }
      if (!_isDisposed) {
        _failedScenes.add(scene);
        final failureCount = (_failureCounts[scene] ?? 0) + 1;
        _failureCounts[scene] = failureCount;
        if (failureCount <= 2 || _visibleScenes().contains(scene)) {
          _retryTimers[scene]?.cancel();
          _retryTimers[scene] = Timer(retryDelay * (failureCount < 4 ? failureCount : 4), () {
            _retryTimers.remove(scene);
            if (failureCount > 2 && !_visibleScenes().contains(scene)) return;
            _failedScenes.remove(scene);
            if (_plannedScenes().contains(scene)) _schedule();
          });
        }
        _schedule();
      }
    }
  }

  void _discardQualityFrames(int requestId) {
    final frames = _pendingQualityFrames.remove(requestId);
    if (frames == null) return;
    _release(frames.full);
    _release(frames.preview);
  }

  void _publishFrames(JobMapScene scene, ({MapFrame full, MapFrame preview}) frames) {
    final previousFull = _fullFrames.remove(scene);
    if (previousFull != null) _cachedBytes -= previousFull.byteCount;
    _fullFrames[scene] = frames.full;
    _cachedBytes += frames.full.byteCount;
    final previousPreview = _previewFrames.remove(scene);
    if (previousPreview != null) {
      _cachedBytes -= previousPreview.byteCount;
    }
    _previewFrames[scene] = frames.preview;
    _cachedBytes += frames.preview.byteCount;
    _failureCounts.remove(scene);
    _trimToBudget(protectedFullScene: renderBudget?.quality == .compact ? null : scene);
    notifyListeners();
    if (previousFull != null || previousPreview != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        if (previousFull != null) _release(previousFull);
        if (previousPreview != null) _release(previousPreview);
      });
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  bool _trimToBudget({JobMapScene? protectedFullScene}) {
    final pinned = _visibleScenes();
    var changed = false;
    if (renderBudget?.quality == .compact) {
      for (final scene in pinned) {
        if (_cachedBytes <= maxCachedBytes) break;
        if (!_fullFrames.containsKey(scene)) continue;
        changed = _evictPreview(scene) || changed;
      }
    }
    var retainedBudget = maxCachedBytes;
    JobMapScene? protectedPreviewScene;
    if (renderBudget?.quality == .compact) {
      protectedPreviewScene = _rankedDemands()
          .map((demand) => demand.scene)
          .where((scene) => !pinned.contains(scene) && _previewFrames.containsKey(scene))
          .firstOrNull;
      if (protectedPreviewScene != null) {
        retainedBudget = math.max(retainedBudget, _pinnedFrameBytes + _previewFrames[protectedPreviewScene]!.byteCount);
      }
    }
    for (final scene in _fullFrames.keys.toList(growable: false)) {
      if (_cachedBytes <= retainedBudget) break;
      if (pinned.contains(scene) || scene == protectedFullScene) continue;
      changed = _evictFull(scene) || changed;
    }
    for (final scene in _previewFrames.keys.toList(growable: false)) {
      if (_cachedBytes <= retainedBudget) break;
      if (pinned.contains(scene) || scene == protectedPreviewScene) continue;
      changed = _evictPreview(scene) || changed;
    }
    return changed;
  }

  bool _evictFull(JobMapScene scene) {
    final frame = _fullFrames.remove(scene);
    if (frame == null) return false;
    _cachedBytes -= frame.byteCount;
    _release(frame);
    if (!_previewFrames.containsKey(scene)) {
      _partialScenes.remove(scene);
      _finalizationTimedOutScenes.remove(scene);
      _qualityAttempts.remove(scene);
    }
    return true;
  }

  bool _evictPreview(JobMapScene scene) {
    final frame = _previewFrames.remove(scene);
    if (frame == null) return false;
    _cachedBytes -= frame.byteCount;
    _release(frame);
    if (!_fullFrames.containsKey(scene)) {
      _partialScenes.remove(scene);
      _finalizationTimedOutScenes.remove(scene);
      _qualityAttempts.remove(scene);
    }
    return true;
  }

  void _release(MapFrame frame) {
    if (_frameHolds.containsKey(frame.textureId)) {
      _retiredFrames[frame.textureId] = frame;
      return;
    }
    final operation = engine.release(frame).catchError((Object _, StackTrace __) {});
    _pendingReleases.add(operation);
    unawaited(operation.whenComplete(() => _pendingReleases.remove(operation)));
  }

  Future<void> _disposeEngineAfterPendingWork() async {
    await Future.wait(_pendingReleases.toList(growable: false));
    await engine.dispose();
    await Future.wait(_pendingRenders.toList(growable: false));
    await Future.wait(_pendingReleases.toList(growable: false));
  }

  @override
  void didHaveMemoryPressure() {
    if (renderBudget == null) {
      trimMemory();
      return;
    }
    if (_trimToBudget()) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .paused || state == .hidden) {
      _wasBackgrounded = true;
      return;
    }
    if (state != .resumed || !_wasBackgrounded) return;
    _wasBackgrounded = false;
    if (defaultTargetPlatform == .android &&
        (_fullFrames.isNotEmpty || _previewFrames.isNotEmpty || _activeRenders.isNotEmpty)) {
      invalidateFrames();
    }
  }

  @override
  void dispose() {
    _scrollMotionIdleTimer?.cancel();
    if (_isDisposed) return;
    _isDisposed = true;
    _frameHolds.clear();
    for (final frame in _retiredFrames.values) {
      _release(frame);
    }
    _retiredFrames.clear();
    WidgetsBinding.instance.removeObserver(this);
    engine
      ..setFrameFinalListener(null)
      ..setRendererResetListener(null);
    renderBudget?.removeListener(_onRenderBudgetChanged);
    renderBudget?.setActive(false);
    _clearFailures();
    _clearFinalizationTimers();
    _clearEarlyFinalNotifications();
    _partialScenes.clear();
    _finalizationTimedOutScenes.clear();
    for (final frame in _fullFrames.values) {
      _release(frame);
    }
    for (final frame in _previewFrames.values) {
      _release(frame);
    }
    for (final requestId in _pendingQualityFrames.keys.toList()) {
      _discardQualityFrames(requestId);
    }
    _qualityAttempts.clear();
    _fullFrames.clear();
    _previewFrames.clear();
    _cachedBytes = 0;
    _routes.clear();
    _rendererScenes.clear();
    _scrollingRoutes.clear();
    unawaited(_disposeEngineAfterPendingWork().catchError((Object _, StackTrace __) {}));
    super.dispose();
  }
}
