// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacKeyMacro",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacKeyMacro", targets: ["MacKeyMacro"]),
    ],
    targets: [
        // 記録データのモデルと純粋ロジック(テスト可能)
        .target(name: "MacroCore"),
        // SwiftUI アプリ本体(記録・再生・ホットキー・UI)
        .executableTarget(name: "MacKeyMacro", dependencies: ["MacroCore"]),
        .testTarget(name: "MacroCoreTests", dependencies: ["MacroCore"]),
    ]
)
