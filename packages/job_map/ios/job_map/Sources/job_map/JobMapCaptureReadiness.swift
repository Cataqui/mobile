struct JobMapCaptureReadiness {
  private(set) var hasTiles = false
  private(set) var canCaptureFinal = false

  mutating func markTilesRendered() {
    hasTiles = true
  }

  mutating func markSnapshotReady() {
    hasTiles = true
    canCaptureFinal = true
  }

  mutating func reset() {
    hasTiles = false
    canCaptureFinal = false
  }
}
