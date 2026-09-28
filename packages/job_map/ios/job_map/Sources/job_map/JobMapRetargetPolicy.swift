final class JobMapRetargetPolicy {
  private var hasPublishedFrame = false

  func markFramePublished() {
    hasPublishedFrame = true
  }

  func shouldCreateFreshView(cameraChanged: Bool) -> Bool {
    hasPublishedFrame && cameraChanged
  }

  func earlyProbeDelays(isNewView: Bool, hasRetargetSignature: Bool) -> [Double] {
    if isNewView && hasPublishedFrame { return [0.1, 0.2, 0.4, 0.65, 0.8, 1.1, 1.35] }
    if hasRetargetSignature { return [0.2, 0.45, 0.65, 0.85, 1.1, 1.35] }
    return [0.1, 0.4, 0.65, 0.8, 1.1, 1.35]
  }

  func reset() {
    hasPublishedFrame = false
  }
}
