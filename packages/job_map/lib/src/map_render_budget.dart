import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:job_map/src/enums/map_render_quality.dart';
import 'package:job_map/src/map_render_capabilities.dart';

final class MapRenderBudget extends ChangeNotifier with WidgetsBindingObserver {
  MapRenderBudget({required this.rendererSlotCount, required this.maxCachedBytes, required this.readCapabilities})
    : _concurrentRenders = rendererSlotCount,
      _rendererCeiling = rendererSlotCount,
      _cacheBytes = math.min(maxCachedBytes, 24 * 1024 * 1024) {
    WidgetsBinding.instance.addObserver(this);
  }

  final int rendererSlotCount;
  final int maxCachedBytes;
  final Future<MapRenderCapabilities> Function() readCapabilities;

  static const defaultMaxCachedBytes = 48 * 1024 * 1024;
  static const _sampleWindow = Duration(milliseconds: 150);

  int _concurrentRenders;
  int _rendererCeiling;
  int _cacheBytes;
  MapRenderQuality _quality = .balanced;
  int _sampleCount = 0;
  int _lateFrames = 0;
  int _headroomFrames = 0;
  int _lateWindows = 0;
  int _recurringLateWindows = 0;
  int _recurringExcessMicros = 0;
  int _recoveryFrames = 0;
  int _recoveryLateFrames = 0;
  int _headroomRecoveryFrames = 0;
  int _headroomLateFrames = 0;
  int _normalMemoryReads = 0;
  int _higherCacheReads = 0;
  int? _pendingHigherCacheBytes;
  int? _lastFrameEndMicros;
  Duration _sampleDuration = Duration.zero;
  Duration _consecutiveLateWork = Duration.zero;
  Duration _recurringDuration = Duration.zero;
  Duration _healthyDuration = Duration.zero;
  Duration _headroomDuration = Duration.zero;
  Timer? _capabilityTimer;
  Timer? _quietPromotionTimer;
  bool _active = false;
  bool _foreground = true;
  bool _disposed = false;
  bool _readingCapabilities = false;
  bool _monitoringFrames = false;
  bool _underMemoryPressure = false;
  bool _compactConstrained = false;
  bool _memoryConstrained = false;
  bool _earlySharpEligible = false;

  int get concurrentRenders => _concurrentRenders;
  int get cacheBytes => _cacheBytes;
  MapRenderQuality get quality => _quality;
  int get maxOffscreenPrefetchScenes {
    if (_quality == .compact || _concurrentRenders < rendererSlotCount || _memoryConstrained) return 2;
    if (_quality == .sharp && _earlySharpEligible) return 6;
    return 4;
  }

  void setActive(bool active) {
    if (_active == active || _disposed) return;
    _active = active;
    _syncMonitoring();
  }

  void applyCapabilities(MapRenderCapabilities capabilities) {
    if (_disposed) return;
    final previous = (_concurrentRenders, _cacheBytes, _quality, maxOffscreenPrefetchScenes);
    final wasUnderMemoryPressure = _underMemoryPressure;
    final wasCompactConstrained = _compactConstrained;
    final previousRendererCeiling = _rendererCeiling;

    if (capabilities.lowMemory) {
      _underMemoryPressure = true;
      _normalMemoryReads = 0;
    } else if (_underMemoryPressure) {
      _normalMemoryReads++;
      if (_normalMemoryReads >= 2) {
        _underMemoryPressure = false;
        _normalMemoryReads = 0;
      }
    }

    final availableSlots = math.min(rendererSlotCount, capabilities.maxRendererSlots);
    _rendererCeiling = switch (capabilities.thermalState) {
      .nominal || .fair => availableSlots,
      .serious => math.max(1, availableSlots - 1),
      .critical => 1,
    };
    if (_underMemoryPressure) _rendererCeiling = 1;
    _compactConstrained =
        _underMemoryPressure || capabilities.thermalState == .serious || capabilities.thermalState == .critical;
    _memoryConstrained =
        capabilities.lowRamDevice ||
        capabilities.totalMemoryBytes < 3 * 1024 * 1024 * 1024 ||
        capabilities.availableMemoryBytes < 192 * 1024 * 1024;
    _earlySharpEligible =
        !_memoryConstrained &&
        !_compactConstrained &&
        capabilities.thermalState == .nominal &&
        capabilities.totalMemoryBytes >= 4 * 1024 * 1024 * 1024 &&
        capabilities.availableMemoryBytes >= 512 * 1024 * 1024;
    _concurrentRenders = math.min(_concurrentRenders, _rendererCeiling);
    if (_compactConstrained) _quality = .compact;
    _scheduleQuietPromotion();
    if (wasCompactConstrained != _compactConstrained || previousRendererCeiling != _rendererCeiling) {
      _resetFrameSamples();
    }

    final proportionalCacheBytes = capabilities.availableMemoryBytes ~/ 8;
    final cacheBandBytes = proportionalCacheBytes ~/ (8 * 1024 * 1024) * (8 * 1024 * 1024);
    final memoryCacheBytes = math.min(
      maxCachedBytes,
      math.max(8 * 1024 * 1024, math.min(48 * 1024 * 1024, cacheBandBytes)),
    );
    final desiredCacheBytes = _underMemoryPressure
        ? math.min(maxCachedBytes, 4 * 1024 * 1024)
        : capabilities.lowRamDevice
        ? math.min(memoryCacheBytes, 16 * 1024 * 1024)
        : memoryCacheBytes;
    if (desiredCacheBytes <= _cacheBytes || (wasUnderMemoryPressure && !_underMemoryPressure)) {
      _cacheBytes = desiredCacheBytes;
      _pendingHigherCacheBytes = null;
      _higherCacheReads = 0;
    } else {
      if (_pendingHigherCacheBytes == null || desiredCacheBytes < _pendingHigherCacheBytes!) {
        _pendingHigherCacheBytes = desiredCacheBytes;
        _higherCacheReads = 0;
      }
      _higherCacheReads++;
      if (_higherCacheReads >= 2) {
        _cacheBytes = desiredCacheBytes;
        _pendingHigherCacheBytes = null;
        _higherCacheReads = 0;
      }
    }
    if (previous != (_concurrentRenders, _cacheBytes, _quality, maxOffscreenPrefetchScenes)) notifyListeners();
  }

  void recordFrameWork({
    required Duration work,
    required Duration frameBudget,
    int? frameVsyncStartMicros,
    Duration? frameTotalSpan,
  }) {
    if (!_active || !_foreground || _disposed) return;
    assert(frameBudget > Duration.zero, 'frameBudget must be positive');
    if (frameVsyncStartMicros != null) {
      // Include time queued for raster: overlapping pipeline work is not idle.
      final previousEnd = _lastFrameEndMicros;
      if (previousEnd != null && frameVsyncStartMicros - previousEnd > _sampleWindow.inMicroseconds) {
        _consecutiveLateWork = Duration.zero;
      }
      _lastFrameEndMicros = frameVsyncStartMicros + (frameTotalSpan ?? work).inMicroseconds;
    }
    _sampleCount++;
    _sampleDuration += frameBudget;
    if (work > frameBudget) {
      _quietPromotionTimer?.cancel();
      _quietPromotionTimer = null;
      _lateFrames++;
      _recurringExcessMicros += work.inMicroseconds - frameBudget.inMicroseconds;
      // One long frame can contribute at most half the sustained-stall threshold.
      _consecutiveLateWork += Duration(microseconds: math.min(work.inMicroseconds, _sampleWindow.inMicroseconds));
      if (_consecutiveLateWork >= _sampleWindow * 2) {
        final previous = (_concurrentRenders, _quality);
        _stepDown();
        _resetFrameSamples();
        if (previous != (_concurrentRenders, _quality)) notifyListeners();
        return;
      }
    } else {
      _consecutiveLateWork = Duration.zero;
    }
    _scheduleQuietPromotion();
    if (work.inMicroseconds * 4 <= frameBudget.inMicroseconds * 3) _headroomFrames++;
    if (_sampleDuration < _sampleWindow) return;

    final previous = (_concurrentRenders, _quality);
    final lateWindow = _lateFrames >= 2 && _lateFrames / _sampleCount >= .25;
    _recurringDuration += _sampleDuration;
    if (_lateFrames > 0) _recurringLateWindows++;
    var steppedDown = false;
    if (lateWindow) {
      _lateWindows++;
      _resetRecoveryProgress();
      if (_lateWindows >= 2) {
        _lateWindows = 0;
        _stepDown();
        _resetRecurringTrend();
        steppedDown = true;
      }
    } else {
      _lateWindows = 0;
      _healthyDuration += _sampleDuration;
      _recoveryFrames += _sampleCount;
      _recoveryLateFrames += _lateFrames;
      if (_healthyDuration >= const Duration(seconds: 1) && _recoveryLateFrames * 20 > _recoveryFrames) {
        _resetRecoveryProgress();
      }
      if (_headroomFrames * 4 >= _sampleCount * 3) {
        _headroomDuration += _sampleDuration;
        _headroomRecoveryFrames += _sampleCount;
        _headroomLateFrames += _lateFrames;
        if (_headroomDuration >= const Duration(seconds: 1) && _headroomLateFrames * 20 > _headroomRecoveryFrames) {
          _resetHeadroomProgress();
        }
      } else {
        _resetHeadroomProgress();
      }
    }
    if (!steppedDown && _recurringDuration >= const Duration(seconds: 2)) {
      // Repeated isolated long captures can miss several refresh intervals
      // without reporting two late frames in any single 150 ms window.
      final recurringStalls = _hasRecurringStalls;
      _resetRecurringTrend();
      if (recurringStalls) {
        _lateWindows = 0;
        _resetRecoveryProgress();
        _stepDown();
        steppedDown = true;
      }
    }
    if (steppedDown) _consecutiveLateWork = Duration.zero;
    if (!lateWindow && !steppedDown) _recoverFromHealthyFrames();
    _sampleCount = 0;
    _lateFrames = 0;
    _headroomFrames = 0;
    _sampleDuration = Duration.zero;
    if (previous != (_concurrentRenders, _quality)) notifyListeners();
  }

  Future<void> _refreshCapabilities() async {
    if (_readingCapabilities || !_active || !_foreground || _disposed) return;
    _readingCapabilities = true;
    try {
      final capabilities = await readCapabilities();
      if (_active && _foreground && !_disposed) applyCapabilities(capabilities);
    } on Object {
      // Rendering stays available if platform telemetry is temporarily unavailable.
    } finally {
      _readingCapabilities = false;
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    final refreshRate = WidgetsBinding.instance.platformDispatcher.implicitView?.display.refreshRate ?? 60;
    final frameBudget = Duration(microseconds: (Duration.microsecondsPerSecond / math.max(1, refreshRate)).round());
    for (final timing in timings) {
      recordFrameWork(
        work: Duration(
          microseconds: math.max(
            timing.buildDuration.inMicroseconds + timing.vsyncOverhead.inMicroseconds,
            timing.rasterDuration.inMicroseconds,
          ),
        ),
        frameBudget: frameBudget,
        frameVsyncStartMicros: timing.timestampInMicroseconds(.vsyncStart),
        frameTotalSpan: timing.totalSpan,
      );
    }
  }

  bool get _hasRecurringStalls =>
      _recurringLateWindows >= 3 && _recurringExcessMicros * 20 >= _recurringDuration.inMicroseconds;

  void _stepDown() {
    _quietPromotionTimer?.cancel();
    _quietPromotionTimer = null;
    switch (_quality) {
      case .sharp:
        _quality = .balanced;
      case .balanced:
        _quality = .compact;
      case .compact:
        _concurrentRenders = math.max(1, _concurrentRenders - 1);
    }
    _scheduleQuietPromotion();
  }

  void _recoverFromHealthyFrames() {
    if (_compactConstrained || _hasRecurringStalls) return;
    if (_concurrentRenders < _rendererCeiling && _healthyDuration >= const Duration(seconds: 3)) {
      _concurrentRenders++;
      _resetRecoveryProgress();
      return;
    }
    if (_quality == .compact && _healthyDuration >= const Duration(seconds: 3)) {
      _quality = .balanced;
      _resetRecoveryProgress();
      _scheduleQuietPromotion();
      return;
    }
    final sharpRecovery = _earlySharpEligible ? const Duration(seconds: 3) : const Duration(seconds: 10);
    if (_quality == .balanced && _healthyDuration >= sharpRecovery && _headroomDuration >= sharpRecovery) {
      _quality = .sharp;
      _resetRecoveryProgress();
    }
  }

  void _resetHeadroomProgress() {
    _headroomDuration = Duration.zero;
    _headroomRecoveryFrames = 0;
    _headroomLateFrames = 0;
  }

  void _resetRecoveryProgress() {
    _healthyDuration = Duration.zero;
    _recoveryFrames = 0;
    _recoveryLateFrames = 0;
    _resetHeadroomProgress();
  }

  void _resetRecurringTrend() {
    _recurringDuration = Duration.zero;
    _recurringLateWindows = 0;
    _recurringExcessMicros = 0;
  }

  void _resetFrameSamples() {
    _sampleCount = 0;
    _lateFrames = 0;
    _headroomFrames = 0;
    _lateWindows = 0;
    _sampleDuration = Duration.zero;
    _consecutiveLateWork = Duration.zero;
    _lastFrameEndMicros = null;
    _resetRecurringTrend();
    _resetRecoveryProgress();
  }

  void _syncMonitoring() {
    _capabilityTimer?.cancel();
    _capabilityTimer = null;
    if (!_active || !_foreground || _disposed) {
      _quietPromotionTimer?.cancel();
      _quietPromotionTimer = null;
    }
    if (_monitoringFrames) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
      _monitoringFrames = false;
    }
    if (!_active || !_foreground || _disposed) {
      _resetFrameSamples();
      return;
    }
    // Debug instrumentation distorts frame times and must not throttle rendering.
    if (!kDebugMode) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
      _monitoringFrames = true;
    }
    unawaited(_refreshCapabilities());
    _capabilityTimer = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(_refreshCapabilities()));
    _scheduleQuietPromotion();
  }

  void _scheduleQuietPromotion() {
    if (_quietPromotionTimer != null ||
        !_active ||
        !_foreground ||
        _disposed ||
        !_earlySharpEligible ||
        (_quality == .sharp && _concurrentRenders >= _rendererCeiling)) {
      if (!_earlySharpEligible || (_quality == .sharp && _concurrentRenders >= _rendererCeiling)) {
        _quietPromotionTimer?.cancel();
        _quietPromotionTimer = null;
      }
      return;
    }
    _quietPromotionTimer = Timer(const Duration(seconds: 3), () {
      _quietPromotionTimer = null;
      if (!_active || !_foreground || _disposed || !_earlySharpEligible) return;
      if (_concurrentRenders < _rendererCeiling) {
        _concurrentRenders++;
      } else {
        switch (_quality) {
          case .compact:
            _quality = .balanced;
          case .balanced:
            _quality = .sharp;
          case .sharp:
            return;
        }
      }
      _resetRecoveryProgress();
      notifyListeners();
      _scheduleQuietPromotion();
    });
  }

  @override
  void didHaveMemoryPressure() {
    final previous = (_concurrentRenders, _cacheBytes, _quality);
    _underMemoryPressure = true;
    _normalMemoryReads = 0;
    _compactConstrained = true;
    _rendererCeiling = 1;
    _concurrentRenders = 1;
    _quality = .compact;
    _cacheBytes = math.min(maxCachedBytes, 4 * 1024 * 1024);
    _pendingHigherCacheBytes = null;
    _higherCacheReads = 0;
    _resetFrameSamples();
    if (previous != (_concurrentRenders, _cacheBytes, _quality)) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == .resumed;
    _syncMonitoring();
  }

  @override
  void dispose() {
    _disposed = true;
    _syncMonitoring();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
