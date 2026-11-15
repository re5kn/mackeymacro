import CoreGraphics
import Foundation
import MacroCore

/// CGEventTap(listen only)で全アプリのキー入力を記録する。
/// 「入力監視」の権限が必要。
final class KeyRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var events: [KeyEvent] = []

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastTimestamp: TimeInterval?

    /// 記録を開始する。権限がないなどでタップを作れなければ false。
    @discardableResult
    func start() -> Bool {
        guard !isRecording else { return true }

        let types: [CGEventType] = [.keyDown, .keyUp, .flagsChanged]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << CGEventMask($1.rawValue)) }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: keyRecorderCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.runLoopSource = source
        events = []
        lastTimestamp = nil
        isRecording = true
        return true
    }

    /// 記録を止めて、整形済みのイベント列を返す。
    /// - Parameter stoppedByShortcut: 停止ショートカットの打鍵が末尾に入っているので取り除く
    func stop(stoppedByShortcut: Bool) -> [KeyEvent] {
        guard isRecording else { return [] }
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        tap = nil
        runLoopSource = nil
        isRecording = false

        var result = events
        if stoppedByShortcut {
            result = RecordingCleanup.trimmingTrailingShortcut(result)
        }
        return RecordingCleanup.normalized(result)
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) {
        // 処理が遅いと macOS がタップを無効化するので、そのときは再有効化する
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }

        let kind: KeyEventKind
        switch type {
        case .keyDown: kind = .keyDown
        case .keyUp: kind = .keyUp
        case .flagsChanged: kind = .flagsChanged
        default: return
        }

        let now = ProcessInfo.processInfo.systemUptime
        let delay = lastTimestamp.map { now - $0 } ?? 0
        lastTimestamp = now

        let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
        events.append(KeyEvent(kind: kind, keyCode: keyCode, flags: event.flags.rawValue, delay: delay))
    }
}

private func keyRecorderCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if let refcon {
        let recorder = Unmanaged<KeyRecorder>.fromOpaque(refcon).takeUnretainedValue()
        recorder.handle(type: type, event: event)
    }
    return Unmanaged.passUnretained(event)
}
