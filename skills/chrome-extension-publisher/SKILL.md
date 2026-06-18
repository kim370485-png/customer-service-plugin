---
name: chrome-extension-publisher
display_name: "Chrome Extension Publisher"
description: 一键发布 Chrome浏览器插件。只需提供新版插件代码（文件夹或zip），自动完成版本更新、打包、发布。
metadata:
  version: 1.0.0
  agent:
    type: tool
    runtime: bash
    context_isolation: execution
    parent_context_access: read-only
---

# Chrome Extension Publisher

一键发布 Chrome浏览器插件到 GitHub，自动打包并分发给所有用户。

## 使用方式

对 agent 说：
- "发布新版本，代码在 ~/Downloads/plugin-v5.5/"
- "更新插件，zip 包在桌面"
- "发布 5.5，插件文件夹是 /path/to/plugin/"

## 前置条件

发布者需要：
1. GitHub 账号（已加入仓库 collaborators）
2. Git 已配置（能 push 到 GitHub）
3. 已安装本 skill

## 完整发布流程

### 1. 初始化（首次使用）

检查本地是否有仓库：
```bash
if [ ! -d "customer-service-plugin" ]; then
  git clone https://github.com/jesse-tzx/customer-service-plugin.git
  cd customer-service-plugin
fi
```

### 2. 获取新版本代码

发布者会提供：
- **文件夹路径**：直接复制
- **zip 文件**：先解压再复制

```bash
# 如果是 zip，先解压
if [ "$INPUT" = *.zip ]; then
  mkdir -p /tmp/plugin-update
  unzip -o "$INPUT" -d /tmp/plugin-update
  INPUT="/tmp/plugin-update"
fi

# 清空 src/ 并复制新代码
rm -rf src/*
cp -r "$INPUT"/* src/

# 清理临时文件
rm -rf /tmp/plugin-update
```

### 3. 确认版本号

读取 manifest.json 中的版本：
```bash
CURRENT_VERSION=$(python3 -c "import json; print(json.load(open('src/manifest.json'))['version'])")
echo "当前版本: $CURRENT_VERSION"
```

**如果发布者指定了版本号**（如"发布 5.5"），更新 manifest.json：
```bash
# macOS
sed -i '' 's/"version": "[^"]*"/"version": "5.5"/' src/manifest.json

# Linux
sed -i 's/"version": "[^"]*"/"version": "5.5"/' src/manifest.json
```

**如果发布者没指定版本号**，询问：
> "当前版本是 5.4，新版本号是什么？"

### 4. 提交并推送

```bash
git add -A
git commit -m "chore: update plugin to v5.5"
git push origin main
```

### 5. 等待 GitHub Actions

推送后，GitHub Actions 会自动：
- 使用 `key.pem` 打包 `.crx`
- 更新 `updates.xml` 中的版本号
- 提交回仓库

等待约 1-2 分钟，然后验证：
```bash
# 检查 GitHub Actions 状态
curl -s "https://api.github.com/repos/jesse-tzx/customer-service-plugin/actions/runs" | grep -A 5 '"status"'

# 检查 updates.xml 是否已更新
curl -s https://raw.githubusercontent.com/jesse-tsx/customer-service-plugin/main/updates.xml | grep version
```

### 6. 通知用户

发布成功后，告诉用户：
```
✅ v5.5 发布成功！

GitHub Actions 已自动完成：
- 打包 extension.crx
- 更新 updates.xml
- 提交到仓库

所有用户的 Chrome 会在几小时内自动更新。
如需立即生效，让用户在 chrome://extensions/ 点击刷新按钮。
```

## 错误处理

| 错误 | 原因 | 解决 |
|------|------|------|
| `git push` 失败 | 没有仓库写权限 | 让用户检查是否已加入 collaborators，或重新登录 git |
| GitHub Actions 失败 | 缺少 `EXTENSION_KEY` secret | 联系仓库管理员（jesse-tzx）配置 secret |
| `updates.xml` 未更新 | Actions 还没跑完 | 等 1-2 分钟再检查，或查看 Actions 日志 |
| `src/manifest.json` 不存在 | 发布者给的代码不完整 | 让发布者确认文件夹包含完整的插件代码 |

## GitHub Actions 配置（仅仓库管理员）

首次使用需要配置：

1. 将 `key.pem` 的内容添加到 GitHub Secrets：
   - 打开 https://github.com/jesse-tzx/customer-service-plugin/settings/secrets/actions
   - 点击 "New repository secret"
   - Name: `EXTENSION_KEY`
   - Value: 粘贴 `key.pem` 的全部内容（包括 `-----BEGIN RSA PRIVATE KEY-----` 和 `-----END RSA PRIVATE KEY-----`）

2. 确保 `.github/workflows/publish.yml` 已提交到仓库

## 示例对话

**用户：** 发布 5.5，代码在 ~/Downloads/plugin-v5.5/

**Agent：**
```
正在检查仓库...
✓ 仓库已就绪

正在复制插件代码...
✓ 已复制到 src/

当前版本：v5.4
即将发布：v5.5

执行以下操作：
1. 更新 src/manifest.json 版本号为 5.5
2. 提交并推送到 GitHub
3. GitHub Actions 自动打包

确认发布吗？
```

**用户：** 确认

**Agent：**
```
✓ 已推送到 GitHub
⏳ 等待 GitHub Actions 打包...
✓ v5.5 发布成功！

所有用户的 Chrome 会在几小时内自动更新。
如需立即生效，让用户打开 chrome://extensions/ 点击刷新按钮。
```

## 技术细节

- **仓库地址**：https://github.com/jesse-tzx/customer-service-plugin
- **更新清单**：https://raw.githubusercontent.com/jesse-tsx/customer-service-plugin/main/updates.xml
- **Extension ID**：njjdclibfaedfofiphakngdnglelphje
- **打包方式**：GitHub Actions 使用 Chrome `--pack-extension` 命令
- **分发方式**：Chrome Enterprise Policy（用户通过 .reg 或 .mobileconfig 安装）
