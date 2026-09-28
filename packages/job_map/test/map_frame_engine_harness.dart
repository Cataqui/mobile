import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:job_map/job_map.dart';
import 'package:job_map/job_map_testing.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

class MapFrameEngineHarness {
  MapFrameEngineHarness({required this.mapFrameEngine, this.rendererSlotCount = 2}) {
    registerFallbackValue(_fallbackScene);
    registerFallbackValue(const MapFrame(scene: _fallbackScene, textureId: 0, widthPx: 1, heightPx: 1));
    when(() => mapFrameEngine.rendererSlotCount).thenAnswer((_) => rendererSlotCount);
    when(() => mapFrameEngine.setFrameFinalListener(any())).thenAnswer((invocation) {
      _frameFinalListener = invocation.positionalArguments.single as ValueChanged<MapFrameFinalEvent>?;
    });
    when(() => mapFrameEngine.setFrameProgressListener(any())).thenAnswer((invocation) {
      _frameProgressListener = invocation.positionalArguments.single as ValueChanged<MapFrameFinalEvent>?;
    });
    when(() => mapFrameEngine.setRendererResetListener(any())).thenAnswer((_) {});
    when(() => mapFrameEngine.setScrollActive(any(), allowReadyPreview: any(named: 'allowReadyPreview'))).thenAnswer((
      invocation,
    ) async {
      scrollActivityChanges.add(invocation.positionalArguments.single as bool);
      readyPreviewChanges.add(invocation.namedArguments[#allowReadyPreview]! as bool);
    });
    when(
      () => mapFrameEngine.render(
        any(),
        requestId: any(named: 'requestId'),
        rendererSlot: any(named: 'rendererSlot'),
      ),
    ).thenAnswer((invocation) {
      final request = PendingMapFrameRender(
        scene: invocation.positionalArguments.single as JobMapScene,
        requestId: invocation.namedArguments[#requestId]! as int,
        rendererSlot: invocation.namedArguments[#rendererSlot]! as int,
        completer: Completer<({MapFrame full, MapFrame preview, bool isFinal})>(),
      );
      requests.add(request);
      return request.completer.future;
    });
    when(() => mapFrameEngine.release(any())).thenAnswer((invocation) async {
      released.add(invocation.positionalArguments.single as MapFrame);
    });
    when(mapFrameEngine.dispose).thenAnswer((_) async {
      disposed = true;
      for (final request in requests) {
        if (!request.completer.isCompleted) request.completer.completeError(StateError('renderer disposed'));
      }
    });
  }

  final MockMapFrameEngine mapFrameEngine;
  int rendererSlotCount;

  static const _fallbackScene = JobMapScene(
    cameraLatitude: 0,
    cameraLongitude: 0,
    locationLatitude: 0,
    locationLongitude: 0,
    zoom: 13,
    radiusMeters: 0,
    radiusColorArgb: 0,
    backgroundColorArgb: 0,
    styleJson: null,
    widthPoints: 1,
    heightPoints: 1,
    paddingBottomPoints: 0,
    widthPx: 1,
    heightPx: 1,
  );

  final List<PendingMapFrameRender> requests = [];
  final List<MapFrame> released = [];
  final List<bool> scrollActivityChanges = [];
  final List<bool> readyPreviewChanges = [];
  ValueChanged<MapFrameFinalEvent>? _frameFinalListener;
  ValueChanged<MapFrameFinalEvent>? _frameProgressListener;
  bool disposed = false;

  void complete(PendingMapFrameRender request, {required int textureId, bool isFinal = true}) {
    request.completer.complete((
      full: MapFrame(
        scene: request.scene,
        textureId: textureId,
        widthPx: request.scene.widthPx,
        heightPx: request.scene.heightPx,
      ),
      preview: MapFrame(
        scene: request.scene,
        textureId: textureId + 1000,
        widthPx: (request.scene.widthPoints * request.scene.previewScale).round().clamp(1, request.scene.widthPx),
        heightPx: (request.scene.heightPoints * request.scene.previewScale).round().clamp(1, request.scene.heightPx),
      ),
      isFinal: isFinal,
    ));
  }

  void completeRequest(int requestId, {required int textureId}) =>
      complete(requests.singleWhere((request) => request.requestId == requestId), textureId: textureId);

  void finalize(PendingMapFrameRender request, {int? textureId}) {
    final finalTextureId = textureId ?? 10000 + request.requestId;
    _frameFinalListener?.call((
      requestId: request.requestId,
      rendererSlot: request.rendererSlot,
      full: MapFrame(
        scene: request.scene,
        textureId: finalTextureId,
        widthPx: request.scene.widthPx,
        heightPx: request.scene.heightPx,
      ),
      preview: MapFrame(
        scene: request.scene,
        textureId: finalTextureId + 1000,
        widthPx: (request.scene.widthPoints * request.scene.previewScale).round().clamp(1, request.scene.widthPx),
        heightPx: (request.scene.heightPoints * request.scene.previewScale).round().clamp(1, request.scene.heightPx),
      ),
    ));
  }

  void progress(PendingMapFrameRender request, {required int textureId}) {
    _frameProgressListener?.call((
      requestId: request.requestId,
      rendererSlot: request.rendererSlot,
      full: MapFrame(
        scene: request.scene,
        textureId: textureId,
        widthPx: request.scene.widthPx,
        heightPx: request.scene.heightPx,
      ),
      preview: MapFrame(
        scene: request.scene,
        textureId: textureId + 1000,
        widthPx: (request.scene.widthPoints * request.scene.previewScale).round().clamp(1, request.scene.widthPx),
        heightPx: (request.scene.heightPoints * request.scene.previewScale).round().clamp(1, request.scene.heightPx),
      ),
    ));
  }
}

@immutable
class PendingMapFrameRender {
  const PendingMapFrameRender({
    required this.scene,
    required this.requestId,
    required this.rendererSlot,
    required this.completer,
  });

  final JobMapScene scene;
  final int requestId;
  final int rendererSlot;
  final Completer<({MapFrame full, MapFrame preview, bool isFinal})> completer;
}
