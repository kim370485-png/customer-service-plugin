# 飞猪客服工具箱 - 安装与更新指南

> 当前版本：v5.9 | 扩展 ID：`fmoadjiolfncoiahhmmjmgdoniiagohj`

---

## 客服小二安装（一次性操作）

安装后，后续所有版本更新由 Chrome 自动完成，无需再操作。

### Windows

1. 下载以下两个文件到**同一个文件夹**（比如桌面）：
   - [install-windows.bat](./install-external/install-windows.bat)（右键 → 另存为）
   - [fmoadjiolfncoiahhmmjmgdoniiagohj.json](./install-external/fmoadjiolfncoiahhmmjmgdoniiagohj.json)（右键 → 另存为）
2. 双击运行 `install-windows.bat`
3. **完全退出 Chrome**：
   - 关闭所有 Chrome 窗口
   - 右下角任务栏托盘区域，找到 Chrome 图标，右键 → 退出
4. 重新打开 Chrome
5. Chrome 会弹出提示"已添加新的扩展程序" → 点击**启用扩展程序**
6. 打开 `chrome://extensions/` 确认看到"飞猪客服工具箱" ✅

### Mac

**方式一：描述文件安装（推荐）**

1. 下载 [install.mobileconfig](./install.mobileconfig)（右键 → 另存为，保存到桌面）
2. 双击打开 → 系统设置会自动打开 → 点击「安装」
3. **完全退出 Chrome**（⌘Q）
4. 重新打开 Chrome
5. 打开 `chrome://extensions/` 确认看到"飞猪客服工具箱" ✅

**方式二：手动安装（备选）**

如果描述文件被 MDM 策略拦截，可以用手动方式：

1. 下载 [install-mac.sh](./install-external/install-mac.sh) 和 [fmoadjiolfncoiahhmmjmgdoniiagohj.json](./install-external/fmoadjiolfncoiahhmmjmgdoniiagohj.json) 到同一个文件夹
2. 打开终端，运行 `bash install-mac.sh`
3. 完全退出 Chrome（⌘Q）→ 重新打开
4. Chrome 弹出确认框 → 点击"启用扩展程序"

---

## 自动更新机制

安装完成后，Chrome 会每隔约 5 小时自动检查更新。当管理员发布新版本时：

- Chrome **自动下载并安装**新版本
- 客服小二**无需任何操作**
- 如需立即更新：打开 `chrome://extensions/` → 开启开发者模式 → 点击左上角"更新"按钮

---

## 管理员发布新版本

### 方式一：本地脚本发版

前提：本机已安装 Chrome，且有 `key.pem` 文件。

```bash
cd customer-service-plugin
./publish.sh 6.0
```

脚本自动完成：更新 manifest 版本 → 打包 .crx → 更新 updates.xml → git push。

### 方式二：GitHub Actions 自动发版（推荐）

在 GitHub 仓库网页上直接编辑 `src/manifest.json` 的版本号 → Commit → GitHub Actions 自动打包 .crx 并更新 updates.xml。

**首次配置**（仅一次）：
1. 打开仓库 → Settings → Secrets and variables → Actions → New repository secret
2. Name：`EXTENSION_KEY`
3. Value：联系管理员获取 `key.pem` 文件内容
4. 保存

之后每次修改 `src/manifest.json` 的版本号并 push，Actions 自动完成发版。

---

## 故障排查

| 问题 | 原因 | 解法 |
|------|------|------|
| Windows 安装后扩展未出现 | Chrome 未完全退出 | 任务管理器结束所有 chrome.exe 进程后重开 |
| Mac mobileconfig 安装失败 | 旧描述文件冲突 | 系统设置 → 描述文件 → 删除旧的「飞猪客服工具箱」→ 再装新的 |
| Mac mobileconfig 被 MDM 拦截 | 阿里郎 MDM 阻止 | 改用方式二（终端手动安装） |
| 扩展出现但被禁用 | 企业管理策略拦截 | 联系 IT 将 `fmoadjiolfncoiahhmmjmgdoniiagohj` 加入白名单 |
| 版本不更新 | Chrome 缓存 | `chrome://extensions/` → 手动点"更新" |

---

## 文件说明

| 文件 | 用途 |
|------|------|
| `src/` | 插件源码 |
| `extension.crx` | 打包后的插件（由 publish.sh 或 GitHub Actions 生成） |
| `updates.xml` | Chrome 自动更新清单 |
| `install.mobileconfig` | Mac 安装描述文件 |
| `install-external/install-windows.bat` | Windows 安装脚本 |
| `install-external/fmoadjiolfncoiahhmmjmgdoniiagohj.json` | Windows 扩展配置 |
| `install-user.reg` | Windows 注册表（备选方案，需要企业环境） |
| `install.reg` | Windows 注册表（备选方案，需要管理员权限） |
| `publish.sh` | 本地一键发布脚本 |
