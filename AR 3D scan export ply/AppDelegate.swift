import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // Called when the app finishes launching
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 1. Create your SwiftUI view
        let tutorialView = TutorialView()
        
        // 2. Wrap it in a UIHostingController
        let hostingController = UIHostingController(rootView: tutorialView)

        // 3. Create the UIWindow and set the rootViewController
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()

        return true
    }
}
