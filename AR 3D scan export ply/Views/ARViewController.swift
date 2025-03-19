import UIKit
import ARKit
import SceneKit

class ARViewController: UIViewController, ARSCNViewDelegate {

    private var sceneView = ARSCNView(frame: .zero)
    private var splatData: GaussianSplatData

    init(splatData: GaussianSplatData) {
        self.splatData = splatData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupExportButton()
        addSplatPointCloud()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    func setupSceneView() {
        sceneView.delegate = self
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sceneView)

        // Optionally show feature points, etc.
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.scene = SCNScene()
    }

    func setupExportButton() {
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export 3D Model", for: .normal)
        exportButton.addTarget(self, action: #selector(export3DModel), for: .touchUpInside)
        exportButton.frame = CGRect(x: 20,
                                    y: view.bounds.height - 100,
                                    width: view.bounds.width - 40,
                                    height: 50)
        view.addSubview(exportButton)
    }

    func addSplatPointCloud() {
        // Convert splat data into SCNGeometry or a custom geometry
        // For demonstration, we create a SCNGeometry with points
        let vertexData = createVertexData(from: splatData)
        let vertexSource = SCNGeometrySource(data: vertexData,
                                             semantic: .vertex,
                                             vectorCount: splatData.splats.count,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<Float>.size * 3)

        // Color data
        let colorData = createColorData(from: splatData)
        let colorSource = SCNGeometrySource(data: colorData,
                                            semantic: .color,
                                            vectorCount: splatData.splats.count,
                                            usesFloatComponents: true,
                                            componentsPerVector: 3,
                                            bytesPerComponent: MemoryLayout<Float>.size,
                                            dataOffset: 0,
                                            dataStride: MemoryLayout<Float>.size * 3)

        // We have one element describing how points are connected
        // But for point cloud, each vertex is its own point
        let indices = (0..<splatData.splats.count).map { Int32($0) }
        let indexData = Data(bytes: indices, count: MemoryLayout<Int32>.size * indices.count)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .point,
                                         primitiveCount: splatData.splats.count,
                                         bytesPerIndex: MemoryLayout<Int32>.size)

        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])

        // SceneKit can do point-size in a geometry shader, or we can force a bigger point size:
        geometry.firstMaterial = SCNMaterial()
        geometry.firstMaterial?.lightingModel = .constant
        geometry.firstMaterial?.isDoubleSided = true
        // For advanced control, we'd use a custom SCNProgram with a Metal geometry shader.

        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(0, 0, -1.0) // Place 1 meter in front of camera for demonstration
        sceneView.scene.rootNode.addChildNode(node)
    }

    func createVertexData(from splats: GaussianSplatData) -> Data {
        var data = Data()
        for s in splats.splats {
            var x = s.position.x
            var y = s.position.y
            var z = s.position.z
            data.append(UnsafeBufferPointer(start: &x, count: 1))
            data.append(UnsafeBufferPointer(start: &y, count: 1))
            data.append(UnsafeBufferPointer(start: &z, count: 1))
        }
        return data
    }

    func createColorData(from splats: GaussianSplatData) -> Data {
        var data = Data()
        for s in splats.splats {
            var r = s.color.x
            var g = s.color.y
            var b = s.color.z
            data.append(UnsafeBufferPointer(start: &r, count: 1))
            data.append(UnsafeBufferPointer(start: &g, count: 1))
            data.append(UnsafeBufferPointer(start: &b, count: 1))
        }
        return data
    }

    @objc func export3DModel() {
        // Show some action sheet or directly call exporter
        let exporter = Exporter()
        exporter.export(splatData: splatData, format: .ply) { url in
            // Show share sheet or handle the exported file
            guard let fileUrl = url else { return }
            let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
    }
}
