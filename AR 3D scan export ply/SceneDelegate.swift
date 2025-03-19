import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        
        // If you’re using SwiftUI for the tutorial:
        let tutorialView = TutorialView()
        window.rootViewController = UIHostingController(rootView: tutorialView)
        
        // If using UIKit for the tutorial:
        // window.rootViewController = TutorialViewController()

        self.window = window
        window.makeKeyAndVisible()
    }
}
