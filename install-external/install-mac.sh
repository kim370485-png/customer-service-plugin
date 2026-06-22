#!/bin/bash

echo "正在安装飞猪客服工具箱..."
echo

TARGET="$HOME/Library/Application Support/Google/Chrome/External Extensions"

mkdir -p "$TARGET"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/fmoadjiolfncoiahhmmjmgdoniiagohj.json" "$TARGET/"

if [ $? -eq 0 ]; then
    echo "✓ 安装成功！"
    echo
    echo "请完全退出 Chrome（⌘Q），然后重新打开。"
    echo "Chrome 会弹出一个确认框，点击"启用扩展程序"即可。"
else
    echo "✗ 安装失败，请检查 Chrome 是否已安装。"
fi

echo
