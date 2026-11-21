#!/bin/bash
# 安装/升级到 /Applications。
# 关键约束：语音模型存放在用户目录，安装过程绝不搬动/嵌套 App 包内的模型，
# 避免重装后模型路径失效导致“语音监听不启动、TTS 不播报”。
set -euo pipefail
cd "$(dirname "$0")"

SRC="ui/dist/mac-arm64/AVA.app"
DEST="/Applications/AVA.app"
MODELS="$HOME/Library/Application Support/ava-assistant-ui/models"
KWS_CHECK="$MODELS/kws/encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx"

if [ ! -d "$SRC" ]; then
  echo "找不到 $SRC"
  echo "请先执行：cd ui && npx electron-builder --mac --arm64 --publish never"
  exit 1
fi

osascript -e 'quit app "AVA"' 2>/dev/null || true
sleep 1
pkill -f "$DEST/Contents/MacOS" 2>/dev/null || true
pkill -f "ava-core --data-dir" 2>/dev/null || true
pkill -f "voice-serve" 2>/dev/null || true

# 仅当用户目录缺少模型时，从新包引导一次；已存在则完全不动。
if [ ! -f "$KWS_CHECK" ] && [ -d "$SRC/Contents/Resources/resources/models" ]; then
  mkdir -p "$MODELS"
  rsync -a "$SRC/Contents/Resources/resources/models/" "$MODELS/"
fi

rm -rf "$DEST"
cp -R "$SRC" /Applications/
# 签名：优先使用 AVA_SIGN_ID，其次本机任何可用的代码签名证书，最后退回 ad-hoc。
SIGN_ID="${AVA_SIGN_ID:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' 'NR==1{print $2}')}"
if [ -n "$SIGN_ID" ]; then
  codesign --force --deep --sign "$SIGN_ID" "$DEST" 2>&1 | tail -1
else
  echo "未找到代码签名证书，使用 ad-hoc 签名"
  codesign --force --deep --sign - "$DEST" 2>&1 | tail -1
fi
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
open "$DEST"
echo "已安装并启动：$DEST"
echo "模型目录：$MODELS"
