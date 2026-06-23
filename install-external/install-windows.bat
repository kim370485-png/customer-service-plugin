@echo off
chcp 65001 >nul
echo.
echo ====================================
echo   飞猪客服工具箱 - Windows 安装程序
echo ====================================
echo.

set "EXT_ID=phfpldkfckdkigbhemjhekdpijgbbbop"
set "UPDATE_URL=https://raw.githubusercontent.com/kim370485-png/customer-service-plugin/main/updates.xml"

:: ============================================================
:: 清理 HKLM（避免与 HKCU 冲突）
:: 之前版本写入了 HKLM，会导致 Chrome 报"策略冲突"
:: ============================================================
echo [1/2] 清理旧策略...

reg delete "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /f >nul 2>nul
echo   HKLM 已清理

:: ============================================================
:: 只写入 HKCU（用户级别策略）
:: 跟第一个能用的版本（install-user.reg）一样的方式
:: ============================================================
echo [2/2] 写入用户策略 (HKCU)...

reg add "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%EXT_ID%;%UPDATE_URL%" /f >nul 2>nul

if %errorlevel% equ 0 (
    echo   HKCU 写入成功
) else (
    echo   HKCU 写入失败
    pause
    exit /b 1
)

echo.
echo ====================================
echo   安装完成！请按以下步骤操作：
echo ====================================
echo.
echo   1. 完全退出 Chrome
echo      - 关闭所有 Chrome 窗口
echo      - 右下角托盘找到 Chrome 图标，右键 → 退出
echo.
echo   2. 重新打开 Chrome
echo.
echo   3. 打开 chrome://extensions/
echo      确认看到「飞猪客服工具箱」
echo.
echo   扩展 ID: %EXT_ID%
echo.
pause
