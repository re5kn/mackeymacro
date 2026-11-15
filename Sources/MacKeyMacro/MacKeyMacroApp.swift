import AppKit
import SwiftUI

@main
struct MacKeyMacroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var app = AppState()

    var body: some Scene {
        WindowGroup("MacKeyMacro", id: "main") {
            ContentView()
                .environmentObject(app)
                .frame(minWidth: 720, minHeight: 440)
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(app)
        } label: {
            Image(systemName: app.recorder.isRecording ? "record.circle.fill" : "keyboard")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // `swift run` で起動したときも Dock とウインドウが出るようにする
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // ウインドウを閉じてもメニューバーとショートカットは動き続ける
        false
    }
}
