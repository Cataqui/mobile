import CoreVideo
import Flutter
import Foundation

final class JobMapTexture: NSObject, FlutterTexture {
  private let lock = NSLock()
  private var pixelBuffer: CVPixelBuffer?

  func update(with pixelBuffer: CVPixelBuffer) {
    lock.lock()
    self.pixelBuffer = pixelBuffer
    lock.unlock()
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    lock.lock()
    let pixelBuffer = self.pixelBuffer
    lock.unlock()
    guard let pixelBuffer else { return nil }
    return Unmanaged.passRetained(pixelBuffer)
  }
}
