import MacroCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                PermissionBanner()
                if let message = app.message {
                    HStack {
                        Text(message).font(.callout)
                        Spacer()
                        Button {
                            app.message = nil
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.bar)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    app.toggleRecording()
                } label: {
                    Label(
                        app.recorder.isRecording ? "記録を停止" : "記録を開始",
                        systemImage: app.recorder.isRecording ? "stop.circle.fill" : "record.circle"
                    )
                }
                .help("⌃⌥⌘R でも開始・停止できます")
                .tint(app.recorder.isRecording ? .red : nil)

                if app.player.isPlaying {
                    Button {
                        app.stopPlayback()
                    } label: {
                        Label("再生を中止", systemImage: "stop.fill")
                    }
                    .help("⌃⌥⌘. でも中止できます")
                }
            }
        }
    }

    private var sidebar: some View {
        List(selection: $app.selection) {
            if app.recorder.isRecording {
                Label("記録中… \(app.recorder.events.count) イベント", systemImage: "record.circle.fill")
                    .foregroundStyle(.red)
            }
            ForEach(app.store.macros) { macro in
                VStack(alignment: .leading, spacing: 2) {
                    Text(macro.name)
                    HStack(spacing: 6) {
                        if let hotKey = macro.hotKey {
                            Text(KeyNames.describe(hotKey))
                                .foregroundStyle(app.failedHotKeyMacroIDs.contains(macro.id) ? .red : .secondary)
                        }
                        Text("\(macro.events.count) イベント")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
                .tag(macro.id)
                .contextMenu {
                    Button("再生") { app.play(macro.id) }
                    Button("削除", role: .destructive) { app.delete(macro.id) }
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 240)
    }

    @ViewBuilder
    private var detail: some View {
        if let id = app.selection, let index = app.store.macros.firstIndex(where: { $0.id == id }) {
            MacroDetailView(macro: Binding(
                get: { app.store.macros.indices.contains(index) ? app.store.macros[index] : Macro(name: "", events: []) },
                set: { newValue in
                    if let i = app.store.macros.firstIndex(where: { $0.id == newValue.id }) {
                        app.store.macros[i] = newValue
                    }
                }
            ))
            .id(id)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("「記録を開始」を押して、対象のアプリでキーを操作してください。")
                Text("⌃⌥⌘R で記録の開始・停止、⌃⌥⌘. で再生の中止ができます。")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

/// 権限が足りないときに上部に出すバナー
private struct PermissionBanner: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        if !app.canListen || !app.canPost {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    if !app.canListen { Text("記録には「入力監視」の許可が必要です") }
                    if !app.canPost { Text("再生には「アクセシビリティ」の許可が必要です") }
                }
                .font(.callout)
                Spacer()
                if !app.canListen { Button("入力監視を許可…") { Permissions.requestListen() } }
                if !app.canPost { Button("アクセシビリティを許可…") { Permissions.requestPost() } }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.yellow.opacity(0.15))
        }
    }
}
