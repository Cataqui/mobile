import Flutter
import GoogleMaps

final class JobMapRendererSlot {
  let mapView: GMSMapView
  let circle: GMSCircle
  let backgroundColorArgb: Int
  var pendingRequestId: Int?
  var pendingResult: ((Result<NativeMapFrames, Error>) -> Void)?
  var pendingSize: (widthPx: Int, heightPx: Int)?
  var captureReadiness = JobMapCaptureReadiness()
  var lastStyleJson: String?
  var lastLocationLatitude: Double
  var lastLocationLongitude: Double
  var lastRadiusMeters: Double
  var lastRadiusColorArgb: Int
  var lastPaddingBottomPoints: Double

  init(
    mapView: GMSMapView,
    circle: GMSCircle,
    backgroundColorArgb: Int,
    locationLatitude: Double,
    locationLongitude: Double,
    radiusMeters: Double,
    radiusColorArgb: Int,
    paddingBottomPoints: Double
  ) {
    self.mapView = mapView
    self.circle = circle
    self.backgroundColorArgb = backgroundColorArgb
    lastLocationLatitude = locationLatitude
    lastLocationLongitude = locationLongitude
    lastRadiusMeters = radiusMeters
    lastRadiusColorArgb = radiusColorArgb
    lastPaddingBottomPoints = paddingBottomPoints
  }

  func finishPending(with response: NativeMapFrames) {
    finishPending(with: .success(response))
  }

  func finishPending(with error: PigeonError) {
    finishPending(with: .failure(error))
  }

  private func finishPending(with response: Result<NativeMapFrames, Error>) {
    let result = pendingResult
    pendingResult = nil
    pendingRequestId = nil
    pendingSize = nil
    result?(response)
  }
}
