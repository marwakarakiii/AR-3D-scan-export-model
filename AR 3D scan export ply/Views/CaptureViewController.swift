import UIKit
import AVFoundation

class CaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private var capturedImages: [UIImage] = []
    
    // We'll store a reference to the button
    private var captureButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Failed to access camera.")
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        // previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds

        DispatchQueue.main.async {
            self.view.layer.insertSublayer(self.previewLayer, at: 0)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }

        print("✅ Camera setup complete.")
    }

    func setupUI() {
        // Keep a reference in the property
        captureButton = UIButton(type: .system)
        captureButton.setTitle("Capture Image", for: .normal)
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        captureButton.backgroundColor = UIColor.blue
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        captureButton.layer.cornerRadius = 10
        captureButton.clipsToBounds = true

        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 200),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        print("✅ Capture button added to view!")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    @objc func capturePhoto() {
        // 1) Prevent spamming by disabling the button
        captureButton.isEnabled = false

        print("📸 Capture button tapped!")
        guard let photoOutput = photoOutput else {
            print("❌ photoOutput is nil")
            captureButton.isEnabled = true // Re-enable on failure
            return
        }

        // 2) Configure your photo settings
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        // 3) Re-enable the button so user can tap again
        defer { captureButton.isEnabled = true }

        if let error = error {
            print("❌ Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else {
            print("❌ Failed to convert photo data to UIImage.")
            return
        }

        capturedImages.append(uiImage)
        print("✅ Photo captured! Total images stored: \(capturedImages.count)")

        // If you only want 10 images total:
        if capturedImages.count >= 10 {
            goToDepthEstimation()
        }
    }

    func goToDepthEstimation() {
        print("🚀 Navigating to Depth Estimation Screen!")
        // If you REALLY only want 10 images, consider disabling the button here.
        // captureButton.isEnabled = false

        DispatchQueue.main.async {
            let depthVC = DepthEstimationViewController(images: self.capturedImages)
            self.navigationController?.pushViewController(depthVC, animated: true)
        }
    }
}
