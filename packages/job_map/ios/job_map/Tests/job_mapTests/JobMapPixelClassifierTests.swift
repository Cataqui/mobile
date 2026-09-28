import CoreVideo
import XCTest
@testable import job_map

final class JobMapPixelClassifierTests: XCTestCase {
  func testWhenOnlyAttributionIsVisibleItRejectsTheFrame() throws {
    let frame = makeFrame(roadsOnRight: false)
    let analysis = try XCTUnwrap(JobMapPixelClassifier.analyze(frame, includesCenter: true))

    XCTAssertFalse(analysis.hasDetail)
  }

  func testWhenNewRoadsAppearOnTheRightItAcceptsPartialGooglePixels() throws {
    let blank = try XCTUnwrap(JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: false), includesCenter: true))
    let partial = try XCTUnwrap(JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: true), includesCenter: true))

    XCTAssertTrue(partial.hasDetail)
    XCTAssertTrue(JobMapPixelClassifier.hasChangedMapDetail(from: blank, to: partial))
  }

  func testWhenPixelsHaveNotChangedItRejectsTheOldLocation() throws {
    let old = try XCTUnwrap(JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: true), includesCenter: true))
    let unchanged = try XCTUnwrap(JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: true), includesCenter: true))

    XCTAssertFalse(JobMapPixelClassifier.hasChangedMapDetail(from: old, to: unchanged))
  }

  func testWhenSparseRoadsMoveToANewLocationItDetectsTheChange() throws {
    let old = try XCTUnwrap(JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: false, roadsOnLeft: true), includesCenter: true))
    let new = try XCTUnwrap(JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: true), includesCenter: true))

    XCTAssertTrue(old.hasDetail)
    XCTAssertTrue(new.hasDetail)
    XCTAssertTrue(JobMapPixelClassifier.hasChangedMapDetail(from: old, to: new))
  }

  func testWhenOnlyNativeCircleIsVisibleItRejectsTheFrame() throws {
    let analysis = try XCTUnwrap(JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: false, circleOnly: true), includesCenter: false))

    XCTAssertFalse(analysis.hasDetail)
  }

  func testDetailOnlyClassificationMatchesRetainedRoadSamples() {
    let frame = makeFrame(roadsOnRight: true)
    let retained = JobMapPixelClassifier.analyze(frame, includesCenter: true)
    let detailOnly = JobMapPixelClassifier.analyze(
      frame, includesCenter: true, retainSamples: false)

    XCTAssertEqual([retained?.hasDetail, detailOnly?.hasDetail, detailOnly?.samples.isEmpty], [true, true, true])
  }

  func testDetailOnlyClassificationStillRejectsBlankMapWithAttribution() {
    let frame = makeFrame(roadsOnRight: false)
    let retained = JobMapPixelClassifier.analyze(frame, includesCenter: true)
    let detailOnly = JobMapPixelClassifier.analyze(
      frame, includesCenter: true, retainSamples: false)

    XCTAssertEqual([retained?.hasDetail, detailOnly?.hasDetail, detailOnly?.samples.isEmpty], [false, false, true])
  }

  func testDetailOnlyClassificationStillRejectsNativeCircleWithoutTiles() {
    let frame = makeFrame(roadsOnRight: false, circleOnly: true)
    let retained = JobMapPixelClassifier.analyze(frame, includesCenter: false)
    let detailOnly = JobMapPixelClassifier.analyze(
      frame, includesCenter: false, retainSamples: false)

    XCTAssertEqual([retained?.hasDetail, detailOnly?.hasDetail, detailOnly?.samples.isEmpty], [false, false, true])
  }

  func testMissingSamplesCannotClaimChangedMapDetail() {
    let old = JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: false, roadsOnLeft: true), includesCenter: true)!
    let noSamples = JobMapPixelClassifier.analyze(
      makeFrame(roadsOnRight: true), includesCenter: true, retainSamples: false)!

    XCTAssertFalse(JobMapPixelClassifier.hasChangedMapDetail(from: old, to: noSamples))
  }

  private func makeFrame(
    roadsOnRight: Bool,
    roadsOnLeft: Bool = false,
    circleOnly: Bool = false
  ) -> CVPixelBuffer {
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault, 280, 320, kCVPixelFormatType_32BGRA,
      [kCVPixelBufferCGImageCompatibilityKey: true] as CFDictionary,
      &pixelBuffer)
    XCTAssertEqual(status, kCVReturnSuccess)
    let frame = pixelBuffer!
    CVPixelBufferLockBaseAddress(frame, [])
    defer { CVPixelBufferUnlockBaseAddress(frame, []) }
    let pixels = CVPixelBufferGetBaseAddress(frame)!.assumingMemoryBound(to: UInt8.self)
    let rowBytes = CVPixelBufferGetBytesPerRow(frame)

    for y in 0..<320 {
      for x in 0..<280 {
        let offset = y * rowBytes + x * 4
        let road = ((roadsOnRight && x >= 140) || (roadsOnLeft && x < 140))
          && y < 284 && (x % 60 == 8 || y % 90 == 8)
        let circle = circleOnly && (x - 140) * (x - 140) + (y - 160) * (y - 160) < 35 * 35
        let attribution = y >= 294 && x < 40 && (x % 5 == 0 || y % 5 == 0)
        pixels[offset] = road ? 218 : circle ? 45 : attribution ? 32 : 245
        pixels[offset + 1] = road ? 227 : circle ? 45 : attribution ? 32 : 243
        pixels[offset + 2] = road ? 235 : circle ? 45 : attribution ? 32 : 241
        pixels[offset + 3] = 255
      }
    }
    return frame
  }
}
