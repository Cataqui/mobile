import 'package:pigeon/pigeon.dart';

class NativeMapRenderRequest {
  int requestId;
  int rendererSlot;
  int widthPx;
  int heightPx;
  double widthPoints;
  double heightPoints;
  double nativeScale;
  double previewScale;
  double cameraLatitude;
  double cameraLongitude;
  double locationLatitude;
  double locationLongitude;
  double zoom;
  double radiusMeters;
  int radiusColorArgb;
  int backgroundColorArgb;
  double paddingBottomPoints;
  String? styleJson;
}

class NativeMapFrames {
  int textureId;
  int widthPx;
  int heightPx;
  int previewTextureId;
  int previewWidthPx;
  int previewHeightPx;
  bool isFinal;
}

class NativeMapFinalFrame {
  int requestId;
  int rendererSlot;
  int textureId;
  int widthPx;
  int heightPx;
  int previewTextureId;
  int previewWidthPx;
  int previewHeightPx;
}

class NativeMapCapabilities {
  bool lowMemory;
  bool lowRamDevice;
  int availableMemoryBytes;
  int totalMemoryBytes;
  int processorCount;
  int thermalState;
  int maxRendererSlots;
}

@HostApi()
abstract class JobMapHostApi {
  @async
  NativeMapFrames render(NativeMapRenderRequest request);

  void releaseTexture(int textureId);

  void setScrollActive(bool active, bool allowReadyPreview);

  NativeMapCapabilities readRenderCapabilities();

  void disposeFrames();
}

@FlutterApi()
abstract class JobMapFlutterApi {
  void frameProgress(NativeMapFinalFrame frame);

  void frameFinal(NativeMapFinalFrame frame);

  void rendererReset();
}
