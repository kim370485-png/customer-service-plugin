#!/bin/bash
# 飞猪客服工具箱 - Mac 一键安装
# 双击此文件即可自动安装

echo ""
echo "正在安装飞猪客服工具箱..."
echo ""

TARGET="$HOME/Library/Application Support/Google/Chrome/External Extensions"
JSON_FILE="$TARGET/phfpldkfckdkigbhemjhekdpijgbbbop.json"

mkdir -p "$TARGET"

cat > "$JSON_FILE" << 'EOF'
{
  "external_update_url": "https://raw.githubusercontent.com/kim370485-png/customer-service-plugin/main/updates.xml"
}
EOF

if [ -f "$JSON_FILE" ]; then
    echo "===================================="
    echo "  ✓ 安装成功！"
    echo "===================================="
    echo ""
    echo "请完全退出 Chrome："
    echo "  1. 关闭所有 Chrome 窗口"
    echo "  2. 按 ⌘Q 完全退出"
    echo "  3. 重新打开 Chrome"
    echo ""
    echo "Chrome 会弹出提示，点击「启用扩展程序」即可。"
else
    echo "✗ 安装失败，请检查 Chrome 是否已安装。"
fi

echo ""
echo "按任意键关闭此窗口..."
read -n 1
