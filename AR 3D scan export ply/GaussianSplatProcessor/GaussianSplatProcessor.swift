import Foundation
import UIKit
import simd

struct GaussianSplat {
    var position: simd_float3   // x, y, z
    var color: simd_float3      // r, g, b
    var radius: Float           // Splat size
}

struct GaussianSplatData {
    var splats: [GaussianSplat]
    // Possibly store metadata, bounding box, etc.
}

class GaussianSplatProcessor {

    // Callback with the final splat data
    func process(images: [UIImage],
                 depthMaps: [[Float]],
                 width: Int,
                 height: Int,
                 completion: @escaping (GaussianSplatData) -> Void) {

        // In a real app, we'd have camera intrinsics for better unprojection
        // Here we do a naive approach

        var allSplats: [GaussianSplat] = []

        for (index, image) in images.enumerated() {
            let depthMap = depthMaps[index]
            guard let cgImage = image.cgImage else { continue }

            // Convert the image to raw RGBA for color sampling
            let colorData = cgImage.toRGBA8Bytes() // see extension below

            for y in 0..<height {
                for x in 0..<width {
                    let depthVal = depthMap[y * width + x]
                    // Skip invalid or zero depth (some thresholds needed)
                    if depthVal <= 0.0 { continue }

                    // Unproject (x, y, depthVal) to 3D - naive approach
                    let X = (Float(x) / Float(width)  - 0.5) * 2.0
                    let Y = (Float(y) / Float(height) - 0.5) * 2.0
                    let Z = depthVal * 1.0 // scale or transform as needed

                    // Sample color
                    let (r, g, b) = colorData.sampleColor(x: x, y: y, width: width)

                    // Create splat
                    let splat = GaussianSplat(position: simd_float3(X, Y, Z),
                                              color: simd_float3(r, g, b),
                                              radius: 0.01)
                    allSplats.append(splat)
                }
            }
        }

        let splatData = GaussianSplatData(splats: allSplats)
        completion(splatData)
    }
}

// Helper for extracting RGBA from a CGImage
extension CGImage {
    func toRGBA8Bytes() -> [UInt8] {
        let width = self.width
        let height = self.height
        let count = width * height * 4
        var pixels = [UInt8](repeating: 0, count: count)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixels,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: width * 4,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
}

extension Array where Element == UInt8 {
    /// Returns color in [0,1] range
    func sampleColor(x: Int, y: Int, width: Int) -> (Float, Float, Float) {
        let offset = ((y * width) + x) * 4
        if offset+2 < count {
            let r = Float(self[offset + 0]) / 255.0
            let g = Float(self[offset + 1]) / 255.0
            let b = Float(self[offset + 2]) / 255.0
            return (r, g, b)
        } else {
            return (0, 0, 0)
        }
    }
}
