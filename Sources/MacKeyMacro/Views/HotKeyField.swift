import AppKit
import Carbon
import MacroCore
import SwiftUI

/// クリックしてからキーを押すと、そのキーの組み合わせをショートカットとして設定する。
/// Esc でキャンセル、Delete で解除。⌃⌥⌘ のいずれかを含む必要がある。
struct HotKeyField: View {
    @Binding var hotKey: HotKey?
    @State private var isCapturing = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggleCapture) {
                Text(label)
                    .frame(minWidth: 140)
            }
            .buttonStyle(.bordered)
            .tint(isCapturing ? .accentColor : nil)

            if hotKey != nil && !isCapturing {
                Button("解除") { hotKey = nil }
                    .buttonStyle(.borderless)
            }
        }
        .onDisappear(perform: stopCapture)
    }

    private var label: String {
        if isCapturing { return "キーを押してください…" }
        if let hotKey { return KeyNames.describe(hotKey) }
        return "ショートカットを設定"
    }

    private func toggleCapture() {
        isCapturing ? stopCapture() : startCapture()
    }

    private func startCapture() {
        isCapturing = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil // 入力をほかのコントロールに渡さない
        }
    }

    private func stopCapture() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isCapturing = false
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if event.keyCode == UInt16(kVK_Escape) && flags.isEmpty {
            stopCapture()
            return
        }
        if (event.keyCode == UInt16(kVK_Delete) || event.keyCode == UInt16(kVK_ForwardDelete)) && flags.isEmpty {
            hotKey = nil
            stopCapture()
            return
        }

        // 修飾キーなしや ⇧ だけだと普段の入力を奪ってしまうので受け付けない
        guard !flags.intersection([.command, .control, .option]).isEmpty else {
            NSSound.beep()
            return
        }

        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }

        let candidate = HotKey(keyCode: UInt32(event.keyCode), carbonModifiers: carbon)
        if candidate == .toggleRecording || candidate == .stopPlayback {
            NSSound.beep() // アプリ自身のショートカットと重複
            return
        }
        hotKey = candidate
        stopCapture()
    }
}
