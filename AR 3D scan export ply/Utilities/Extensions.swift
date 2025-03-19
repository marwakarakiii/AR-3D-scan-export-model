import UIKit
import CoreVideo

extension CGImage {
    func toPixelBuffer() -> CVPixelBuffer? {
        // Force a 256x256 resize to match the model shape
        guard let resized = self.resizedTo(width: 256, height: 256) else {
            print("❌ Failed to resize CGImage to 256x256.")
            return nil
        }

        let w = 256
        let h = 256

        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, w, h,
                            kCVPixelFormatType_32ARGB,
                            attrs as CFDictionary, &pb)
        guard let pixelBuffer = pb else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                  width: w,
                                  height: h,
                                  bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        else { return nil }

        // Now draw the *resized* 256x256 CGImage
        ctx.draw(resized, in: CGRect(x: 0, y: 0, width: w, height: h))
        return pixelBuffer
    }

    func resizedTo(width targetWidth: Int, height targetHeight: Int) -> CGImage? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        context.draw(self, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        return context.makeImage()
    }
}

extension UIImage {
    /// 📌 Convert a grayscale pixel array into a `UIImage`
    static func fromGrayscaleArray(_ pixelData: [UInt8], width: Int, height: Int) -> UIImage? {
        guard pixelData.count == width * height else { return nil }

        let bitsPerComponent = 8
        let bytesPerRow = width
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        guard let provider = CGDataProvider(data: Data(pixelData) as CFData),
              let cgImage = CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bitsPerPixel: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo,
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
