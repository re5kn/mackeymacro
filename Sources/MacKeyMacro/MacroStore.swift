import Foundation
import MacroCore

/// マクロ一覧を ~/Library/Application Support/MacKeyMacro/macros.json に保存する
final class MacroStore: ObservableObject {
    @Published var macros: [Macro] = [] {
        didSet { if !isLoading { save() } }
    }

    let fileURL: URL
    private var isLoading = false

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let dir = base.appendingPathComponent("MacKeyMacro", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("macros.json")
        }
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            isLoading = true
            macros = try decoder.decode([Macro].self, from: data)
            isLoading = false
        } catch {
            isLoading = false
            // 壊れたファイルは上書きせず退避しておく
            let backup = fileURL.deletingPathExtension().appendingPathExtension("broken.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            NSLog("MacKeyMacro: macros.json の読み込みに失敗しました: \(error)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(macros)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("MacKeyMacro: macros.json の保存に失敗しました: \(error)")
        }
    }

    func add(_ macro: Macro) {
        macros.append(macro)
    }

    func delete(id: Macro.ID) {
        macros.removeAll { $0.id == id }
    }

    func macro(id: Macro.ID) -> Macro? {
        macros.first { $0.id == id }
    }

    func nextDefaultName() -> String {
        "マクロ \(macros.count + 1)"
    }
}
