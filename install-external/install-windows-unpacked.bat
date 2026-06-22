@echo off
chcp 65001 >nul
echo.
echo ====================================
echo   飞猪客服工具箱 - Windows 安装程序
echo ====================================
echo.

set "EXT_ID=fmoadjiolfncoiahhmmjmgdoniiagohj"
set "EXT_DIR=%LOCALAPPDATA%\FliggyToolbox"
set "OLD_ID=njjdclibfaedfofiphakngdnglelphje"

echo [1/5] 清理旧版本...

:: 清理旧 External Extensions
set "EXT_EXT_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\External Extensions"
if exist "%EXT_EXT_DIR%\%OLD_ID%.json" del /f "%EXT_EXT_DIR%\%OLD_ID%.json" 2>nul
if exist "%EXT_EXT_DIR%\%EXT_ID%.json" del /f "%EXT_EXT_DIR%\%EXT_ID%.json" 2>nul

:: 清理旧注册表策略
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallSources" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist" /f 2>nul

echo [2/5] 下载扩展源码...

:: 创建目录
if not exist "%EXT_DIR%" mkdir "%EXT_DIR%"
if exist "%EXT_DIR%\manifest.json" del /f "%EXT_DIR%\manifest.json" 2>nul

:: 下载源码 zip
set "ZIP_URL=https://github.com/kim370485-png/customer-service-plugin/archive/refs/heads/main.zip"
set "ZIP_FILE=%TEMP%\fliggy-toolbox.zip"

echo   正在从 GitHub 下载...
powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing } catch { exit 1 }"
if %errorlevel% neq 0 (
    echo   ✗ 下载失败，请检查网络连接
    goto :done
)

echo [3/5] 解压源码...

:: 清理旧文件
if exist "%EXT_DIR%\src" rd /s /q "%EXT_DIR%\src" 2>nul

:: 解压
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXT_DIR%' -Force"
if %errorlevel% neq 0 (
    echo   ✗ 解压失败
    goto :done
)

:: 移动 src 内容到根目录
move /y "%EXT_DIR%\customer-service-plugin-main\src\*" "%EXT_DIR%\" >nul 2>nul
rd /s /q "%EXT_DIR%\customer-service-plugin-main" 2>nul
del /f "%ZIP_FILE%" 2>nul

if not exist "%EXT_DIR%\manifest.json" (
    echo   ✗ 解压后找不到 manifest.json
    goto :done
)
echo   ✓ 源码已解压到 %EXT_DIR%

echo [4/5] 配置 Chrome 自动加载...

:: 修改 Chrome 快捷方式，添加 --load-extension 参数
set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "CHROME_EXE_X86=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

if not exist "%CHROME_EXE%" set "CHROME_EXE=%CHROME_EXE_X86%"

:: 查找所有 Chrome 快捷方式
set "SHORTCUT_FOUND=0"
for /f "delims=" %%i in ('dir /b /s "%APPDATA%\Microsoft\Windows\Start Menu\Programs\*Chrome*.lnk" 2^>nul') do (
    call :modify_shortcut "%%i"
    set "SHORTCUT_FOUND=1"
)
for /f "delims=" %%i in ('dir /b /s "%PUBLIC%\Desktop\*Chrome*.lnk" 2^>nul') do (
    call :modify_shortcut "%%i"
    set "SHORTCUT_FOUND=1"
)
for /f "delims=" %%i in ('dir /b /s "%USERPROFILE%\Desktop\*Chrome*.lnk" 2^>nul') do (
    call :modify_shortcut "%%i"
    set "SHORTCUT_FOUND=1"
)

if "%SHORTCUT_FOUND%"=="0" (
    echo   ⚠ 未找到 Chrome 快捷方式
    echo   请手动在 Chrome 快捷方式属性 → 目标 末尾添加：
    echo   --load-extension="%EXT_DIR%"
)

echo [5/5] 完成！
echo.
echo ====================================
echo   安装完成！请按以下步骤操作：
echo ====================================
echo.
echo   1. 完全退出 Chrome
echo      - 关闭所有 Chrome 窗口
echo      - 右下角托盘区找到 Chrome 图标，右键 → 退出
echo      - 任务管理器确认没有 chrome.exe 进程
echo.
echo   2. 通过桌面快捷方式重新打开 Chrome
echo.
echo   3. Chrome 会提示"已加载扩展程序"
echo      → 在 chrome://extensions/ 确认看到
echo      「飞猪客服工具箱」
echo.
echo   4. 如果出现"禁用开发者模式扩展程序"提示
echo      点击「取消」即可保留扩展
echo.
echo   扩展目录: %EXT_DIR%
echo.

goto :done

:modify_shortcut
:: 使用 PowerShell 修改快捷方式
powershell -Command "$s = New-Object -ComObject WScript.Shell; $sc = $s.CreateShortcut('%~1'); if ($sc.Arguments -notlike '*load-extension*') { $sc.Arguments = $sc.Arguments + ' --load-extension=\"%EXT_DIR%\"'; $sc.Save() }"
echo   ✓ 已修改: %~1
goto :eof

:done
pause
