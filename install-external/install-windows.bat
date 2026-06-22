@echo off
chcp 65001 >nul
echo 正在安装飞猪客服工具箱...
echo.

set "TARGET=%LOCALAPPDATA%\Google\Chrome\User Data\External Extensions"

if not exist "%TARGET%" (
    mkdir "%TARGET%"
)

copy /Y "%~dp0phfpldkfckdkigbhemjhekdpijgbbbop.json" "%TARGET%\" >nul

if %errorlevel% equ 0 (
    echo ✓ 安装成功！
    echo.
    echo 请完全退出 Chrome（右下角托盘图标 → 右键 → 退出），然后重新打开。
    echo Chrome 会弹出一个确认框，点击"启用扩展程序"即可。
) else (
    echo ✗ 安装失败，请检查 Chrome 是否已安装。
)

echo.
pause
