import SwiftUI

@main
struct MyMusicApp: App {
    // Add the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
