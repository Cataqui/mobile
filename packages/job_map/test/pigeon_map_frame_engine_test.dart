import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_map/src/enums/map_thermal_state.dart';
import 'package:job_map/src/generated/job_map_api.g.dart';
import 'package:job_map/src/job_map_scene.dart';
import 'package:job_map/src/map_frame_engine_types.dart';
import 'package:job_map/src/pigeon_map_frame_engine.dart';
import 'package:mocktail/mocktail.dart';

class MockJobMapHostApi extends Mock implements JobMapHostApi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NativeMapFinalFrame finalFrame({required int requestId, int textureId = 17, int widthPx = 640}) =>
      NativeMapFinalFrame(
        requestId: requestId,
        rendererSlot: 0,
        textureId: textureId,
        widthPx: widthPx,
        heightPx: 480,
        previewTextureId: textureId + 1,
        previewWidthPx: 160,
        previewHeightPx: 120,
      );

  const scene = JobMapScene(
    cameraLatitude: -23.55,
    cameraLongitude: -46.63,
    locationLatitude: -23.55,
    locationLongitude: -46.63,
    zoom: 13.5,
    radiusMeters: 600,
    radiusColorArgb: 0x2200AA00,
    backgroundColorArgb: 0xFFFFFFFF,
    paddingBottomPoints: 20,
    styleJson: '[]',
    widthPoints: 320,
    heightPoints: 240,
    widthPx: 640,
    heightPx: 480,
    nativeScale: 1,
  );

  setUpAll(() {
    registerFallbackValue(
      NativeMapRenderRequest(
        requestId: 0,
        rendererSlot: 0,
        widthPx: 1,
        heightPx: 1,
        widthPoints: 1,
        heightPoints: 1,
        nativeScale: 1,
        previewScale: 1,
        cameraLatitude: 0,
        cameraLongitude: 0,
        locationLatitude: 0,
        locationLongitude: 0,
        zoom: 0,
        radiusMeters: 0,
        radiusColorArgb: 0,
        backgroundColorArgb: 0,
        paddingBottomPoints: 0,
      ),
    );
  });

  late MockJobMapHostApi host;
  late PigeonMapFrameEngine engine;
  late List<int> released;
  late NativeMapFrames initialFrames;

  setUp(() {
    host = MockJobMapHostApi();
    released = [];
    initialFrames = NativeMapFrames(
      textureId: 7,
      widthPx: 640,
      heightPx: 480,
      previewTextureId: 8,
      previewWidthPx: 160,
      previewHeightPx: 120,
      isFinal: false,
    );
    when(() => host.render(any())).thenAnswer((_) async => initialFrames);
    when(() => host.releaseTexture(any())).thenAnswer((invocation) async {
      released.add(invocation.positionalArguments.single as int);
    });
    when(host.disposeFrames).thenAnswer((_) async {});
    when(() => host.setScrollActive(any(), any())).thenAnswer((_) async {});
    engine = PigeonMapFrameEngine(hostApi: host);
  });

  tearDown(() async => engine.dispose());

  test('render sends the typed geometry and retains separate preview and full textures', () async {
    final frames = await engine.render(scene, requestId: 4, rendererSlot: 0);
    final request = verify(() => host.render(captureAny())).captured.single as NativeMapRenderRequest;

    expect((request.requestId, request.rendererSlot), (4, 0));
    expect((request.widthPoints, request.heightPoints, request.widthPx, request.heightPx), (320, 240, 640, 480));
    expect((request.nativeScale, request.previewScale, request.paddingBottomPoints), (1, .75, 20));
    expect((request.zoom, request.radiusMeters, request.styleJson), (13.5, 600, '[]'));
    expect((frames.full.textureId, frames.preview.textureId, frames.isFinal), (7, 8, false));
    await engine.release(frames.full);
    await engine.release(frames.preview);
    expect(released, [7, 8]);
  });

  test('capabilities preserve native memory, thermal state, and renderer capacity', () async {
    when(host.readRenderCapabilities).thenAnswer(
      (_) async => NativeMapCapabilities(
        lowMemory: false,
        lowRamDevice: false,
        availableMemoryBytes: 128 * 1024 * 1024,
        totalMemoryBytes: 4 * 1024 * 1024 * 1024,
        processorCount: 6,
        thermalState: 2,
        maxRendererSlots: 2,
      ),
    );
    final capabilities = await engine.readRenderCapabilities();
    expect((capabilities.thermalState, capabilities.maxRendererSlots), (MapThermalState.serious, 2));
    expect(capabilities.availableMemoryBytes, 128 * 1024 * 1024);
    expect(capabilities.totalMemoryBytes, 4 * 1024 * 1024 * 1024);
  });

  test('scroll state reaches the native renderer on iOS', () async {
    debugDefaultTargetPlatformOverride = .iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await engine.setScrollActive(true, allowReadyPreview: true);
    await engine.setScrollActive(false);
    verify(() => host.setScrollActive(true, true)).called(1);
    verify(() => host.setScrollActive(false, false)).called(1);
  });

  test('final frame keeps its requested scene while an initial response is pending', () async {
    final pending = Completer<NativeMapFrames>();
    when(() => host.render(any())).thenAnswer((_) => pending.future);
    final events = <MapFrameFinalEvent>[];
    engine.setFrameFinalListener(events.add);
    final render = engine.render(scene, requestId: 4, rendererSlot: 0);
    engine.frameFinal(finalFrame(requestId: 4));
    pending.complete(initialFrames);
    final frames = await render;

    expect(events.single.full.scene, scene);
    expect((events.single.full.textureId, events.single.preview.textureId), (17, 18));
    expect((frames.full.textureId, frames.preview.textureId), (7, 8));
  });

  test('superseded and duplicate final frames release both native textures', () async {
    final events = <MapFrameFinalEvent>[];
    engine.setFrameFinalListener(events.add);
    await engine.render(scene, requestId: 4, rendererSlot: 0);
    await engine.render(scene, requestId: 5, rendererSlot: 0);
    engine
      ..frameFinal(finalFrame(requestId: 4))
      ..frameFinal(finalFrame(requestId: 5, textureId: 27))
      ..frameFinal(finalFrame(requestId: 5, textureId: 37));
    await Future<void>.delayed(Duration.zero);

    expect(events.single.requestId, 5);
    expect(released, containsAll([17, 18, 37, 38]));
    expect(released, hasLength(4));
  });

  test('SDK-ready preview can update a partial image before its final frame', () async {
    final progress = <MapFrameFinalEvent>[];
    final finals = <MapFrameFinalEvent>[];
    engine
      ..setFrameProgressListener(progress.add)
      ..setFrameFinalListener(finals.add);
    await engine.render(scene, requestId: 4, rendererSlot: 0);
    engine
      ..frameProgress(finalFrame(requestId: 4, textureId: 27))
      ..frameFinal(finalFrame(requestId: 4, textureId: 37));

    expect(progress.single.full.textureId, 27);
    expect(finals.single.full.textureId, 37);
    expect(released, isEmpty);
  });

  test('invalid final geometry is released without replacing the visible map', () async {
    final events = <MapFrameFinalEvent>[];
    engine.setFrameFinalListener(events.add);
    await engine.render(scene, requestId: 4, rendererSlot: 0);
    engine.frameFinal(finalFrame(requestId: 4, widthPx: 320));
    await Future<void>.delayed(Duration.zero);
    expect(events, isEmpty);
    expect(released, [17, 18]);
  });

  test('renderer reset invalidates cached ownership', () async {
    var resets = 0;
    engine.setRendererResetListener(() => resets++);
    await engine.render(scene, requestId: 4, rendererSlot: 0);
    engine
      ..rendererReset()
      ..frameFinal(finalFrame(requestId: 4));
    await Future<void>.delayed(Duration.zero);
    expect(resets, 1);
    expect(released, [17, 18]);
  });

  test('dispose still clears callbacks after the native plugin detaches', () async {
    final detachedEngine = PigeonMapFrameEngine();
    await detachedEngine.dispose();
  });
}
