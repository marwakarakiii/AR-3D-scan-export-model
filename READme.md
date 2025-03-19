# 3D Scanner App: Complete Tutorial

This app is a monocular depth-based 3D scanner that reconstructs 3D objects using MiDaS (Monocular Depth Estimation) and Core ML. It captures images, estimates depth, and exports a .ply 3D point cloud.

## Step 1: Understanding MiDaS (Monocular Depth Estimation)

### What is MiDaS?
MiDaS (Monocular Depth Estimation) is an AI model that predicts depth from a single RGB image. Unlike LiDAR, it does not use actual sensor depth but estimates it using deep learning trained on multiple datasets.

### Why MiDaS?
- Works on any phone (no LiDAR required).
- Pre-trained for general scenes (objects, people, landscapes).
- Converts a single 2D image into a 3D depth map.

### Limitations:
- Outputs relative depth, not absolute (it doesn’t know exact distances).
- Requires good lighting and contrast for best results.
- Can struggle with thin objects or glass/transparent surfaces.

## Step 2: How MiDaS Works in This App

### 1. Model Input
MiDaS requires a specific input format:
- **Size**: 256 × 256 pixels (resized from original).
- **Channels**: 3 (RGB).
- **Range**: Pixel values normalized to [0,1] (divided by 255.0).

#### Example Code:
```swift
let shape: [NSNumber] = [1, 3, 256, 256] // (Batch, Channels, Height, Width)
```
This means:
- `1` → batch size (one image at a time).
- `3` → three color channels (Red, Green, Blue).
- `256 × 256` → fixed image size required by MiDaS.

### 2. Model Output
MiDaS produces:
- A single-channel depth map: `1 × 256 × 256`
- Depth values are **relative** (not real-world meters).

#### Output Example:
```swift
let depthMultiArray = prediction.featureValue(for: "var_1847")?.multiArrayValue
```
- `var_1847` → This is the actual model output (can change depending on conversion).
- Converts into a flat depth array that we reshape into `256×256`.

## Step 3: ONNX to Core ML Conversion

### What We Started With: ONNX
ONNX (Open Neural Network Exchange) is a universal model format used for cross-platform machine learning. MiDaS was originally available as an ONNX model.

### Issue:
Core ML does not support ONNX directly, so we converted `ONNX → Core ML` using `coremltools`.

### Core ML Model Formats: `.mlmodel` vs. `.mlpackage`

#### Why `.mlpackage`?
- MiDaS exports as **ML Program** (newer format).
- `.mlpackage` is optimized and runs faster on Apple devices.
- Required for **iOS 15+** (older `.mlmodel` may fail).

## Step 4: Running Depth Estimation in Swift

### 1. Load MiDaS Model
```swift
private lazy var model: MLModel = {
    do {
        let config = MLModelConfiguration()
        guard let modelURL = Bundle.main.url(forResource: "MiDaS", withExtension: "mlmodelc") else {
            fatalError("MiDaS.mlmodelc not found in the app bundle!")
        }
        return try MLModel(contentsOf: modelURL, configuration: config)
    } catch {
        fatalError("Failed to load MiDaS model: \(error\)")
    }
}()
```
- Loads the `MiDaS.mlmodelc` from the app bundle.
- Ensures it is present or throws a fatal error.

### 2. Convert Image to Input Format
```swift
guard let pixelBuffer = image.pixelBuffer(width: 256, height: 256) else { return nil }
```
- Resizes and converts `UIImage → CVPixelBuffer`.
- MiDaS only accepts **256×256 RGB input**.

### 3. Run Depth Estimation
```swift
guard let prediction = try? model.prediction(from: MiDaSInput(x: pixelBuffer)) else {
    print("Failed to make a prediction with MiDaS model")
    return nil
}
let depthMultiArray = prediction.featureValue(for: "var_1847")?.multiArrayValue
```
- Feeds the image into MiDaS.
- Extracts depth from `var_1847`.

### 4. Convert Depth to Float Array
```swift
let (depthValues, width, height) = DepthEstimator.multiArrayToFloatArray(depthMultiArray)
```
- Reshapes the flat depth output back into a `256×256` format.

## Step 5: 3D Unprojection

### 1. Why Unprojection?
- MiDaS gives a depth image (2D).
- We need `(X, Y, Z)` 3D points for `.ply` export.

### 2. How It Works
Each pixel `(i, j)` has a depth value. We convert it into 3D using a simple camera model:
```swift
let X = ((Float(i) - centerX) / focalLength) * depth
let Y = ((Float(j) - centerY) / focalLength) * depth
let Z = depth
```
- `centerX, centerY` → Image center.
- `focalLength` → Approximate focal length (assumed).
- `depth` → Value from MiDaS.

## Step 6: Export `.ply` (Point Cloud)

### 1. Save Depth as `.ply`
```swift
func exportToPLY(points: [(Float, Float, Float)]) -> String {
    var plyData = "ply\nformat ascii 1.0\nelement vertex \(points.count)\n"
    plyData += "property float x\nproperty float y\nproperty float z\nend_header\n"

    for (x, y, z) in points {
        plyData += "\(x) \(y) \(z)\n"
    }
    return plyData
}
```
- `.ply` is a **text-based 3D format**.
- Each point `(X, Y, Z)` is written to the file.

## Debugging & Common Issues

## Summary of What the App Does
- Captures an image from the camera.
- Runs **MiDaS** (monocular depth estimation).
- Extracts depth as a `256×256` float array.
- **Unprojects pixels** into 3D space.
- **Exports the 3D point cloud** as `.ply`.

### This is a complete overview of the app from start to finish. You now understand:
- How **MiDaS** processes images.
- Why we converted `ONNX → Core ML`.
- How depth is used for **3D reconstruction**.
- The **unprojection math** behind it.

### If you need better quality results, consider:
- Taking more pictures from different angles.
- Using a **higher-quality segmentation model** to filter background noise.
