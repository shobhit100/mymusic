import UIKit
import SwiftUI

// Define a custom notification name
extension NSNotification.Name {
    static let savePlaybackState = NSNotification.Name("SavePlaybackStateNotification")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillResignActive(_ application: UIApplication) {
        // Save playback state when the app is about to resign active (e.g., when the app is closed)
        NotificationCenter.default.post(name: .savePlaybackState, object: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Save playback state when the app is about to terminate
        NotificationCenter.default.post(name: .savePlaybackState, object: nil)
    }
}
