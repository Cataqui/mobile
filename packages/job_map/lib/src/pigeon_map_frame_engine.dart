import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:job_map/src/enums/map_thermal_state.dart';
import 'package:job_map/src/generated/job_map_api.g.dart';
import 'package:job_map/src/job_map_scene.dart';
import 'package:job_map/src/map_frame.dart';
import 'package:job_map/src/map_frame_engine.dart';
import 'package:job_map/src/map_frame_engine_types.dart';
import 'package:job_map/src/map_render_capabilities.dart';

final class PigeonMapFrameEngine implements MapFrameEngine, JobMapFlutterApi {
  PigeonMapFrameEngine({JobMapHostApi? hostApi, BinaryMessenger? binaryMessenger})
    : _hostApi = hostApi ?? JobMapHostApi(binaryMessenger: binaryMessenger),
      _binaryMessenger = binaryMessenger {
    JobMapFlutterApi.setUp(this, binaryMessenger: binaryMessenger);
  }

  final JobMapHostApi _hostApi;
  final BinaryMessenger? _binaryMessenger;
  final Map<int, ({int requestId, JobMapScene scene})> _activeRequests = {};
  ValueChanged<MapFrameFinalEvent>? _frameFinalListener;
  ValueChanged<MapFrameFinalEvent>? _frameProgressListener;
  VoidCallback? _rendererResetListener;

  Future<void> _releaseTextures(int fullTextureId, int previewTextureId) async {
    await _hostApi.releaseTexture(fullTextureId);
    if (previewTextureId != fullTextureId) await _hostApi.releaseTexture(previewTextureId);
  }

  ({MapFrame full, MapFrame preview, bool isFinal}) _readFrames(NativeMapFrames response, JobMapScene scene) {
    if (response.widthPx != scene.widthPx ||
        response.heightPx != scene.heightPx ||
        response.previewWidthPx <= 0 ||
        response.previewHeightPx <= 0 ||
        response.previewWidthPx > response.widthPx ||
        response.previewHeightPx > response.heightPx ||
        response.previewTextureId == response.textureId) {
      throw const FormatException('Invalid native job map frame');
    }
    return (
      full: MapFrame(
        scene: scene,
        textureId: response.textureId,
        widthPx: response.widthPx,
        heightPx: response.heightPx,
      ),
      preview: MapFrame(
        scene: scene,
        textureId: response.previewTextureId,
        widthPx: response.previewWidthPx,
        heightPx: response.previewHeightPx,
      ),
      isFinal: response.isFinal,
    );
  }

  @override
  int get rendererSlotCount => 2;

  @override
  void setFrameFinalListener(ValueChanged<MapFrameFinalEvent>? listener) => _frameFinalListener = listener;

  @override
  void setFrameProgressListener(ValueChanged<MapFrameFinalEvent>? listener) => _frameProgressListener = listener;

  @override
  void setRendererResetListener(VoidCallback? listener) => _rendererResetListener = listener;

  @override
  Future<void> setScrollActive(bool active, {bool allowReadyPreview = false}) {
    if (defaultTargetPlatform != .iOS) return Future<void>.value();
    return _hostApi.setScrollActive(active, allowReadyPreview);
  }

  Future<MapRenderCapabilities> readRenderCapabilities() async {
    final response = await _hostApi.readRenderCapabilities();
    if (response.availableMemoryBytes < 0 ||
        response.totalMemoryBytes <= 0 ||
        response.processorCount <= 0 ||
        response.thermalState < 0 ||
        response.thermalState >= MapThermalState.values.length ||
        response.maxRendererSlots <= 0) {
      throw const FormatException('Invalid native map rendering capabilities');
    }
    return MapRenderCapabilities(
      lowMemory: response.lowMemory,
      lowRamDevice: response.lowRamDevice,
      availableMemoryBytes: response.availableMemoryBytes,
      totalMemoryBytes: response.totalMemoryBytes,
      processorCount: response.processorCount,
      thermalState: MapThermalState.values[response.thermalState],
      maxRendererSlots: response.maxRendererSlots,
    );
  }

  @override
  Future<({MapFrame full, MapFrame preview, bool isFinal})> render(
    JobMapScene scene, {
    required int requestId,
    required int rendererSlot,
  }) async {
    _activeRequests[rendererSlot] = (requestId: requestId, scene: scene);
    NativeMapFrames? response;
    try {
      response = await _hostApi.render(
        NativeMapRenderRequest(
          requestId: requestId,
          rendererSlot: rendererSlot,
          widthPx: scene.widthPx,
          heightPx: scene.heightPx,
          widthPoints: scene.widthPoints,
          heightPoints: scene.heightPoints,
          nativeScale: scene.nativeScale,
          previewScale: scene.previewScale,
          cameraLatitude: scene.cameraLatitude,
          cameraLongitude: scene.cameraLongitude,
          locationLatitude: scene.locationLatitude,
          locationLongitude: scene.locationLongitude,
          zoom: scene.zoom,
          radiusMeters: scene.radiusMeters,
          radiusColorArgb: scene.radiusColorArgb,
          backgroundColorArgb: scene.backgroundColorArgb,
          paddingBottomPoints: scene.paddingBottomPoints,
          styleJson: scene.styleJson,
        ),
      );
      final frames = _readFrames(response, scene);
      if (response.isFinal && _activeRequests[rendererSlot]?.requestId == requestId) {
        _activeRequests.remove(rendererSlot);
      }
      return frames;
    } on Object {
      if (_activeRequests[rendererSlot]?.requestId == requestId) _activeRequests.remove(rendererSlot);
      if (response != null) await _releaseTextures(response.textureId, response.previewTextureId);
      rethrow;
    }
  }

  @override
  Future<void> release(MapFrame frame) => _hostApi.releaseTexture(frame.textureId);

  @override
  void frameProgress(NativeMapFinalFrame frame) => _deliverFrame(frame, isFinal: false);

  @override
  void frameFinal(NativeMapFinalFrame frame) => _deliverFrame(frame, isFinal: true);

  void _deliverFrame(NativeMapFinalFrame frame, {required bool isFinal}) {
    final active = _activeRequests[frame.rendererSlot];
    if (active == null || active.requestId != frame.requestId) {
      unawaited(_releaseTextures(frame.textureId, frame.previewTextureId));
      return;
    }
    if (frame.widthPx != active.scene.widthPx ||
        frame.heightPx != active.scene.heightPx ||
        frame.previewWidthPx <= 0 ||
        frame.previewHeightPx <= 0 ||
        frame.previewWidthPx > frame.widthPx ||
        frame.previewHeightPx > frame.heightPx ||
        frame.previewTextureId == frame.textureId) {
      unawaited(_releaseTextures(frame.textureId, frame.previewTextureId));
      return;
    }
    final listener = isFinal ? _frameFinalListener : _frameProgressListener;
    if (listener == null) {
      unawaited(_releaseTextures(frame.textureId, frame.previewTextureId));
      return;
    }
    if (isFinal) _activeRequests.remove(frame.rendererSlot);
    listener((
      requestId: frame.requestId,
      rendererSlot: frame.rendererSlot,
      full: MapFrame(scene: active.scene, textureId: frame.textureId, widthPx: frame.widthPx, heightPx: frame.heightPx),
      preview: MapFrame(
        scene: active.scene,
        textureId: frame.previewTextureId,
        widthPx: frame.previewWidthPx,
        heightPx: frame.previewHeightPx,
      ),
    ));
  }

  @override
  void rendererReset() {
    _activeRequests.clear();
    _rendererResetListener?.call();
  }

  @override
  Future<void> dispose() async {
    _frameFinalListener = null;
    _frameProgressListener = null;
    _rendererResetListener = null;
    _activeRequests.clear();
    JobMapFlutterApi.setUp(null, binaryMessenger: _binaryMessenger);
    try {
      await _hostApi.disposeFrames();
    } on PlatformException catch (error) {
      if (error.code != 'channel-error') rethrow;
    }
  }
}
