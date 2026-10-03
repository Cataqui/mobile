import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testWhenApplicationLaunchesItShouldRegisterTheFlutterAppDelegate() {
    XCTAssertTrue(UIApplication.shared.delegate is AppDelegate)
  }
}
