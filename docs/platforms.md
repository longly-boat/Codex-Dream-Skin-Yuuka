# 平台与开发

[中文](./platforms.md) · [English](./platforms.en.md)

## 平台支持

**Codex Dream Skin Yuuka v1.9.2 仅正式发行 Windows x64。** macOS 与 Linux 保留上游源码和检查，尚未完成优香品牌隔离与原生界面验收，不提供优香版 DMG 或 Linux 安装包。下表中继承平台的信息用于开发参考，不是当前支持承诺。

| 项目 | Windows | macOS | Linux |
| --- | --- | --- | --- |
| 优香版状态 | Windows x64 首发 | 继承源码，未发行 | 继承源码，未发行 |
| 安装方式 | Yuuka Setup.exe、源码脚本 | 上游 DMG / 源码构建流程 | 上游源码 / tar.gz 构建流程 |
| 控制入口 | 系统托盘、原生主题管理器 | 菜单栏 App | shell 命令 |
| Codex 来源 | Microsoft Store `OpenAI.Codex` | 官方 Codex App | 主要适配 AUR `openai-codex-desktop` |
| 运行时 | Setup 内置 Node.js；源码需要 Node.js 22+ | 使用 Codex 内置 Node.js | Node.js 20+ |
| 自定义背景与保存主题 | 支持 | 支持 | 使用当前配置 |
| 主题 ZIP 导入与透明度菜单 | 支持 | 支持 | — |
| 动效设置与恢复 | 支持 | 支持 | 支持 |

Windows 调试会话使用独立的受管 profile，首次使用时可能需要重新登录 Codex。默认主题为「优香 · 千年研讨会」，已保存主题还包含「优香 · 夜间核算」；本版不注册或接管 `dreamskin://` 协议，可通过主题管理器导入普通主题 ZIP。

正式安装与迁移：[Windows 使用说明](../windows/README.md) · [安装指南](./install-windows.md)。继承平台开发参考：[macOS](../macos/README.md) · [Linux](../linux/README.md)；其中旧品牌、路径和发布入口属于上游实现，不能视为优香版安装说明。

## 默认路径

| 平台 | 安装后引擎 | 用户数据与日志 |
| --- | --- | --- |
| Windows 优香版 | `%LOCALAPPDATA%\CodexDreamSkinYuuka\engine` | `%LOCALAPPDATA%\CodexDreamSkinYuuka` |
| macOS（继承源码） | `~/.codex/codex-dream-skin-studio` | `~/Library/Application Support/CodexDreamSkinStudio` |
| Linux（继承源码） | `~/.codex/codex-dream-skin-linux` | `${XDG_STATE_HOME:-~/.local/state}/CodexDreamSkin` |

Windows 安装器与卸载器位于 `%LOCALAPPDATA%\Programs\CodexDreamSkinYuuka`，受管 profile 位于状态目录中的 `cdp-profile/`，已保存主题位于 `themes/`。原版状态目录 `%LOCALAPPDATA%\CodexDreamSkin` 独立保留；迁移前先停用原版自动接管并恢复外观，满足校验后仅复制缺失的优香主题与偏好，不覆盖新数据或复制登录资料。具体边界见 [Windows 迁移说明](../windows/README.md)。

## 共享运行时

共享架构通过本机回环 CDP 向已验证的 Codex 界面加载样式和装饰层。`runtime/` 是共享源，平台脚本负责应用发现、启动、配置与恢复；继承平台仍同步共享资产，避免后续移植时源码漂移。

修改共享样式或脚本后，从仓库根目录同步资产：

```bash
node tools/sync-runtime-assets.mjs
node tools/sync-runtime-assets.mjs --check
```

主题格式与图片配置见[主题管理](./theme-management.md)，动效偏好见[动效设置](./theme-motion.md)，CDP 与路径校验见[安全说明](../SECURITY.md)。

## 开发检查

跨平台 Node 检查建议使用 Node.js 22。以下命令从仓库根目录运行：

```bash
node --test macos/tests/*.test.mjs windows/tests/*.test.mjs tools/*.test.mjs
node tools/sync-runtime-assets.mjs --check
node tools/check-selector-provenance.mjs
node macos/scripts/injector.mjs --check-payload
node windows/scripts/injector.mjs --check-payload
node linux/scripts/injector.mjs --check-payload
```

原生构建与测试使用对应平台环境：

- Windows：PowerShell 5.1 / 7；源码安装前需使用 .NET SDK 8+ [构建主题管理器](../windows/theme-manager/README.md)。
- macOS（继承平台）：`./macos/tests/run-tests.sh`；菜单栏 App 与 DMG 构建见 [macOS 说明](../macos/README.md)，当前工作流只保留适用检查，不发行优香 DMG。
- Linux（继承平台）：归档构建与桌面验证见 [Linux 说明](../linux/README.md)，当前不发行优香 Linux 安装包。

发布步骤见[发布流程](./releases/README.md)，版本历史见[更新记录](../windows/CHANGELOG.md)。当前正式资产仅为 `CodexDreamSkinYuuka-Setup-vX.Y.Z.exe` 与 `SHA256SUMS.txt`；继承平台测试通过不能替代本平台的原生安装和界面验收。
