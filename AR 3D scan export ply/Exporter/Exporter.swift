import Foundation
import SceneKit
import QuickLook // for possible .usdz usage

enum ExportFormat {
    case ply
    case obj
    case usdz
}

class Exporter {

    func export(splatData: GaussianSplatData, format: ExportFormat, completion: @escaping (URL?) -> Void) {
        switch format {
        case .ply:
            completion(exportAsPLY(splatData: splatData))
        case .obj:
            completion(exportAsOBJ(splatData: splatData))
        case .usdz:
            // You can create a SCNScene from the splats, then use SCNScene.write(to:options:delegate:progressHandler:)
            completion(exportAsUSDZ(splatData: splatData))
        }
    }

    private func exportAsPLY(splatData: GaussianSplatData) -> URL? {
        // PLY header
        var plyText = """
        ply
        format ascii 1.0
        element vertex \(splatData.splats.count)
        property float x
        property float y
        property float z
        property uchar red
        property uchar green
        property uchar blue
        end_header
        """

        // For each splat, write a line
        for s in splatData.splats {
            let r = Int(s.color.x * 255)
            let g = Int(s.color.y * 255)
            let b = Int(s.color.z * 255)
            plyText += "\n\(s.position.x) \(s.position.y) \(s.position.z) \(r) \(g) \(b)"
        }

        // Save to temporary folder
        let fileName = "ExportedModel.ply"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try plyText.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write PLY file: \(error)")
            return nil
        }
    }

    private func exportAsOBJ(splatData: GaussianSplatData) -> URL? {
        var objText = ""
        // v x y z
        for s in splatData.splats {
            objText += "v \(s.position.x) \(s.position.y) \(s.position.z)\n"
        }
        // Save
        let fileName = "ExportedModel.obj"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try objText.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write OBJ file: \(error)")
            return nil
        }
    }

    private func exportAsUSDZ(splatData: GaussianSplatData) -> URL? {
        // 1) Create a SCNScene from point data
        // 2) Use SceneKit’s write(to:options:delegate:progressHandler:) with
        //    .usdz (iOS 14+). This can be tricky with pure points, so a mesh approach might be required.
        // Example code (simplified):
        let scene = SCNScene()

        // Build geometry from splat data
        // Re-use logic from ARViewController if needed
        let node = SCNNode()
        scene.rootNode.addChildNode(node)

        let fileName = "ExportedModel.usdz"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try scene.write(to: tempURL, options: nil, delegate: nil, progressHandler: nil)
            return tempURL
        } catch {
            print("USDZ export failed: \(error)")
            return nil
        }
    }
}
