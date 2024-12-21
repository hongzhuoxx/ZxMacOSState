import SwiftUI

@main
struct ZxMachineStateApp: App {
    // 使用 @NSApplicationDelegateAdaptor 来适配 AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
