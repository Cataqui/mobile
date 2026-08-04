import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testWhenApplicationFinishesLaunchingItShouldRetainGoogleMapsServices() {
    let appDelegate = UIApplication.shared.delegate as? AppDelegate

    XCTAssertNotNil(appDelegate?.googleMapsServices)
  }
}
