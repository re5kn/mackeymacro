import AppKit
import ApplicationServices
import CoreGraphics

/// 記録には「入力監視」、再生には「アクセシビリティ」の許可が必要
enum Permissions {
    /// キー入力の監視(記録)
    static var canListen: Bool { CGPreflightListenEventAccess() }
    /// キーイベントの送出(再生)
    static var canPost: Bool { CGPreflightPostEventAccess() }

    static func requestListen() {
        if !CGRequestListenEventAccess() {
            open("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
        }
    }

    static func requestPost() {
        if !CGRequestPostEventAccess() {
            open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        }
    }

    private static func open(_ string: String) {
        if let url = URL(string: string) { NSWorkspace.shared.open(url) }
    }
}
