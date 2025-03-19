import Foundation
import CoreML
import UIKit

/// A manual MLFeatureProvider for MiDaS, so we can feed an MLMultiArray without collisions.
class MiDaSFeatureInput: MLFeatureProvider {
    var featureNames: Set<String> { ["x"] }
    private let inputTensor: MLMultiArray

    init(tensor: MLMultiArray) {
        self.inputTensor = tensor
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        guard featureName == "x" else { return nil }
        return MLFeatureValue(multiArray: inputTensor)
    }
}

/// The depth estimator that loads `MiDaS.mlmodelc` from the app bundle.
class DepthEstimator {

    /// 1) Load the `.mlmodelc` manually as an `MLModel` (no auto‐generated classes).
    private lazy var miDaSModel: MLModel = {
        // Example: we look for "MiDaS.mlmodelc" in the app bundle
        let modelName = "MiDaS"  // Adjust if your compiled model is named differently
        let modelExtension = "mlmodelc"

        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: modelExtension) else {
            fatalError("❌ Could not find \(modelName).\(modelExtension) in the app bundle!")
        }
        do {
            return try MLModel(contentsOf: modelURL)
        } catch {
            fatalError("❌ Failed to load MiDaS model: \(error)")
        }
    }()

    init() {
        // Nothing special
    }

    // MARK: - Public Method to Estimate Depth
    /// Returns (depthValues, width, height) or nil on failure
    func estimateDepth(from uiImage: UIImage) -> ([Float], Int, Int)? {
        // 1. Convert UIImage → CGImage
        guard let cgImage = uiImage.cgImage else {
            print("❌ Unable to get CGImage from UIImage.")
            return nil
        }

        // 2. Convert CGImage → CVPixelBuffer
        guard let pixelBuffer = cgImage.toPixelBuffer() else {
            print("❌ Failed to convert CGImage to CVPixelBuffer.")
            return nil
        }

        // 3. Convert CVPixelBuffer → MLMultiArray (1×3×256×256)
        guard let mlMultiArray = pixelBufferToMultiArray(pixelBuffer) else {
            print("❌ Failed to convert CVPixelBuffer to MLMultiArray.")
            return nil
        }

        // 4. Wrap MLMultiArray in our MiDaSFeatureInput
        let input = MiDaSFeatureInput(tensor: mlMultiArray)

        // 5. Run prediction via `MLModel.prediction(from:)`
        guard let output = try? miDaSModel.prediction(from: input) else {
            print("❌ MiDaS prediction failed.")
            return nil
        }

        // 6. Extract the depth multi-array from the output dictionary
        //    You must match the actual output key from your model. If it's "var_1847", etc.
        guard let depthArray = output.featureValue(for: "var_1847")?.multiArrayValue else {
            print("❌ Depth output (var_1847) not found in the model output.")
            return nil
        }

        // 7. Convert MLMultiArray → [Float] + width + height
        let (depthValues, w, h) = multiArrayToFloatArray(depthArray)

        // Optional: visualize the depth map (comment out if you don’t need debug)
        debugDepthMap(depthValues: depthValues, width: w, height: h)

        print("✅ Depth estimated. Size: \(w)x\(h)")
        return (depthValues, w, h)
    }

    // MARK: - Private Helper: Convert CVPixelBuffer → MLMultiArray
    private func pixelBufferToMultiArray(_ pixelBuffer: CVPixelBuffer) -> MLMultiArray? {
        do {
            let shape: [NSNumber] = [1, 3, 256, 256] // (batch, channels, height, width)
            let array = try MLMultiArray(shape: shape, dataType: .float32)

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
            let w = CVPixelBufferGetWidth(pixelBuffer)
            let h = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

            let floatPtr = array.dataPointer.bindMemory(to: Float.self, capacity: 3 * 256 * 256)

            for y in 0..<h {
                let rowPtr = baseAddress.advanced(by: y * bytesPerRow)
                for x in 0..<w {
                    let offset = y * w + x
                    let pixel = rowPtr.load(fromByteOffset: x * 4, as: UInt32.self)

                    // Extract ARGB → RGB (normalize 0..1)
                    let r = Float((pixel >> 16) & 0xFF) / 255.0
                    let g = Float((pixel >> 8) & 0xFF) / 255.0
                    let b = Float((pixel) & 0xFF) / 255.0

                    // Fill the MLMultiArray (channel-major) [batch=1, channels=3, height=256, width=256]
                    floatPtr[offset] = r
                    floatPtr[256 * 256 + offset] = g
                    floatPtr[2 * 256 * 256 + offset] = b
                }
            }

            return array
        } catch {
            print("❌ Error creating MLMultiArray: \(error)")
            return nil
        }
    }

    // MARK: - Private Helper: Convert MLMultiArray → ([Float], width, height)
    private func multiArrayToFloatArray(_ array: MLMultiArray) -> ([Float], Int, Int) {
        // The shape is [1, 256, 256] => or sometimes [1, h, w]
        // or [1, height, width]. Adjust if needed.
        // Check your MiDaS model's actual output shape.
        let batch = array.shape[0].intValue  // typically 1
        let height = array.shape[1].intValue
        let width  = array.shape[2].intValue

        var floats: [Float] = []
        floats.reserveCapacity(width * height)

        for hIndex in 0..<height {
            for wIndex in 0..<width {
                let idx = hIndex * width + wIndex
                floats.append(Float(truncating: array[idx]))
            }
        }
        print("Depth output shape: [\(batch), \(height), \(width)] => \(floats.count) floats")
        return (floats, width, height)
    }

    // MARK: - Private Helper: Debug Visualization of Depth
    private func debugDepthMap(depthValues: [Float], width: Int, height: Int) {
        guard let minVal = depthValues.min(),
              let maxVal = depthValues.max() else { return }

        var pixels = [UInt8](repeating: 0, count: width * height)
        for i in 0..<depthValues.count {
            let normalized = UInt8(((depthValues[i] - minVal) / (maxVal - minVal)) * 255)
            pixels[i] = normalized
        }

        guard let depthImage = UIImage.fromGrayscaleArray(pixels, width: width, height: height) else { return }

        DispatchQueue.main.async {
            let debugView = UIImageView(image: depthImage)
            debugView.frame = UIScreen.main.bounds
            debugView.contentMode = .scaleAspectFit
            UIApplication.shared.windows.first?.addSubview(debugView)
            print("✅ Depth map debug overlay displayed.")
        }
    }
}
