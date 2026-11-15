#!/bin/bash
# リリースビルドして build/MacKeyMacro.app を作る。
# 権限(入力監視・アクセシビリティ)は .app 単位で許可するので、この .app から起動してください。
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

APP="build/MacKeyMacro.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MacKeyMacro" "$APP/Contents/MacOS/MacKeyMacro"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# アドホック署名(署名がないと権限の許可が保持されない)
codesign --force --sign - "$APP"

echo "作成しました: $APP"
echo "起動: open $APP"
