import Foundation

/// 仮想キーコードを表示用の名前に変換する(US / JIS 配列の主要キー)
public enum KeyNames {
    private static let names: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7",
        27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        36: "Return", 37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space", 50: "`", 51: "Delete",
        53: "Esc", 54: "右⌘", 55: "⌘", 56: "⇧", 57: "CapsLock", 58: "⌥", 59: "⌃",
        60: "右⇧", 61: "右⌥", 62: "右⌃", 63: "fn",
        65: "テンキー.", 67: "テンキー*", 69: "テンキー+", 71: "Clear", 75: "テンキー/",
        76: "Enter", 78: "テンキー-", 81: "テンキー=",
        82: "テンキー0", 83: "テンキー1", 84: "テンキー2", 85: "テンキー3", 86: "テンキー4",
        87: "テンキー5", 88: "テンキー6", 89: "テンキー7", 91: "テンキー8", 92: "テンキー9",
        93: "¥", 94: "_", 102: "英数", 104: "かな",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11",
        105: "F13", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
        114: "Help", 115: "Home", 116: "PageUp", 117: "⌦", 118: "F4", 119: "End",
        120: "F2", 121: "PageDown", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑",
    ]

    public static func name(for keyCode: UInt16) -> String {
        names[keyCode] ?? "Key\(keyCode)"
    }

    /// CGEventFlags のビットから「⌃⌥⇧⌘」形式の文字列を作る
    public static func modifierSymbols(_ flags: UInt64) -> String {
        var s = ""
        if flags & ModifierFlags.secondaryFn != 0 { s += "fn" }
        if flags & ModifierFlags.control != 0 { s += "⌃" }
        if flags & ModifierFlags.option != 0 { s += "⌥" }
        if flags & ModifierFlags.shift != 0 { s += "⇧" }
        if flags & ModifierFlags.command != 0 { s += "⌘" }
        return s
    }

    /// イベント一覧での表示
    public static func describe(_ event: KeyEvent) -> String {
        let key = name(for: event.keyCode)
        switch event.kind {
        case .keyDown:
            return "↓ \(modifierSymbols(event.flags))\(key)"
        case .keyUp:
            return "↑ \(key)"
        case .flagsChanged:
            return ModifierFlags.isPress(event) ? "↓ \(key)" : "↑ \(key)"
        }
    }

    /// Carbon の修飾キー値(cmdKey=256, shiftKey=512, optionKey=2048, controlKey=4096)
    public static func describe(_ hotKey: HotKey) -> String {
        var s = ""
        if hotKey.carbonModifiers & 4096 != 0 { s += "⌃" }
        if hotKey.carbonModifiers & 2048 != 0 { s += "⌥" }
        if hotKey.carbonModifiers & 512 != 0 { s += "⇧" }
        if hotKey.carbonModifiers & 256 != 0 { s += "⌘" }
        return s + name(for: UInt16(truncatingIfNeeded: hotKey.keyCode))
    }
}
