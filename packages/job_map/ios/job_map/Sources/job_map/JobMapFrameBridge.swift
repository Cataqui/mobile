import Accelerate
import CoreGraphics
import CoreVideo
import Flutter
import GoogleMaps
import QuartzCore
import UIKit
import os

final class JobMapFrameBridge: NSObject, JobMapHostApi, GMSMapViewDelegate {
  private struct ProgressiveFrame {
    let requestId: Int
    let widthPx: Int
    let heightPx: Int
    let isReadyPreview: Bool
  }

  private let flutterApi: JobMapFlutterApi
  private let textureRegistry: FlutterTextureRegistry
  private let frameQueue = DispatchQueue(label: "com.cataqui.mobile.job_map_frames", qos: .userInitiated)
  private let classificationQueue = DispatchQueue(label: "com.cataqui.mobile.job_map_classification", qos: .userInitiated)
  private var rendererSlots: [JobMapRendererSlot?] = [nil, nil]
  private var textures: [Int64: JobMapTexture] = [:]
  private var parsedStyles: [String: GMSMapStyle] = [:]
  private var progressiveFrames: [Int: ProgressiveFrame] = [:]
  private var fullFrameInFlight: [Int: Int] = [:]
  private var fullCaptureRetries: [Int: Int] = [:]
  private var retargetSignatures: [Int: JobMapPixelClassifier.Analysis] = [:]
  private var scrollActive = false
  private var allowReadyPreview = false
  private let retargetPolicy = JobMapRetargetPolicy()
  private var receivedMemoryWarning = false
  private var memoryWarningObserver: NSObjectProtocol?

  init(messenger: FlutterBinaryMessenger, textureRegistry: FlutterTextureRegistry) {
    flutterApi = JobMapFlutterApi(binaryMessenger: messenger)
    self.textureRegistry = textureRegistry
    super.init()
    memoryWarningObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didReceiveMemoryWarningNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.receivedMemoryWarning = true
    }
  }

  deinit {
    if let memoryWarningObserver {
      NotificationCenter.default.removeObserver(memoryWarningObserver)
    }
  }

  func readRenderCapabilities() throws -> NativeMapCapabilities {
    let processInfo = ProcessInfo.processInfo
    let lowMemory = receivedMemoryWarning
    receivedMemoryWarning = false
    let thermalState: Int
    switch processInfo.thermalState {
    case .nominal:
      thermalState = 0
    case .fair:
      thermalState = 1
    case .serious:
      thermalState = 2
    case .critical:
      thermalState = 3
    @unknown default:
      thermalState = 3
    }
    return NativeMapCapabilities(
      lowMemory: lowMemory,
      lowRamDevice: false,
      availableMemoryBytes: Int64(os_proc_available_memory()),
      totalMemoryBytes: Int64(clamping: processInfo.physicalMemory),
      processorCount: Int64(processInfo.processorCount),
      thermalState: Int64(thermalState),
      maxRendererSlots: Int64(rendererSlots.count))
  }

  func render(
    request: NativeMapRenderRequest,
    completion result: @escaping (Result<NativeMapFrames, Error>) -> Void
  ) {
    let requestId = Int(request.requestId)
    let rendererSlot = Int(request.rendererSlot)
    let widthPx = Int(request.widthPx)
    let heightPx = Int(request.heightPx)
    let widthPoints = request.widthPoints
    let heightPoints = request.heightPoints
    let nativeScale = request.nativeScale
    let cameraLatitude = request.cameraLatitude
    let cameraLongitude = request.cameraLongitude
    let locationLatitude = request.locationLatitude
    let locationLongitude = request.locationLongitude
    let zoom = request.zoom
    let radiusMeters = request.radiusMeters
    let radiusColorArgb = Int(request.radiusColorArgb)
    let backgroundColorArgb = Int(request.backgroundColorArgb)
    let paddingBottomPoints = request.paddingBottomPoints
    guard
      rendererSlots.indices.contains(rendererSlot),
      widthPx > 0, heightPx > 0,
      widthPx <= 4096, heightPx <= 4096,
      widthPx * heightPx <= 8_000_000,
      widthPoints.isFinite, heightPoints.isFinite,
      widthPoints > 0, heightPoints > 0,
      nativeScale.isFinite, nativeScale > 0, nativeScale <= 1,
      cameraLatitude.isFinite, cameraLongitude.isFinite,
      locationLatitude.isFinite, locationLongitude.isFinite,
      zoom.isFinite, radiusMeters.isFinite, paddingBottomPoints.isFinite,
      (-90...90).contains(cameraLatitude), (-180...180).contains(cameraLongitude),
      (-90...90).contains(locationLatitude), (-180...180).contains(locationLongitude),
      zoom + log2(nativeScale) >= 0,
      radiusMeters >= 0, paddingBottomPoints >= 0
    else {
      result(.failure(PigeonError(code: "invalid_arguments", message: "Invalid map frame request", details: nil)))
      return
    }

    guard let window = activeWindow() else {
      result(.failure(PigeonError(code: "no_window", message: "No active app window", details: nil)))
      return
    }

    let styleJson = request.styleJson
    let style: GMSMapStyle?
    if let styleJson {
      do {
        if let cachedStyle = parsedStyles[styleJson] {
          style = cachedStyle
        } else {
          let parsedStyle = try GMSMapStyle(jsonString: styleJson)
          parsedStyles[styleJson] = parsedStyle
          style = parsedStyle
        }
      } catch {
        result(.failure(PigeonError(code: "invalid_style", message: error.localizedDescription, details: nil)))
        return
      }
    } else {
      style = nil
    }

    let nativeZoom = zoom + log2(nativeScale)
    let frame = CGRect(
      x: 0, y: 0, width: widthPoints * nativeScale, height: heightPoints * nativeScale)
    let camera = GMSCameraPosition(
      latitude: cameraLatitude, longitude: cameraLongitude, zoom: Float(nativeZoom))
    let location = CLLocationCoordinate2D(latitude: locationLatitude, longitude: locationLongitude)
    progressiveFrames.removeValue(forKey: rendererSlot)
    fullFrameInFlight.removeValue(forKey: rendererSlot)
    fullCaptureRetries.removeValue(forKey: rendererSlot)
    let previousCamera = rendererSlots[rendererSlot]?.mapView.camera
    let cameraChangedBeforeReplacement = previousCamera.map {
      abs($0.target.latitude - cameraLatitude) > 0.0000001
        || abs($0.target.longitude - cameraLongitude) > 0.0000001
        || abs(Double($0.zoom) - nativeZoom) > 0.0001
    } ?? false
    if let existing = rendererSlots[rendererSlot],
      existing.backgroundColorArgb != backgroundColorArgb
        || retargetPolicy.shouldCreateFreshView(cameraChanged: cameraChangedBeforeReplacement) {
      retargetSignatures.removeValue(forKey: rendererSlot)
      existing.finishPending(
        with: PigeonError(code: "superseded", message: "A newer map request replaced this one", details: nil))
      existing.mapView.delegate = nil
      existing.circle.map = nil
      existing.mapView.removeFromSuperview()
      rendererSlots[rendererSlot] = nil
    }

    let slot: JobMapRendererSlot
    let reusedMapView: Bool
    if let existing = rendererSlots[rendererSlot] {
      slot = existing
      reusedMapView = true
      if slot.mapView.superview !== window {
        slot.mapView.removeFromSuperview()
        window.insertSubview(slot.mapView, at: 0)
        slot.captureReadiness.reset()
      }
    } else {
      reusedMapView = false
      let options = GMSMapViewOptions()
      options.frame = frame
      options.camera = camera
      options.backgroundColor = color(from: backgroundColorArgb)
      let mapView = GMSMapView(options: options)
      mapView.isUserInteractionEnabled = false
      mapView.paddingAdjustmentBehavior = .never
      let circle = GMSCircle(position: location, radius: radiusMeters)
      circle.fillColor = color(from: radiusColorArgb)
      circle.strokeColor = UIColor.clear
      circle.strokeWidth = 0
      slot = JobMapRendererSlot(
        mapView: mapView,
        circle: circle,
        backgroundColorArgb: backgroundColorArgb,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        radiusMeters: radiusMeters,
        radiusColorArgb: radiusColorArgb,
        paddingBottomPoints: paddingBottomPoints)
      rendererSlots[rendererSlot] = slot
      window.insertSubview(mapView, at: 0)
      mapView.delegate = self
    }

    slot.finishPending(
      with: PigeonError(code: "superseded", message: "A newer map request replaced this one", details: nil))
    let cameraChanged = reusedMapView && cameraChangedBeforeReplacement
    let styleChanged = slot.lastStyleJson != styleJson
    let sizeChanged = slot.mapView.bounds.size != frame.size
    let paddingChanged = slot.lastPaddingBottomPoints != paddingBottomPoints
    let circleChanged = (slot.lastRadiusMeters > 0 || radiusMeters > 0)
      && (slot.lastLocationLatitude != locationLatitude
        || slot.lastLocationLongitude != locationLongitude
        || slot.lastRadiusMeters != radiusMeters
        || slot.lastRadiusColorArgb != radiusColorArgb)
    if reusedMapView, cameraChanged, !styleChanged, !sizeChanged {
      // Before the first publication, a reused map may still show old tiles.
      // Compare new tiles with the pixels actually on it before retargeting.
      let preview = previewSize(slot: slot, widthPx: widthPx, heightPx: heightPx)
      if let baseline = captureMap(
        slot: slot,
        widthPx: preview.width,
        heightPx: preview.height,
        afterScreenUpdates: false) {
        retargetSignatures[rendererSlot] = JobMapPixelClassifier.analyze(
          baseline, includesCenter: slot.lastRadiusMeters == 0)
      } else {
        retargetSignatures.removeValue(forKey: rendererSlot)
      }
    } else {
      retargetSignatures.removeValue(forKey: rendererSlot)
    }
    let needsTileRefresh = !slot.captureReadiness.hasTiles
      || cameraChanged
      || sizeChanged
      || styleChanged
      || circleChanged
      || paddingChanged

    if needsTileRefresh {
      slot.captureReadiness.reset()
    }
    slot.pendingRequestId = requestId
    slot.pendingResult = result
    slot.pendingSize = (widthPx: widthPx, heightPx: heightPx)
    slot.mapView.frame = frame
    slot.mapView.padding = UIEdgeInsets(
      top: 0, left: 0, bottom: paddingBottomPoints * nativeScale, right: 0)
    slot.circle.position = location
    slot.circle.radius = radiusMeters
    slot.circle.fillColor = color(from: radiusColorArgb)
    slot.circle.map = radiusMeters > 0 ? slot.mapView : nil
    slot.lastLocationLatitude = locationLatitude
    slot.lastLocationLongitude = locationLongitude
    slot.lastRadiusMeters = radiusMeters
    slot.lastRadiusColorArgb = radiusColorArgb
    slot.lastPaddingBottomPoints = paddingBottomPoints
    if slot.lastStyleJson != styleJson {
      slot.mapView.mapStyle = style
      slot.lastStyleJson = styleJson
    }
    if needsTileRefresh {
      if !reusedMapView || cameraChanged || styleChanged || sizeChanged || paddingChanged {
        slot.mapView.moveCamera(GMSCameraUpdate.setCamera(camera))
      }
      if !reusedMapView || (!cameraChanged && !styleChanged)
        || retargetSignatures[rendererSlot] != nil {
        let delays = retargetPolicy.earlyProbeDelays(
          isNewView: !reusedMapView,
          hasRetargetSignature: retargetSignatures[rendererSlot] != nil)
        for delay in delays {
          DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak slot] in
            guard let self, let slot else { return }
            self.probeEarlyFrame(
              slot: slot,
              rendererSlot: rendererSlot,
              requestId: requestId,
              widthPx: widthPx,
              heightPx: heightPx)
          }
        }
      }
    } else {
      DispatchQueue.main.async { [weak self, weak slot] in
        guard let self, let slot, slot.pendingRequestId == requestId else { return }
        self.captureFullFrame(
          slot: slot,
          rendererSlot: rendererSlot,
          requestId: requestId,
          widthPx: widthPx,
          heightPx: heightPx)
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak slot] in
      guard let slot, slot.pendingRequestId == requestId else { return }
      slot.finishPending(
        with: PigeonError(code: "map_timeout", message: "Map tiles did not become ready", details: nil))
    }
  }

  private func activeWindow() -> UIWindow? {
    for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
      if let window = scene.windows.first(where: \.isKeyWindow) {
        return window
      }
    }
    return nil
  }

  private func color(from argb: Int) -> UIColor {
    let value = UInt32(truncatingIfNeeded: argb)
    return UIColor(
      red: CGFloat((value >> 16) & 0xff) / 255,
      green: CGFloat((value >> 8) & 0xff) / 255,
      blue: CGFloat(value & 0xff) / 255,
      alpha: CGFloat((value >> 24) & 0xff) / 255)
  }

  private func previewSize(slot: JobMapRendererSlot, widthPx: Int, heightPx: Int) -> (width: Int, height: Int) {
    (
      width: Int(min(Double(widthPx), max(1, slot.mapView.bounds.width.rounded()))),
      height: Int(min(Double(heightPx), max(1, slot.mapView.bounds.height.rounded())))
    )
  }

  private func makePixelBuffer(widthPx: Int, heightPx: Int) -> CVPixelBuffer? {
    let properties: [CFString: Any] = [
      kCVPixelBufferMetalCompatibilityKey: true,
      kCVPixelBufferIOSurfacePropertiesKey: [:],
    ]
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault, widthPx, heightPx, kCVPixelFormatType_32BGRA,
      properties as CFDictionary, &pixelBuffer)
    guard status == kCVReturnSuccess else { return nil }
    return pixelBuffer
  }

  private func captureMap(
    slot: JobMapRendererSlot,
    widthPx: Int,
    heightPx: Int,
    afterScreenUpdates: Bool
  ) -> CVPixelBuffer? {
    guard let pixelBuffer = makePixelBuffer(widthPx: widthPx, heightPx: heightPx) else { return nil }
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
      | CGBitmapInfo.byteOrder32Little.rawValue
    guard let context = CGContext(
      data: CVPixelBufferGetBaseAddress(pixelBuffer), width: widthPx, height: heightPx,
      bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo)
    else { return nil }
    context.setFillColor(color(from: slot.backgroundColorArgb).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: widthPx, height: heightPx))
    context.translateBy(x: 0, y: CGFloat(heightPx))
    context.scaleBy(
      x: CGFloat(widthPx) / slot.mapView.bounds.width,
      y: -CGFloat(heightPx) / slot.mapView.bounds.height)
    UIGraphicsPushContext(context)
    let didDraw = slot.mapView.drawHierarchy(
      in: slot.mapView.bounds, afterScreenUpdates: afterScreenUpdates)
    UIGraphicsPopContext()
    return didDraw ? pixelBuffer : nil
  }

  private func scaledPixelBuffer(
    from source: CVPixelBuffer,
    widthPx: Int,
    heightPx: Int
  ) -> CVPixelBuffer? {
    guard let destination = makePixelBuffer(widthPx: widthPx, heightPx: heightPx) else { return nil }
    CVPixelBufferLockBaseAddress(source, .readOnly)
    CVPixelBufferLockBaseAddress(destination, [])
    defer {
      CVPixelBufferUnlockBaseAddress(destination, [])
      CVPixelBufferUnlockBaseAddress(source, .readOnly)
    }
    var sourceImage = vImage_Buffer(
      data: CVPixelBufferGetBaseAddress(source),
      height: vImagePixelCount(CVPixelBufferGetHeight(source)),
      width: vImagePixelCount(CVPixelBufferGetWidth(source)),
      rowBytes: CVPixelBufferGetBytesPerRow(source))
    var destinationImage = vImage_Buffer(
      data: CVPixelBufferGetBaseAddress(destination),
      height: vImagePixelCount(heightPx),
      width: vImagePixelCount(widthPx),
      rowBytes: CVPixelBufferGetBytesPerRow(destination))
    guard vImageScale_ARGB8888(
      &sourceImage, &destinationImage, nil, vImage_Flags(kvImageHighQualityResampling)) == kvImageNoError
    else { return nil }
    return destination
  }

  private func registerTexture(with pixelBuffer: CVPixelBuffer) -> Int64 {
    let texture = JobMapTexture()
    texture.update(with: pixelBuffer)
    let textureId = textureRegistry.register(texture)
    textures[textureId] = texture
    textureRegistry.textureFrameAvailable(textureId)
    return textureId
  }

  private func frameResult(
    fullTextureId: Int64,
    previewTextureId: Int64,
    widthPx: Int,
    heightPx: Int,
    previewWidthPx: Int,
    previewHeightPx: Int,
    isFinal: Bool
  ) -> NativeMapFrames {
    NativeMapFrames(
      textureId: fullTextureId,
      widthPx: Int64(widthPx),
      heightPx: Int64(heightPx),
      previewTextureId: previewTextureId,
      previewWidthPx: Int64(previewWidthPx),
      previewHeightPx: Int64(previewHeightPx),
      isFinal: isFinal)
  }

  func setScrollActive(active: Bool, allowReadyPreview: Bool) throws {
    scrollActive = active
    let readyPreviewBecameAllowed = active && allowReadyPreview && !self.allowReadyPreview
    self.allowReadyPreview = allowReadyPreview
    if readyPreviewBecameAllowed {
      for rendererSlot in rendererSlots.indices {
        guard let slot = rendererSlots[rendererSlot], slot.captureReadiness.hasTiles,
          let frame = progressiveFrames[rendererSlot]
        else { continue }
        publishReadyPreview(slot: slot, rendererSlot: rendererSlot, frame: frame)
      }
    }
    if !active {
      var nextCaptureDelay = 0.0
      for rendererSlot in rendererSlots.indices {
        guard let slot = rendererSlots[rendererSlot], slot.captureReadiness.canCaptureFinal else { continue }
        let request: (id: Int, widthPx: Int, heightPx: Int)
        if let requestId = slot.pendingRequestId, let size = slot.pendingSize {
          request = (id: requestId, widthPx: size.widthPx, heightPx: size.heightPx)
        } else if let progressive = progressiveFrames[rendererSlot] {
          request = (
            id: progressive.requestId,
            widthPx: progressive.widthPx,
            heightPx: progressive.heightPx)
        } else {
          continue
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + nextCaptureDelay) { [weak self, weak slot] in
          guard let self, let slot else { return }
          self.captureFullFrame(
            slot: slot,
            rendererSlot: rendererSlot,
            requestId: request.id,
            widthPx: request.widthPx,
            heightPx: request.heightPx)
        }
        nextCaptureDelay += 1.0 / 60.0
      }
    }
  }

  private func probeEarlyFrame(
    slot: JobMapRendererSlot,
    rendererSlot: Int,
    requestId: Int,
    widthPx: Int,
    heightPx: Int
  ) {
    guard rendererSlots[rendererSlot] === slot,
      slot.pendingRequestId == requestId,
      (!slot.captureReadiness.canCaptureFinal || scrollActive)
    else { return }

    let preview = previewSize(slot: slot, widthPx: widthPx, heightPx: heightPx)
    guard preview.width >= JobMapPixelClassifier.minimumDimensionPx,
      preview.height >= JobMapPixelClassifier.minimumDimensionPx else { return }
    guard let previewBuffer = captureMap(
      slot: slot,
      widthPx: preview.width,
      heightPx: preview.height,
      afterScreenUpdates: false)
    else { return }
    let includesCenter = slot.lastRadiusMeters == 0
    let retainSamples = retargetSignatures[rendererSlot] != nil
    classificationQueue.async { [weak self, weak slot] in
      let analysis = JobMapPixelClassifier.analyze(
        previewBuffer,
        includesCenter: includesCenter,
        retainSamples: retainSamples)
      DispatchQueue.main.async { [weak self, weak slot] in
        guard let self, let slot,
          self.rendererSlots[rendererSlot] === slot,
          slot.pendingRequestId == requestId,
          (!slot.captureReadiness.canCaptureFinal || self.scrollActive),
          let analysis, analysis.hasDetail
        else { return }
        if let previous = self.retargetSignatures[rendererSlot],
          !JobMapPixelClassifier.hasChangedMapDetail(from: previous, to: analysis) {
          return
        }
        self.publishEarlyFrame(
          slot: slot,
          rendererSlot: rendererSlot,
          requestId: requestId,
          widthPx: widthPx,
          heightPx: heightPx,
          previewBuffer: previewBuffer)
      }
    }
  }

  private func publishEarlyFrame(
    slot: JobMapRendererSlot,
    rendererSlot: Int,
    requestId: Int,
    widthPx: Int,
    heightPx: Int,
    previewBuffer: CVPixelBuffer
  ) {
    guard rendererSlots[rendererSlot] === slot,
      slot.pendingRequestId == requestId,
      (!slot.captureReadiness.canCaptureFinal || scrollActive)
    else { return }
    let preview = previewSize(slot: slot, widthPx: widthPx, heightPx: heightPx)
    // Flutter scales the texture itself. Both handles retain immutable pixels
    // so Dart can blend them with the later full capture without CPU upscaling.
    let fullTextureId = registerTexture(with: previewBuffer)
    let previewTextureId = registerTexture(with: previewBuffer)
    retargetPolicy.markFramePublished()
    progressiveFrames[rendererSlot] = ProgressiveFrame(
      requestId: requestId,
      widthPx: widthPx,
      heightPx: heightPx,
      isReadyPreview: slot.captureReadiness.hasTiles)
    retargetSignatures.removeValue(forKey: rendererSlot)
    // Reserve the eventual full-size allocation in Dart's cache budget now.
    slot.finishPending(with: frameResult(
      fullTextureId: fullTextureId,
      previewTextureId: previewTextureId,
      widthPx: widthPx,
      heightPx: heightPx,
      previewWidthPx: preview.width,
      previewHeightPx: preview.height,
      isFinal: false))
  }

  private func captureFullFrame(
    slot: JobMapRendererSlot,
    rendererSlot: Int,
    requestId: Int,
    widthPx: Int,
    heightPx: Int
  ) {
    guard (slot.pendingRequestId == requestId || progressiveFrames[rendererSlot]?.requestId == requestId),
      fullFrameInFlight[rendererSlot] != requestId,
      slot.captureReadiness.canCaptureFinal,
      !scrollActive
    else {
      return
    }
    fullFrameInFlight[rendererSlot] = requestId
    guard let fullBuffer = captureMap(
      slot: slot,
      widthPx: widthPx,
      heightPx: heightPx,
      afterScreenUpdates: false) else {
      fullFrameInFlight.removeValue(forKey: rendererSlot)
      retryFullCaptureOrFinish(
        slot: slot,
        rendererSlot: rendererSlot,
        requestId: requestId,
        widthPx: widthPx,
        heightPx: heightPx)
      return
    }
    let preview = previewSize(slot: slot, widthPx: widthPx, heightPx: heightPx)
    let includesCenter = slot.lastRadiusMeters == 0
    frameQueue.async { [weak self, weak slot] in
      guard let self else { return }
      let previewBuffer = self.scaledPixelBuffer(
        from: fullBuffer, widthPx: preview.width, heightPx: preview.height)
      let hasMapDetail = previewBuffer.flatMap {
        JobMapPixelClassifier.analyze(
          $0, includesCenter: includesCenter, retainSamples: false)?.hasDetail
      } ?? false
      DispatchQueue.main.async { [weak self, weak slot] in
        guard let self, let slot, self.rendererSlots[rendererSlot] === slot else { return }
        if self.fullFrameInFlight[rendererSlot] == requestId {
          self.fullFrameInFlight.removeValue(forKey: rendererSlot)
        }
        guard let previewBuffer, hasMapDetail else {
          self.retryFullCaptureOrFinish(
            slot: slot,
            rendererSlot: rendererSlot,
            requestId: requestId,
            widthPx: widthPx,
            heightPx: heightPx)
          return
        }
        if slot.pendingRequestId == requestId
          || self.progressiveFrames[rendererSlot]?.requestId == requestId {
          self.fullCaptureRetries.removeValue(forKey: rendererSlot)
        }
        if slot.pendingRequestId == requestId {
          self.retargetSignatures.removeValue(forKey: rendererSlot)
          let fullTextureId = self.registerTexture(with: fullBuffer)
          let previewTextureId = self.registerTexture(with: previewBuffer)
          self.retargetPolicy.markFramePublished()
          slot.finishPending(with: self.frameResult(
            fullTextureId: fullTextureId,
            previewTextureId: previewTextureId,
            widthPx: widthPx,
            heightPx: heightPx,
            previewWidthPx: preview.width,
            previewHeightPx: preview.height,
            isFinal: true))
          return
        }
        guard let progressive = self.progressiveFrames[rendererSlot],
          progressive.requestId == requestId
        else { return }
        self.retargetSignatures.removeValue(forKey: rendererSlot)
        let fullTextureId = self.registerTexture(with: fullBuffer)
        let previewTextureId = self.registerTexture(with: previewBuffer)
        self.retargetPolicy.markFramePublished()
        self.progressiveFrames.removeValue(forKey: rendererSlot)
        self.flutterApi.frameFinal(
          frame: NativeMapFinalFrame(
            requestId: Int64(requestId),
            rendererSlot: Int64(rendererSlot),
            textureId: fullTextureId,
            widthPx: Int64(widthPx),
            heightPx: Int64(heightPx),
            previewTextureId: previewTextureId,
            previewWidthPx: Int64(preview.width),
            previewHeightPx: Int64(preview.height))) { _ in }
      }
    }
  }

  private func publishReadyPreview(slot: JobMapRendererSlot, rendererSlot: Int, frame: ProgressiveFrame) {
    guard rendererSlots[rendererSlot] === slot,
      progressiveFrames[rendererSlot]?.requestId == frame.requestId,
      scrollActive,
      allowReadyPreview,
      !frame.isReadyPreview
    else { return }
    let preview = previewSize(slot: slot, widthPx: frame.widthPx, heightPx: frame.heightPx)
    guard let pixels = captureMap(
      slot: slot,
      widthPx: preview.width,
      heightPx: preview.height,
      afterScreenUpdates: false)
    else { return }
    guard JobMapPixelClassifier.analyze(
      pixels, includesCenter: slot.lastRadiusMeters == 0, retainSamples: false)?.hasDetail == true
    else { return }
    let fullTextureId = registerTexture(with: pixels)
    let previewTextureId = registerTexture(with: pixels)
    progressiveFrames[rendererSlot] = ProgressiveFrame(
      requestId: frame.requestId,
      widthPx: frame.widthPx,
      heightPx: frame.heightPx,
      isReadyPreview: true)
    flutterApi.frameProgress(
      frame: NativeMapFinalFrame(
        requestId: Int64(frame.requestId),
        rendererSlot: Int64(rendererSlot),
        textureId: fullTextureId,
        widthPx: Int64(frame.widthPx),
        heightPx: Int64(frame.heightPx),
        previewTextureId: previewTextureId,
        previewWidthPx: Int64(preview.width),
        previewHeightPx: Int64(preview.height))) { _ in }
  }

  private func retryFullCaptureOrFinish(
    slot: JobMapRendererSlot,
    rendererSlot: Int,
    requestId: Int,
    widthPx: Int,
    heightPx: Int
  ) {
    guard slot.pendingRequestId == requestId
      || progressiveFrames[rendererSlot]?.requestId == requestId
    else { return }
    let attempts = fullCaptureRetries[rendererSlot] ?? 0
    if attempts < 2 {
      fullCaptureRetries[rendererSlot] = attempts + 1
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self, weak slot] in
        guard let self, let slot, self.rendererSlots[rendererSlot] === slot else { return }
        self.captureFullFrame(
          slot: slot,
          rendererSlot: rendererSlot,
          requestId: requestId,
          widthPx: widthPx,
          heightPx: heightPx)
      }
      return
    }
    fullCaptureRetries.removeValue(forKey: rendererSlot)
    if slot.pendingRequestId == requestId {
      slot.finishPending(with: PigeonError(
        code: "capture_failed", message: "Could not draw map pixels", details: nil))
    }
  }

  func releaseTexture(textureId: Int64) throws {
    if textures.removeValue(forKey: textureId) != nil {
      textureRegistry.unregisterTexture(textureId)
    }
  }

  func disposeFrames() throws {
    for slot in rendererSlots.compactMap({ $0 }) {
      slot.finishPending(
        with: PigeonError(code: "disposed", message: "Map renderer disposed", details: nil))
      slot.mapView.delegate = nil
      slot.circle.map = nil
      slot.mapView.removeFromSuperview()
    }
    rendererSlots = [nil, nil]
    progressiveFrames.removeAll()
    fullFrameInFlight.removeAll()
    fullCaptureRetries.removeAll()
    retargetSignatures.removeAll()
    scrollActive = false
    allowReadyPreview = false
    retargetPolicy.reset()
    for textureId in textures.keys {
      textureRegistry.unregisterTexture(textureId)
    }
    textures.removeAll()
    parsedStyles.removeAll()
  }

  func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
    finishReadyMap(mapView, stable: false)
  }

  func mapViewSnapshotReady(_ mapView: GMSMapView) {
    finishReadyMap(mapView, stable: true)
  }

  private func finishReadyMap(_ mapView: GMSMapView, stable: Bool) {
    guard let rendererSlot = rendererSlots.firstIndex(where: { $0?.mapView === mapView }),
      let slot = rendererSlots[rendererSlot]
    else {
      return
    }
    if stable {
      slot.captureReadiness.markSnapshotReady()
    } else {
      slot.captureReadiness.markTilesRendered()
    }
    if scrollActive || !slot.captureReadiness.canCaptureFinal {
      if let requestId = slot.pendingRequestId, let size = slot.pendingSize {
        probeEarlyFrame(
          slot: slot,
          rendererSlot: rendererSlot,
          requestId: requestId,
          widthPx: size.widthPx,
          heightPx: size.heightPx)
      } else if allowReadyPreview, let frame = progressiveFrames[rendererSlot] {
        publishReadyPreview(slot: slot, rendererSlot: rendererSlot, frame: frame)
      }
      return
    }
    if let requestId = slot.pendingRequestId, let arguments = slot.pendingSize {
      captureFullFrame(
        slot: slot,
        rendererSlot: rendererSlot,
        requestId: requestId,
        widthPx: arguments.widthPx,
        heightPx: arguments.heightPx)
      return
    }
    guard let progressive = progressiveFrames[rendererSlot] else { return }
    captureFullFrame(
      slot: slot,
      rendererSlot: rendererSlot,
      requestId: progressive.requestId,
      widthPx: progressive.widthPx,
      heightPx: progressive.heightPx)
  }
}
