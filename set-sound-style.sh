#!/bin/bash
# 切换 AVA 提示音风格。用法：./set-sound-style.sh crystal|warm|tech|minimal|glass|pulse
set -euo pipefail
cd "$(dirname "$0")"

STYLE="${1:-crystal}"
SRC="docs/sound-previews/$STYLE"
if [ ! -d "$SRC" ]; then
  echo "未知风格：$STYLE"
  echo "可用风格：crystal warm tech minimal glass pulse"
  exit 1
fi

cp "$SRC/wake_sound.wav" resources/wake_sound.wav
for f in complete computer_beep_1 computerbeep_75 computerbeep_29 subagent_done; do
  cp "$SRC/$f.mp3" "resources/$f.mp3"
done

echo "已切换为「$STYLE」风格。重启 AVA 后生效。"
