import Foundation

/// 記録したキーイベントの種類
public enum KeyEventKind: String, Codable, Sendable {
    case keyDown
    case keyUp
    /// 修飾キー(⇧⌃⌥⌘fn CapsLock)の押下・解放
    case flagsChanged
}

/// 1つのキーイベント
public struct KeyEvent: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var kind: KeyEventKind
    /// macOS の仮想キーコード
    public var keyCode: UInt16
    /// CGEventFlags の rawValue(修飾キー部分のみ)
    public var flags: UInt64
    /// 直前のイベントからの待ち時間(秒)
    public var delay: TimeInterval

    public init(id: UUID = UUID(), kind: KeyEventKind, keyCode: UInt16, flags: UInt64, delay: TimeInterval) {
        self.id = id
        self.kind = kind
        self.keyCode = keyCode
        self.flags = flags & ModifierFlags.mask
        self.delay = max(0, delay)
    }
}

/// グローバルショートカット(Carbon の仮想キーコード + 修飾キー)
public struct HotKey: Codable, Hashable, Sendable {
    public var keyCode: UInt32
    /// Carbon の修飾キー(cmdKey / optionKey / controlKey / shiftKey)
    public var carbonModifiers: UInt32

    public init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }
}

/// 登録済みマクロ
public struct Macro: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var events: [KeyEvent]
    public var hotKey: HotKey?
    /// 再生速度の倍率(2.0 なら2倍速)
    public var speed: Double
    /// 繰り返し回数
    public var repeatCount: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        events: [KeyEvent],
        hotKey: HotKey? = nil,
        speed: Double = 1.0,
        repeatCount: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.events = events
        self.hotKey = hotKey
        self.speed = speed
        self.repeatCount = repeatCount
        self.createdAt = createdAt
    }

    /// 1回分の再生時間(秒、速度倍率込み)
    public var duration: TimeInterval {
        events.reduce(0) { $0 + $1.delay } / max(speed, 0.01)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, events, hotKey, speed, repeatCount, createdAt
    }

    // 後からフィールドを足しても古い保存データを読めるように、任意項目は既定値で補う
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "マクロ"
        events = try c.decodeIfPresent([KeyEvent].self, forKey: .events) ?? []
        hotKey = try c.decodeIfPresent(HotKey.self, forKey: .hotKey)
        speed = try c.decodeIfPresent(Double.self, forKey: .speed) ?? 1.0
        repeatCount = try c.decodeIfPresent(Int.self, forKey: .repeatCount) ?? 1
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

/// CGEventFlags と同じビット値(CoreGraphics に依存せずに扱うため)
public enum ModifierFlags {
    public static let alphaShift: UInt64 = 0x0001_0000 // CapsLock
    public static let shift: UInt64 = 0x0002_0000
    public static let control: UInt64 = 0x0004_0000
    public static let option: UInt64 = 0x0008_0000
    public static let command: UInt64 = 0x0010_0000
    public static let secondaryFn: UInt64 = 0x0080_0000

    public static let mask: UInt64 = alphaShift | shift | control | option | command | secondaryFn
    /// 「押しっぱなし」を判定するときに見る修飾キー(CapsLock はトグルなので除く)
    public static let heldMask: UInt64 = shift | control | option | command | secondaryFn

    /// 修飾キーの仮想キーコード → 対応するフラグ
    public static func flag(forKeyCode keyCode: UInt16) -> UInt64? {
        switch keyCode {
        case 56, 60: return shift
        case 59, 62: return control
        case 58, 61: return option
        case 55, 54: return command
        case 63: return secondaryFn
        case 57: return alphaShift
        default: return nil
        }
    }

    /// flagsChanged イベントが「押下」かどうか
    public static func isPress(_ event: KeyEvent) -> Bool {
        guard let flag = flag(forKeyCode: event.keyCode) else { return true }
        return event.flags & flag != 0
    }
}
