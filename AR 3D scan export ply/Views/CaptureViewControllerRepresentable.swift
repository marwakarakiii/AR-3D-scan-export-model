import SwiftUI
import UIKit

struct CaptureViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CaptureViewController {
        return CaptureViewController()
    }

    func updateUIViewController(_ uiViewController: CaptureViewController, context: Context) {}
}
