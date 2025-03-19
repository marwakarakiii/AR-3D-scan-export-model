import SwiftUI
import CoreML

struct TutorialView: View {
    @State private var modelLoaded: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {  // ✅ Ensure NavigationView is present
            VStack(spacing: 20) {
                Text("Gaussian Splatting 3D Scanner")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()

                Text("Since your device lacks LiDAR, we will use Gaussian Splatting to reconstruct 3D objects from images.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()

                if let error = errorMessage {
                    Text("❌ Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if modelLoaded {
                    Text("✅ MiDaS Model Loaded Successfully!")
                        .foregroundColor(.green)
                        .padding()
                } else {
                    Text("⏳ Loading MiDaS Model...")
                        .foregroundColor(.gray)
                        .padding()
                }

                NavigationLink(destination: CaptureViewControllerRepresentable()) {
                    Text("Start Scanning")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .onAppear {
                loadMiDaSModel()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }

    /// ✅ Loads the MiDaS Model
    private func loadMiDaSModel() {
        let possibleExtensions = ["mlpackage", "mlmodelc"]
        var modelURL: URL? = nil

        for ext in possibleExtensions {
            if let url = Bundle.main.url(forResource: "MiDaS", withExtension: ext) {
                modelURL = url
                print("✅ Found MiDaS model: \(url)")
                break
            }
        }

        guard let finalModelURL = modelURL else {
            errorMessage = "MiDaS model file not found in the app bundle!"
            print("❌ MiDaS model file not found!")
            return
        }

        do {
            let config = MLModelConfiguration()
            let _ = try MLModel(contentsOf: finalModelURL, configuration: config)
            modelLoaded = true
        } catch {
            errorMessage = "Failed to load MiDaS model: \(error.localizedDescription)"
            print("❌ Failed to load MiDaS model: \(error)")
        }
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}
