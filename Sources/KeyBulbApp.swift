import SwiftUI

@main
struct KeyBulbApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = KeyModel()

    var body: some Scene {
        // 單一視窗：關掉視窗就結束 App
        Window("電火按鍵", id: "main") {
            KeyView(model: model)
                .onAppear {
                    model.start()
                    SelfTest.runIfRequested(model: model)
                }
        }
        .defaultSize(width: 740, height: 680)
        .windowResizability(.contentMinSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
