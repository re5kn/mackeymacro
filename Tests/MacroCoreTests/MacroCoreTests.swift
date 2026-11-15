import XCTest
@testable import MacroCore

final class RecordingCleanupTests: XCTestCase {
    private func down(_ code: UInt16, _ flags: UInt64 = 0, delay: Double = 0.1) -> KeyEvent {
        KeyEvent(kind: .keyDown, keyCode: code, flags: flags, delay: delay)
    }
    private func up(_ code: UInt16, _ flags: UInt64 = 0, delay: Double = 0.1) -> KeyEvent {
        KeyEvent(kind: .keyUp, keyCode: code, flags: flags, delay: delay)
    }
    private func mod(_ code: UInt16, _ flags: UInt64, delay: Double = 0.1) -> KeyEvent {
        KeyEvent(kind: .flagsChanged, keyCode: code, flags: flags, delay: delay)
    }

    private let cmdOptCtrl = ModifierFlags.command | ModifierFlags.option | ModifierFlags.control

    func testNormalizedDropsOrphanKeyUpAndLeadingModifierRelease() {
        // ⌃⌥⌘R で記録開始 → R と修飾キーを離す → "a" を打つ
        let events = [
            up(15, cmdOptCtrl),
            mod(59, ModifierFlags.command | ModifierFlags.option), // ⌃ を離す
            mod(58, ModifierFlags.command), // ⌥ を離す
            mod(55, 0), // ⌘ を離す
            down(0, delay: 0.5),
            up(0),
        ]
        let result = RecordingCleanup.normalized(events)
        XCTAssertEqual(result.map(\.kind), [.keyDown, .keyUp])
        XCTAssertEqual(result.first?.delay, 0)
        XCTAssertEqual(result.last?.delay ?? 0, 0.1, accuracy: 1e-9)
    }

    func testNormalizedKeepsLeadingModifierPress() {
        let events = [mod(56, ModifierFlags.shift), down(0, ModifierFlags.shift), up(0, ModifierFlags.shift), mod(56, 0)]
        XCTAssertEqual(RecordingCleanup.normalized(events).count, 4)
    }

    func testNormalizedCarriesDroppedDelayForward() {
        let events = [down(0), up(1, delay: 0.3), up(0, delay: 0.2)]
        let result = RecordingCleanup.normalized(events)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[1].delay, 0.5, accuracy: 1e-9)
    }

    func testTrimmingTrailingShortcut() {
        let events = [
            down(0), up(0),
            mod(59, ModifierFlags.control),
            mod(58, ModifierFlags.control | ModifierFlags.option),
            mod(55, cmdOptCtrl),
            down(15, cmdOptCtrl),
        ]
        let result = RecordingCleanup.trimmingTrailingShortcut(events)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.last?.kind, .keyUp)
    }

    func testTrimmingIgnoresCapsLock() {
        let events = [down(0, ModifierFlags.alphaShift), up(0, ModifierFlags.alphaShift), mod(59, ModifierFlags.control | ModifierFlags.alphaShift)]
        XCTAssertEqual(RecordingCleanup.trimmingTrailingShortcut(events).count, 2)
    }

    func testMacroCodableRoundTripAndDefaults() throws {
        let macro = Macro(name: "テスト", events: [down(0)], hotKey: HotKey(keyCode: 1, carbonModifiers: 256), speed: 2, repeatCount: 3)
        let data = try JSONEncoder().encode(macro)
        XCTAssertEqual(try JSONDecoder().decode(Macro.self, from: data), macro)

        // 古い形式(speed などがない)でも読める
        let legacy = #"{"name":"古い","events":[]}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Macro.self, from: legacy)
        XCTAssertEqual(decoded.speed, 1)
        XCTAssertEqual(decoded.repeatCount, 1)
        XCTAssertNil(decoded.hotKey)
    }

    func testKeyNames() {
        XCTAssertEqual(KeyNames.describe(HotKey(keyCode: 15, carbonModifiers: 4096 | 2048 | 256)), "⌃⌥⌘R")
        XCTAssertEqual(KeyNames.describe(down(0, ModifierFlags.shift)), "↓ ⇧A")
    }
}
