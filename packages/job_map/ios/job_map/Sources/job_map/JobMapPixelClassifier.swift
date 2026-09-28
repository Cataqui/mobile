import CoreVideo

final class JobMapPixelClassifier {
  static let minimumDimensionPx = 48

  struct Analysis {
    let widthPx: Int
    let heightPx: Int
    let includesCenter: Bool
    let samples: [UInt32]
    let hasDetail: Bool
  }

  static func analyze(
    _ pixelBuffer: CVPixelBuffer,
    includesCenter: Bool,
    retainSamples: Bool = true
  ) -> Analysis? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    guard width >= minimumDimensionPx, height >= minimumDimensionPx else { return nil }
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
    let pixels = baseAddress.assumingMemoryBound(to: UInt8.self)
    let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let reference = 8 * rowBytes + 8 * 4
    let referenceBlue = Int(pixels[reference])
    let referenceGreen = Int(pixels[reference + 1])
    let referenceRed = Int(pixels[reference + 2])
    var samples: [UInt32] = []
    var sampleCount = 0
    var changed = 0
    var edges = 0

    func sampleRegion(xStart: Int, xEnd: Int, yStart: Int, yEnd: Int) {
      for y in stride(from: yStart, to: yEnd, by: 3) {
        for x in stride(from: xStart, to: xEnd, by: 3) {
          let offset = y * rowBytes + x * 4
          let previous = offset - 3 * 4
          let blue = Int(pixels[offset])
          let green = Int(pixels[offset + 1])
          let red = Int(pixels[offset + 2])
          sampleCount += 1
          if retainSamples {
            samples.append(
              UInt32(blue) | (UInt32(green) << 8) | (UInt32(red) << 16))
          }
          if abs(blue - referenceBlue) + abs(green - referenceGreen)
            + abs(red - referenceRed) > 36 {
            changed += 1
          }
          if abs(blue - Int(pixels[previous]))
            + abs(green - Int(pixels[previous + 1]))
            + abs(red - Int(pixels[previous + 2])) > 42 {
            edges += 1
          }
        }
      }
    }

    if includesCenter {
      // Radius-zero scenes draw their annotation in Flutter. Ignore only the SDK logo band.
      sampleRegion(xStart: 8, xEnd: width - 8, yStart: 8, yEnd: height - 36)
    } else {
      // A native circle can create false detail at the center of an empty map.
      sampleRegion(xStart: 8, xEnd: width - 8, yStart: 8, yEnd: height / 4)
      sampleRegion(
        xStart: width * 3 / 4, xEnd: width - 8,
        yStart: height / 4, yEnd: height * 3 / 4)
    }

    let threshold = includesCenter ? 2 : 8
    return Analysis(
      widthPx: width,
      heightPx: height,
      includesCenter: includesCenter,
      samples: samples,
      hasDetail: sampleCount > 0
        && changed * 100 >= sampleCount * threshold
        && edges * 1000 >= sampleCount * 20)
  }

  static func hasChangedMapDetail(from previous: Analysis, to current: Analysis) -> Bool {
    guard previous.widthPx == current.widthPx,
      previous.heightPx == current.heightPx,
      previous.includesCenter == current.includesCenter,
      previous.samples.count == current.samples.count,
      !previous.samples.isEmpty
    else { return false }
    var changed = 0
    for (old, new) in zip(previous.samples, current.samples) {
      let difference = abs(Int(old & 0xff) - Int(new & 0xff))
        + abs(Int((old >> 8) & 0xff) - Int((new >> 8) & 0xff))
        + abs(Int((old >> 16) & 0xff) - Int((new >> 16) & 0xff))
      if difference > 36 { changed += 1 }
    }
    return changed * 100 >= previous.samples.count * 2
  }
}
