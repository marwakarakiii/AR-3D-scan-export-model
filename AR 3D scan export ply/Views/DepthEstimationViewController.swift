import UIKit

class DepthEstimationViewController: UIViewController {
    private var images: [UIImage]
    private let depthEstimator = DepthEstimator()  // Our wrapper around MiDaS model

    init(images: [UIImage]) {
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        processDepthForImages()
    }

    private func processDepthForImages() {
        // Could show a loading spinner, etc.
        var depthMaps: [[Float]] = []
        var width: Int = 0
        var height: Int = 0

        for img in images {
            guard let (depthMap, w, h) = depthEstimator.estimateDepth(from: img) else {
                continue
            }
            depthMaps.append(depthMap)
            width = w
            height = h
        }

        // Now we have depth maps for each image
        // Convert them into Gaussian splats
        let splatProcessor = GaussianSplatProcessor()
        splatProcessor.process(images: images, depthMaps: depthMaps, width: width, height: height) { splatData in
            // Once we have the splat/point data, move to AR
            DispatchQueue.main.async {
                let arVC = ARViewController(splatData: splatData)
                self.navigationController?.pushViewController(arVC, animated: true)
            }
        }
    }
}
