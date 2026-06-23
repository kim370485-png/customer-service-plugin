@echo off
chcp 65001 >nul
echo.
echo ====================================
echo   飞猪客服工具箱 - Windows 安装程序
echo ====================================
echo.

set "EXT_ID=fmoadjiolfncoiahhmmjmgdoniiagohj"
set "UPDATE_URL=https://raw.githubusercontent.com/kim370485-png/customer-service-plugin/main/updates.xml"
set "HKLM_KEY=HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
set "HKCU_KEY=HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"

:: ============================================================
:: 检查管理员权限
:: ============================================================
net session >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo  !! 需要管理员权限！
    echo.
    echo  请右键此文件 → "以管理员身份运行"
    echo.
    pause
    exit /b 1
)

echo [1/4] 清理冲突源...

:: ============================================================
:: 关键步骤：删除 HKCU 策略（消除 Chrome 策略冲突）
:: 如果 HKLM 和 HKCU 同时设置 ExtensionInstallForcelist
:: 且内容不同，Chrome 会报"冲突"并全部忽略！
:: ============================================================
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallSources" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist" /f 2>nul

echo   HKCU 策略已清理（消除冲突）

echo [2/4] 合并扩展策略到 HKLM...

:: ============================================================
:: 使用 PowerShell 读取 HKLM 现有策略，合并我们的扩展
:: ============================================================
powershell -ExecutionPolicy Bypass -Command ^
    "$key = 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist';" ^
    "$extId = '%EXT_ID%';" ^
    "$updateUrl = '%UPDATE_URL%';" ^
    "$newEntry = \"$extId;$updateUrl\";" ^
    "" ^
    "# 创建 key（如果不存在）" ^
    "if (!(Test-Path $key)) { New-Item -Path $key -Force | Out-Null };" ^
    "" ^
    "# 读取现有条目" ^
    "$existing = @();" ^
    "$props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue;" ^
    "if ($props) {" ^
    "  $props.PSObject.Properties | ForEach-Object {" ^
    "    if ($_.Name -match '^\d+$') { $existing += $_.Value }" ^
    "  }" ^
    "}" ^
    "" ^
    "# 检查是否已存在（相同 extension ID）" ^
    "$found = $false;" ^
    "foreach ($e in $existing) {" ^
    "  if ($e -like \"$extId;*\") { $found = $true; break }" ^
    "}" ^
    "" ^
    "# 追加（如果不存在）" ^
    "if (!$found) { $existing += $newEntry };" ^
    "" ^
    "# 清空并写入（按序号重新编号）" ^
    "$i = 1;" ^
    "$existing | ForEach-Object {" ^
    "  Set-ItemProperty -Path $key -Name $i.ToString() -Value $_;" ^
    "  $i++" ^
    "}" ^
    "" ^
    "# 删除多余条目（旧的序号可能大于新的数量）" ^
    "while ($i -le ($existing.Count + 10)) {" ^
    "  Remove-ItemProperty -Path $key -Name $i.ToString() -ErrorAction SilentlyContinue;" ^
    "  $i++" ^
    "}" ^
    "" ^
    "Write-Host \"  已写入 $($existing.Count) 个扩展到 HKLM\""

if %errorlevel% neq 0 (
    echo   ✗ 写入注册表失败
    goto :done
)

echo [3/4] 清理旧版扩展...

:: 清理旧版 External Extensions（如果存在）
set "OLD_ID=njjdclibfaedfofiphakngdnglelphje"
set "EXT_EXT_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\External Extensions"
if exist "%EXT_EXT_DIR%\%OLD_ID%.json" del /f "%EXT_EXT_DIR%\%OLD_ID%.json" 2>nul
if exist "%EXT_EXT_DIR%\%EXT_ID%.json" del /f "%EXT_EXT_DIR%\%EXT_ID%.json" 2>nul

echo   旧版配置已清理

echo [4/4] 完成！
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
echo   4. 如果没出现，打开 chrome://policy/
echo      点击「重新加载政策」
echo.
echo   当前策略:
reg query "%HKLM_KEY%" 2>nul
echo.

:done
pause
