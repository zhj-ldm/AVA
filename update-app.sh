#!/bin/bash
# 一键更新桌面 AVA.app
# 用法: ./update-app.sh           # 编译 release 并覆盖桌面 App（含重签）
#       ./update-app.sh --skip-build  # 跳过编译，仅用现有 target/release 产物覆盖
set -e
export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:$PATH"
PROJ="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Desktop/AVA.app"

if [ ! -d "$APP" ]; then
  echo "未找到桌面 App: $APP" >&2
  exit 1
fi

if [ "$1" != "--skip-build" ]; then
  echo "[1/4] cargo build --release (voice-serve + ava-core) ..."
  cd "$PROJ"
  cargo build --release -p voice-serve -p ava-core
else
  echo "[1/4] 跳过编译，使用现有 target/release 产物"
fi

echo "[2/4] 替换 bin -> $APP/Contents/Resources/bin/"
cp -f "$PROJ/target/release/ava-core" "$APP/Contents/Resources/bin/"
cp -f "$PROJ/target/release/voice-serve"    "$APP/Contents/Resources/bin/"

echo "[3/4] 重签 ..."
SIGN_ID="${AVA_SIGN_ID:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' 'NR==1{print $2}')}"
if [ -n "$SIGN_ID" ]; then
  codesign --force --deep --sign "$SIGN_ID" "$APP"
else
  echo "未找到代码签名证书，使用 ad-hoc 签名"
  codesign --force --deep --sign - "$APP"
fi

echo "[4/4] 验证签名 ..."
codesign -dv --verbose=2 "$APP" 2>&1 | grep -E "Identifier|Authority" | head -3

echo "完成。请完全退出 App（Cmd+Q）后重新打开桌面副本。"
