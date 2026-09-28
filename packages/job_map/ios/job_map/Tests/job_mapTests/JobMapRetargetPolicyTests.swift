import XCTest
@testable import job_map

final class JobMapRetargetPolicyTests: XCTestCase {
  func testPublishedSdkRemainsWarmAfterAnUnpublishedReplacementIsSuperseded() {
    let policy = JobMapRetargetPolicy()
    policy.markFramePublished() // A published a real texture.
    let replaceAWithB = policy.shouldCreateFreshView(cameraChanged: true)
    // B is superseded before publishing. The SDK-warmed state belongs to the bridge.
    let replaceUnpublishedBWithC = policy.shouldCreateFreshView(cameraChanged: true)

    XCTAssertEqual([replaceAWithB, replaceUnpublishedBWithC], [true, true])
  }

  func testSameNativeCameraReusesWarmedRenderer() {
    let policy = JobMapRetargetPolicy()
    policy.markFramePublished()

    XCTAssertFalse(policy.shouldCreateFreshView(cameraChanged: false))
  }

  func testInitialViewUsesColdProbeSchedule() {
    let policy = JobMapRetargetPolicy()

    XCTAssertEqual(
      Array(policy.earlyProbeDelays(isNewView: true, hasRetargetSignature: false).prefix(3)),
      [0.1, 0.4, 0.65])
  }

  func testNewViewAfterPublicationProbesAt100And200Milliseconds() {
    let policy = JobMapRetargetPolicy()
    policy.markFramePublished()

    XCTAssertEqual(
      Array(policy.earlyProbeDelays(isNewView: true, hasRetargetSignature: false).prefix(3)),
      [0.1, 0.2, 0.4])
  }

  func testResetReturnsToColdRetargetDecision() {
    let policy = JobMapRetargetPolicy()
    policy.markFramePublished()
    policy.reset()

    XCTAssertFalse(policy.shouldCreateFreshView(cameraChanged: true))
  }

  func testResetReturnsToColdProbeSchedule() {
    let policy = JobMapRetargetPolicy()
    policy.markFramePublished()
    policy.reset()

    XCTAssertEqual(
      Array(policy.earlyProbeDelays(isNewView: true, hasRetargetSignature: false).prefix(2)),
      [0.1, 0.4])
  }
}
