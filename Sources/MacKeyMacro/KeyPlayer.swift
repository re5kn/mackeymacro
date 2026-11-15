import CoreGraphics
import Foundation
import MacroCore

/// 記録したキーイベントを CGEvent として送出して再生する。
/// 「アクセシビリティ」の権限が必要。
final class KeyPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var playingMacroID: Macro.ID?

    private var task: Task<Void, Never>?

    func play(_ macro: Macro) {
        guard !isPlaying, !macro.events.isEmpty else { return }
        isPlaying = true
        playingMacroID = macro.id

        let events = macro.events
        let speed = max(macro.speed, 0.05)
        let repeats = max(macro.repeatCount, 1)

        task = Task.detached(priority: .userInitiated) { [weak self] in
            // ショートカットで起動した場合、修飾キーを離すまで待つ(押したままだと再生内容に混ざる)
            await KeyPlayer.waitForModifiersReleased(timeout: 2.0)

            let source = CGEventSource(stateID: .hidSystemState)
            var heldKeys = Set<UInt16>()

            outer: for _ in 0..<repeats {
                for event in events {
                    if Task.isCancelled { break outer }
                    let wait = event.delay / speed
                    if wait > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                        if Task.isCancelled { break outer }
                    }
                    KeyPlayer.post(event, source: source, heldKeys: &heldKeys)
                }
            }

            // 途中停止などで押しっぱなしのキーが残らないよう、すべて離す
            for keyCode in heldKeys {
                KeyPlayer.postKey(keyCode, down: false, flags: 0, source: source)
            }

            await MainActor.run {
                self?.isPlaying = false
                self?.playingMacroID = nil
                self?.task = nil
            }
        }
    }

    func stop() {
        task?.cancel()
    }

    private static func post(_ event: KeyEvent, source: CGEventSource?, heldKeys: inout Set<UInt16>) {
        let down: Bool
        switch event.kind {
        case .keyDown: down = true
        case .keyUp: down = false
        case .flagsChanged: down = ModifierFlags.isPress(event)
        }
        if down { heldKeys.insert(event.keyCode) } else { heldKeys.remove(event.keyCode) }
        postKey(event.keyCode, down: down, flags: event.flags, source: source)
    }

    private static func postKey(_ keyCode: UInt16, down: Bool, flags: UInt64, source: CGEventSource?) {
        guard let cgEvent = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: down) else { return }
        cgEvent.flags = CGEventFlags(rawValue: flags & ModifierFlags.mask)
        cgEvent.post(tap: .cghidEventTap)
    }

    private static func waitForModifiersReleased(timeout: TimeInterval) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let flags = CGEventSource.flagsState(.combinedSessionState).rawValue
            if flags & ModifierFlags.heldMask == 0 { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}
