@echo off
chcp 65001 >nul
echo.
echo ====================================
echo   飞猪客服工具箱 - Windows 安装程序
echo ====================================
echo.

set "EXT_ID=fmoadjiolfncoiahhmmjmgdoniiagohj"
set "UPDATE_URL=https://raw.githubusercontent.com/kim370485-png/customer-service-plugin/main/updates.xml"
set "REG_KEY=HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"

:: 检查管理员权限
net session >nul 2>nul
if %errorlevel% neq 0 (
    echo ⚠ 需要管理员权限！
    echo 请右键此文件 → 以管理员身份运行
    echo.
    pause
    exit /b 1
)

echo [1/3] 读取现有策略...

:: 用 PowerShell 读取现有 ExtensionInstallForcelist 并合并
powershell -ExecutionPolicy Bypass -Command ^
    "$key = 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist';" ^
    "$extId = '%EXT_ID%';" ^
    "$updateUrl = '%UPDATE_URL%';" ^
    "$newEntry = \"$extId;$updateUrl\";" ^
    "if (!(Test-Path $key)) { New-Item -Path $key -Force | Out-Null };" ^
    "$existing = @();" ^
    "$props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue;" ^
    "if ($props) {" ^
    "  $props.PSObject.Properties | ForEach-Object {" ^
    "    if ($_.Name -match '^\d+$') { $existing += $_.Value }" ^
    "  }" ^
    "}" ^
    "$found = $false;" ^
    "foreach ($e in $existing) {" ^
    "  if ($e -like \"$extId;*\") { $found = $true; break }" ^
    "}" ^
    "if (!$found) { $existing += $newEntry };" ^
    "$i = 1;" ^
    "Remove-ItemProperty -Path $key -Name '*' -ErrorAction SilentlyContinue;" ^
    "foreach ($e in $existing) {" ^
    "  Set-ItemProperty -Path $key -Name $i.ToString() -Value $e;" ^
    "  $i++" ^
    "}" ^
    "Write-Host '  ✓ 策略已写入（共' ($existing.Count) '个扩展）'"

if %errorlevel% neq 0 (
    echo   ✗ 写入注册表失败
    goto :done
)

echo [2/3] 刷新 Chrome 策略...

:: 通知 Chrome 重新加载策略
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v "LastPolicyRefreshTime" /t REG_DWORD /d %time:~0,2%%time:~3,2%%time:~6,2% /f >nul 2>nul

echo [3/3] 完成！
echo.
echo ====================================
echo   安装完成！请按以下步骤操作：
echo ====================================
echo.
echo   1. 完全退出 Chrome
echo      - 关闭所有 Chrome 窗口
echo      - 右下角托盘区找到 Chrome 图标，右键 → 退出
echo.
echo   2. 重新打开 Chrome
echo.
echo   3. 打开 chrome://extensions/
echo      确认看到「飞猪客服工具箱」✅
echo.
echo   4. 如果没出现，打开 chrome://policy/
echo      点「重新加载政策」→ 刷新页面
echo.

:done
pause
