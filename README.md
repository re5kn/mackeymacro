# MacKeyMacro

キー操作を記録して、あとからショートカット一発で再生できる macOS 用のキーマクロアプリです。
メニューバーに常駐し、他のアプリが前面にあっても動作します。

## できること

- **記録**: 「記録を開始」(または `⌃⌥⌘R`)を押してから、対象のアプリでキーを操作し、もう一度押すと停止。押した順番とタイミングがそのまま保存されます。
- **再生**: 一覧やメニューバーから再生するか、マクロごとに設定したグローバルショートカットで再生。`⌃⌥⌘.` で中止。
- **編集**: 名前、ショートカット、再生速度(0.25〜4倍)、繰り返し回数の変更と、不要なイベントの削除。
- **保存**: `~/Library/Application Support/MacKeyMacro/macros.json` に自動保存。

修飾キー(⇧⌃⌥⌘fn)も記録されるので、`⌘C` → `⌘Tab` → `⌘V` のような操作も再生できます。
今はキーボードのみが対象で、マウス操作は記録しません。

## 必要なもの

- macOS 13 Ventura 以降
- Xcode 15 以降(または Command Line Tools。`xcode-select --install`)

## ビルドと起動

```bash
git clone https://github.com/re5kn/mackeymacro.git
cd mackeymacro
swift test                 # ロジックのテスト
./scripts/build-app.sh     # build/MacKeyMacro.app を作成
open build/MacKeyMacro.app
```

Xcode で開く場合は `open Package.swift` で開き、スキーム `MacKeyMacro` を実行します。
ただし権限は実行ファイルごとに管理されるため、普段使いは `build/MacKeyMacro.app` から起動するのがおすすめです。

## 権限の設定(初回のみ)

キー操作の記録と再生には、システム設定 > プライバシーとセキュリティ で次の許可が必要です。
アプリ上部のバナーのボタンから設定画面を開けます。

| 機能 | 必要な許可 |
| --- | --- |
| 記録 | 入力監視 |
| 再生 | アクセシビリティ |

許可したあとはアプリを一度終了して起動し直してください。
アドホック署名のため、**ビルドし直すと許可が外れる**ことがあります。その場合は一覧から MacKeyMacro を削除(−)して、もう一度許可してください。

## ショートカット

| 操作 | キー |
| --- | --- |
| 記録の開始・停止 | `⌃⌥⌘R` |
| 再生の中止 | `⌃⌥⌘.` |
| マクロの再生 | マクロごとに設定(⌃⌥⌘ のいずれかを含む組み合わせ) |

## 構成

```
Sources/MacroCore/       記録データのモデルと整形ロジック(テスト対象)
Sources/MacKeyMacro/     アプリ本体
  KeyRecorder.swift      CGEventTap でキー入力を記録
  KeyPlayer.swift        CGEvent でキー入力を送出して再生
  HotKeyManager.swift    Carbon RegisterEventHotKey でグローバルショートカット
  MacroStore.swift       JSON での保存・読み込み
  AppState.swift         全体の状態管理
  Views/                 SwiftUI の画面
Tests/MacroCoreTests/    ユニットテスト
```
