@echo off
chcp 65001 >nul
echo.
echo ====================================
echo   飞猪客服工具箱 - Windows 安装程序
echo ====================================
echo.

set "EXT_ID=fmoadjiolfncoiahhmmjmgdoniiagohj"
set "EXT_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\External Extensions"
set "OLD_ID=njjdclibfaedfofiphakngdnglelphje"

echo [1/4] 清理旧版本...

:: 移除旧的 External Extensions 文件
if exist "%EXT_DIR%\%OLD_ID%.json" (
    del /f "%EXT_DIR%\%OLD_ID%.json"
    echo   已移除旧扩展配置
)

:: 清理旧注册表策略（如果存在）
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallSources" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallSources" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist" /f 2>nul

echo [2/4] 安装新版本...

:: 创建 External Extensions 目录
if not exist "%EXT_DIR%" (
    mkdir "%EXT_DIR%"
)

:: 写入 JSON 配置
(
    echo {
    echo   "external_update_url": "https://raw.githubusercontent.com/kim370485-png/customer-service-plugin/main/updates.xml"
    echo }
) > "%EXT_DIR%\%EXT_ID%.json"

if exist "%EXT_DIR%\%EXT_ID%.json" (
    echo   ✓ 扩展配置已写入
) else (
    echo   ✗ 写入失败，请检查 Chrome 是否已安装
    goto :done
)

echo [3/4] 检查 Chrome 状态...

:: 检查 Chrome 是否在运行
tasklist /FI "IMAGENAME eq chrome.exe" 2>nul | find /i "chrome.exe" >nul
if %errorlevel% equ 0 (
    echo   ⚠ Chrome 正在运行！
    echo   请完全退出 Chrome（右下角托盘图标 → 右键 → 退出）
    echo   然后按任意键继续...
    pause >nul
)

echo [4/4] 完成！
echo.
echo ====================================
echo   安装完成！请按以下步骤操作：
echo ====================================
echo.
echo   1. 如果 Chrome 正在运行，完全退出它
echo      - 关闭所有 Chrome 窗口
echo      - 右下角托盘区找到 Chrome 图标，右键 → 退出
echo      - 任务管理器确认没有 chrome.exe 进程
echo.
echo   2. 重新打开 Chrome
echo.
echo   3. Chrome 会弹出"已添加新的扩展程序"
echo      → 点击「启用扩展程序」
echo.
echo   4. 打开 chrome://extensions/ 确认看到
echo      「飞猪客服工具箱」
echo.
echo   如果没看到扩展，请检查：
echo   - Chrome 是否已完全退出后重开
echo   - 扩展 ID 是否为: %EXT_ID%
echo.

:done
pause
