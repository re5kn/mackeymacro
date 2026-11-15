import Foundation

/// 記録したイベント列を再生しやすい形に整える処理
public enum RecordingCleanup {
    /// - 記録開始前から押されていたキーの keyUp(対応する keyDown がないもの)を捨てる
    /// - 記録開始直後の修飾キーの解放(ショートカットで記録を始めたときの指の離し)を捨てる
    /// - 先頭の待ち時間を 0 にする
    /// 捨てたイベントの待ち時間は次のイベントに足して、全体のタイミングを保つ。
    public static func normalized(_ events: [KeyEvent]) -> [KeyEvent] {
        var result: [KeyEvent] = []
        var down = Set<UInt16>()
        var started = false
        var pendingDelay: TimeInterval = 0

        for var event in events {
            var keep = true
            switch event.kind {
            case .keyDown:
                down.insert(event.keyCode)
                started = true
            case .keyUp:
                keep = down.remove(event.keyCode) != nil
            case .flagsChanged:
                let press = ModifierFlags.isPress(event)
                if press {
                    started = true
                } else if !started {
                    keep = false
                }
            }

            guard keep else {
                pendingDelay += event.delay
                continue
            }
            event.delay = result.isEmpty ? 0 : event.delay + pendingDelay
            pendingDelay = 0
            result.append(event)
        }
        return result
    }

    /// 記録停止のショートカット(例: ⌃⌥⌘R)が末尾に記録されてしまった分を取り除く。
    /// 最後に「すべてのキーと修飾キーが離された」状態になった位置までで切る。
    public static func trimmingTrailingShortcut(_ events: [KeyEvent]) -> [KeyEvent] {
        var down = Set<UInt16>()
        var lastReleasedIndex: Int?

        for (index, event) in events.enumerated() {
            switch event.kind {
            case .keyDown: down.insert(event.keyCode)
            case .keyUp: down.remove(event.keyCode)
            case .flagsChanged: break
            }
            if down.isEmpty && event.flags & ModifierFlags.heldMask == 0 {
                lastReleasedIndex = index
            }
        }

        guard let last = lastReleasedIndex else { return [] }
        return Array(events[...last])
    }
}
