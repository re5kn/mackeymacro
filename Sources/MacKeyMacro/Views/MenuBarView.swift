import MacroCore
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(app.recorder.isRecording ? "記録を停止" : "記録を開始") {
            app.toggleRecording()
        }
        .keyboardShortcut("r", modifiers: [.control, .option, .command])

        if app.player.isPlaying {
            Button("再生を中止") { app.stopPlayback() }
                .keyboardShortcut(".", modifiers: [.control, .option, .command])
        }

        Divider()

        if app.store.macros.isEmpty {
            Text("マクロはまだありません")
        } else {
            ForEach(app.store.macros) { macro in
                Button {
                    app.play(macro.id)
                } label: {
                    if let hotKey = macro.hotKey {
                        Text("▶ \(macro.name)    \(KeyNames.describe(hotKey))")
                    } else {
                        Text("▶ \(macro.name)")
                    }
                }
                .disabled(app.recorder.isRecording || app.player.isPlaying)
            }
        }

        Divider()

        Button("マクロを管理…") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("終了") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
