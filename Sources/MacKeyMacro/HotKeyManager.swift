import Carbon
import Foundation
import MacroCore

/// Carbon の RegisterEventHotKey でグローバルショートカットを登録する。
/// この API は追加の権限なしで、他のアプリが前面にあっても反応する。
final class HotKeyManager {
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var actions: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var handlerRef: EventHandlerRef?

    private static let signature: OSType = 0x4D4B_4D43 // "MKMC"

    init() {
        installHandler()
    }

    deinit {
        unregisterAll()
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    /// 登録に失敗した場合(他アプリと重複など)は false
    @discardableResult
    func register(_ hotKey: HotKey, action: @escaping () -> Void) -> Bool {
        let id = nextID
        nextID += 1

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        let status = RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else { return false }
        refs[id] = ref
        actions[id] = action
        return true
    }

    func unregisterAll() {
        for ref in refs.values { UnregisterEventHotKey(ref) }
        refs.removeAll()
        actions.removeAll()
    }

    fileprivate func fire(id: UInt32) {
        guard let action = actions[id] else { return }
        DispatchQueue.main.async { action() }
    }

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
    }
}

private func hotKeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }
    Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue().fire(id: hotKeyID.id)
    return noErr
}

extension HotKey {
    /// 記録の開始・停止: ⌃⌥⌘R
    static let toggleRecording = HotKey(keyCode: 15, carbonModifiers: UInt32(controlKey | optionKey | cmdKey))
    /// 再生の中止: ⌃⌥⌘.
    static let stopPlayback = HotKey(keyCode: 47, carbonModifiers: UInt32(controlKey | optionKey | cmdKey))
}
