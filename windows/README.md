# Codex Dream Skin Yuuka for Windows · v1.9.2

[中文](README.md) · [English](README.en.md)

优香版首个独立 Windows 发行版本。首页使用蔚蓝档案风格壁纸、眨眼与发丝动效、四张任务卡、优香寄语及可保存的今日计划；任务对话页使用纯色背景。主题通过本机 CDP 加载，项目、侧栏、会话和输入框继续使用 Codex 原生控件。

## 运行要求

- Windows 10 或更高版本，x64。
- 从 Microsoft Store 安装、注册到当前用户且已成功启动过的官方 `OpenAI.Codex`。
- Windows PowerShell 5.1 或更高版本。
- Release 安装器包含 Node.js；源码安装需要 Node.js 22+ 和 .NET SDK 8+。

## Release 安装

从 [Releases](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/releases/latest) 下载 `CodexDreamSkinYuuka-Setup-v1.9.2.exe` 和 `SHA256SUMS.txt`，核对摘要后运行安装器。安装按当前用户进行。首次安装、SmartScreen 提示、更新与卸载见 [Windows 安装指南](../docs/install-windows.md)。

打开 **Codex Dream Skin Yuuka** 进入原生主题管理器；右键托盘图标可应用主题、切换已保存主题或恢复外观。双击托盘图标也可打开管理器。

## 源码安装

已有旧定制版请先完成下方迁移。源码覆盖当前优香引擎前，先在**已安装引擎**中关闭自动接管，再退出 Codex、优香托盘和主题管理器：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexDreamSkinYuuka\engine\scripts\manage-auto-launch-dream-skin.ps1" -Disable
```

首次安装没有此引擎时跳过停用步骤。在仓库根目录运行：

```powershell
node .\tools\build-theme-manager.mjs
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

安装器会校验官方 Store 包和运行时、备份受管外观配置，并初始化主题库。默认创建以下入口：

| 入口 | 用途 |
| --- | --- |
| `Codex Dream Skin Yuuka` | 打开原生主题管理器和托盘 |
| `Codex Dream Skin Yuuka - Tray` | 打开托盘控制 |
| `Codex Dream Skin Yuuka - Restore` | 恢复官方外观并关闭受管 CDP 会话 |

默认从端口 `9335` 开始寻找空闲端口。安装命令可加 `-Port 9444` 指定端口，有效范围为 `1024–65535`。脚本使用 `RemoteSigned` 策略，并在部署时校验受管运行时摘要。

更新源码时重复上述停用、退出、构建与安装步骤。安装保留个人主题、图片和设置；此前启用过自动接管的用户安装后再启用。正式 Setup 升级会自动保存、停止并恢复优香版先前的接管设置。

## 启动与验证

右键托盘图标选择应用主题，或从仓库根目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\start-dream-skin.ps1 -PromptRestart
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\verify-dream-skin.ps1 `
  -ScreenshotPath "$env:TEMP\codex-dream-skin.png"
```

Codex 正在运行时，启动器会询问是否重启。验证脚本检查 CDP 身份、皮肤版本、原生控件和装饰层；截图用于检查溢出和对比度。交互验收项见 [QA 清单](references/qa-inventory.md)。

### Windows 通知兼容模式

在支持的 x64 Store 版本上，可让皮肤窗口使用 Codex 的常用配置，使 Windows 激活请求交给同一个应用实例。先从 Codex 托盘菜单完全退出，再从仓库根目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\start-dream-skin.ps1 -UseOfficialProfile
```

使用安装版时，将脚本路径换成 `"$env:LOCALAPPDATA\CodexDreamSkinYuuka\engine\scripts\start-dream-skin.ps1"`。每次新启动时都需指定此选项。此模式下，常用 Codex 会话在应用运行期间可通过本机 CDP 访问。版本范围与调试访问说明见 [运行说明](references/runtime-notes.md) 和 [SECURITY.md](../SECURITY.md)。

## 主题与动态效果

托盘提供背景替换、ZIP 导入、保存与切换主题、动态效果、暂停、重新应用和恢复入口。首次安装默认为「优香 · 千年研讨会」，已保存主题还包含「优香 · 夜间核算」。选择与自定义透明度会保留。

原生管理器可调整当前主题的背景透明度，并将非活动主题移到回收站。操作说明见 [主题管理器](theme-manager/README.md)。

- 背景支持 PNG、JPEG、WebP，上限 10 MiB、单边 16384 像素、总计 5000 万像素。
- 通过“导入主题 ZIP…”加入主题库，再从“已保存主题”选择应用。格式和限制见 [主题管理](../docs/theme-management.md)。
- 动态效果提供跟随系统、关闭、轻量、完整四档及五类开关，见 [动态效果](../docs/theme-motion.md)。
- 优香安装器不注册或接管 `dreamskin://` 协议。网站的一键换肤不会被此版本接管；请下载普通主题 ZIP 后在托盘导入。
- 动效选「完整」并启用角色动态；系统减少动态效果、窗口隐藏和暂停状态会限制动画。专属角色动效只匹配随包壁纸。
- 今日计划支持添加、勾选和删除，保存在当前 Codex 的本机存储，重启后保留；不创建真实 Codex 目标或发送消息。独立桌宠不包含在安装包中。

## Acrylic 窗口材质

Windows 11 22621+ 且系统“透明效果”开启时，可选择 Desktop Acrylic。设置在下次 Dream Skin 启动时生效：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\manage-window-effects.ps1 -Set Acrylic
```

使用 `-Status` 查看设置，使用 `-Set System` 恢复系统材质。

## 官方快捷方式自动接管

该功能默认关闭。完成安装后，用下方受管引擎命令启用监控器，并保护启用时已打开的 Codex 会话。

当前会话结束后，继续使用原版 Codex 任务栏图标即可。监控器识别新启动的官方实例后会关闭并重启一次，以加载主题；这不是官方进程启动前注入，也不能保证零等待。请在接管完成后再输入内容。

**安装版请运行受管引擎中的命令**，以免登录入口依赖源码目录：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexDreamSkinYuuka\engine\scripts\manage-auto-launch-dream-skin.ps1" -Enable -ProtectCurrentSession
```

同一 Windows 用户最多拥有一个监控器和一个实时受管会话，快速用户切换和 RDP 也适用。使用同一脚本的 `-Status` 查看状态，使用 `-Disable` 停止监控并移除启动项。原版和优香版共用操作与自动接管互斥锁，同一 Codex 同时只使用一个引擎。

## 从旧版迁移

旧定制版可能仍使用 `%LOCALAPPDATA%\CodexDreamSkin`。新程序目录为 `%LOCALAPPDATA%\Programs\CodexDreamSkinYuuka`，运行数据目录为 `%LOCALAPPDATA%\CodexDreamSkinYuuka`。

1. 保存输入并完全退出 Codex；用旧版的自动接管管理脚本执行 `-Disable`，再用旧版恢复入口恢复原生外观。脚本恢复可使用旧目录 `engine\scripts\restore-dream-skin.ps1 -RestoreBaseTheme -NoRelaunch`。
2. 安装优香版。旧版仍有外观备份或自动接管启动项时会拒绝继续，并提示先停用旧版。
3. 仅当新数据目录尚不存在、旧活动主题 ID 为 `yuuka-seminar` 或 `yuuka-seminar-night` 时，复制经过校验的主题和偏好。旧目录原样保留；现有新目录绝不被迁移覆盖。
4. 没有 Safe CSS 的旧超天酱内置预设留在旧目录；其他不完整或无效的待迁移文件会报告错误。先修复或备份整理旧主题库，再重试，不要删除数据来绕过检查。
5. 确认新主题后按上节启用优香自动接管。

迁移不复制旧引擎、进程/端口状态、登录信息、聊天、浏览器 profile 或外观恢复备份；新安装建立自己的恢复备份。今日计划仍使用现有 Codex 本机存储键。详见 [优香使用与迁移](../YUUKA-README.md)。

## 恢复

右键托盘图标选择恢复，或运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\restore-dream-skin.ps1 `
  -RestoreBaseTheme -PromptRestart
```

加 `-Uninstall` 同时删除源码安装创建的快捷方式。`-RecoverConfigBackup` 会先保存当前配置，再恢复安装前的完整 `config.toml`，适用于普通外观恢复无法解决的配置损坏。

结束调试会话需完整恢复并重启，或退出全部 Codex 进程后从官方入口打开。暂停主题会保留调试会话。CDP 的本机访问说明见 [SECURITY.md](../SECURITY.md)。

## 文件与日志

| 用途 | 路径 |
| --- | --- |
| 运行时 | `%LOCALAPPDATA%\CodexDreamSkinYuuka\engine` |
| 当前主题 | `%LOCALAPPDATA%\CodexDreamSkinYuuka\active-theme` |
| 主题库 | `%LOCALAPPDATA%\CodexDreamSkinYuuka\themes` |
| 图片归档 | `%LOCALAPPDATA%\CodexDreamSkinYuuka\images` |
| 会话状态 | `%LOCALAPPDATA%\CodexDreamSkinYuuka\state.json` |
| 日志 | `%LOCALAPPDATA%\CodexDreamSkinYuuka\injector.log`、`injector-error.log`、`verify.log` |
| Codex 配置 | `%USERPROFILE%\.codex\config.toml` |

## 排错与开发

| 情况 | 处理 |
| --- | --- |
| 源码安装找不到 Node.js | 用 `node --version` 确认 22+，重新打开 PowerShell |
| 找不到 Store 包 | 用 `Get-AppxPackage -Name OpenAI.Codex` 检查当前用户的安装 |
| 管理器缺失 | 重新构建管理器并安装，或重新运行 Release Setup |
| 指定端口被占用 | 选择其他空闲端口 |
| Codex 更新后主题失效 | 更新并重新安装 Dream Skin，再从托盘应用主题 |
| 找不到 CDP 端点 | 从托盘应用主题后重试，并保留启动与验证日志 |

当前优香版的安装、路径与恢复以本文和 [安装指南](../docs/install-windows.md) 为准；仓库保留的跨平台历史文档可能描述上游默认值。提交 [Bug](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/issues/new/choose) 时附系统、Codex 与 Dream Skin 版本、复现步骤和已去除凭据及私人内容的日志。

在仓库根目录运行回归检查：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\tests\run-tests.ps1
node .\tools\internet-angel-extension.test.mjs
node .\windows\scripts\injector.mjs --check-payload
```

原生管理器的构建与测试见 [开发说明](theme-manager/README.md)，维护约束见 [SKILL.md](SKILL.md)。

## 来源

本版本基于 [EmiyaKatuz 的超天酱版](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose)，保留原 MIT 软件版权声明；特别感谢其维护者与更早的上游贡献者。角色和游戏素材不属于软件 MIT 授权范围，见 [来源与致谢](../CREDITS.md)。
