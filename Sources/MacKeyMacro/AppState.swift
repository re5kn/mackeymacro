import AppKit
import Combine
import Foundation
import MacroCore

/// アプリ全体の状態。記録・再生・ショートカット登録をまとめる。
final class AppState: ObservableObject {
    let store = MacroStore()
    let recorder = KeyRecorder()
    let player = KeyPlayer()
    private let hotKeys = HotKeyManager()

    @Published var selection: Macro.ID?
    @Published var message: String?
    @Published private(set) var canListen = Permissions.canListen
    @Published private(set) var canPost = Permissions.canPost
    /// 他アプリと重複するなどして登録できなかったショートカット
    @Published private(set) var failedHotKeyMacroIDs: Set<Macro.ID> = []

    private var cancellables = Set<AnyCancellable>()
    private var permissionTimer: Timer?

    init() {
        // 子オブジェクトの変更を画面に伝える
        for publisher in [store.objectWillChange, recorder.objectWillChange, player.objectWillChange] {
            publisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
        }

        // マクロが変わったらショートカットを登録し直す
        store.$macros
            .map { $0.map { MacroHotKey(id: $0.id, hotKey: $0.hotKey) } }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.registerHotKeys() }
            .store(in: &cancellables)

        // 権限はシステム設定で変わるので定期的に確認する
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshPermissions()
        }
    }

    // MARK: - 記録

    func toggleRecording(fromShortcut: Bool = false) {
        if recorder.isRecording {
            stopRecording(fromShortcut: fromShortcut)
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard !player.isPlaying else { return }
        if !Permissions.canListen {
            Permissions.requestListen()
            message = "記録には「入力監視」の許可が必要です。システム設定で MacKeyMacro を許可してから、もう一度お試しください。"
            return
        }
        if recorder.start() {
            message = "記録中です。対象のアプリでキーを操作し、⌃⌥⌘R かメニューの「記録を停止」で終了します。"
        } else {
            message = "キー入力の監視を開始できませんでした。「入力監視」の許可を確認してください。"
        }
    }

    func stopRecording(fromShortcut: Bool) {
        let events = recorder.stop(stoppedByShortcut: fromShortcut)
        guard !events.isEmpty else {
            message = "キー入力が記録されなかったため、マクロは作成しませんでした。"
            return
        }
        let macro = Macro(name: store.nextDefaultName(), events: events)
        store.add(macro)
        selection = macro.id
        message = "「\(macro.name)」を保存しました(\(events.count) イベント)。"
    }

    // MARK: - 再生

    func play(_ id: Macro.ID) {
        guard let macro = store.macro(id: id), !recorder.isRecording else { return }
        if !Permissions.canPost {
            Permissions.requestPost()
            message = "再生には「アクセシビリティ」の許可が必要です。システム設定で MacKeyMacro を許可してください。"
            return
        }
        player.play(macro)
    }

    func stopPlayback() {
        player.stop()
    }

    // MARK: - 編集

    func delete(_ id: Macro.ID) {
        if selection == id { selection = nil }
        store.delete(id: id)
    }

    // MARK: - ショートカット

    private func registerHotKeys() {
        hotKeys.unregisterAll()
        hotKeys.register(.toggleRecording) { [weak self] in self?.toggleRecording(fromShortcut: true) }
        hotKeys.register(.stopPlayback) { [weak self] in self?.stopPlayback() }

        var failed = Set<Macro.ID>()
        for macro in store.macros {
            guard let hotKey = macro.hotKey else { continue }
            let id = macro.id
            let ok = hotKeys.register(hotKey) { [weak self] in self?.play(id) }
            if !ok { failed.insert(id) }
        }
        failedHotKeyMacroIDs = failed
    }

    func refreshPermissions() {
        let listen = Permissions.canListen
        let post = Permissions.canPost
        if listen != canListen { canListen = listen }
        if post != canPost { canPost = post }
    }
}

private struct MacroHotKey: Equatable {
    let id: Macro.ID
    let hotKey: HotKey?
}
