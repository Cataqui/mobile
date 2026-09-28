import XCTest
@testable import job_map

final class JobMapCaptureReadinessTests: XCTestCase {
  func testTileCompletionCannotFreezeDimLabelsAsTheFinalImage() {
    var readiness = JobMapCaptureReadiness()
    readiness.markTilesRendered()

    XCTAssertTrue(readiness.hasTiles)
    XCTAssertFalse(readiness.canCaptureFinal)

    readiness.markSnapshotReady()
    XCTAssertTrue(readiness.canCaptureFinal)
  }

  func testCameraRetargetWaitsForTheNewStableSnapshot() {
    var readiness = JobMapCaptureReadiness()
    readiness.markSnapshotReady()
    readiness.reset()
    readiness.markTilesRendered()

    XCTAssertFalse(readiness.canCaptureFinal)
  }

  func testLateTileCallbackDoesNotDemoteAStableMap() {
    var readiness = JobMapCaptureReadiness()
    readiness.markSnapshotReady()
    readiness.markTilesRendered()

    XCTAssertTrue(readiness.canCaptureFinal)
  }
}
