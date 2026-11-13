# Windows 优香版安装与更新 · v1.9.2

[中文](install-windows.md) · [English](install-windows.en.md)

优香版首个独立 Windows 发行版本，适用于 Windows 10+ x64。Release 安装器包含所需运行时，按当前用户安装到 `%LOCALAPPDATA%\Programs\CodexDreamSkinYuuka`。首次默认为浅色「优香 · 千年研讨会」，主题库同时提供深色「夜间核算」。

## 首次安装

1. 从 Microsoft Store 安装官方 `OpenAI.Codex`，成功启动一次后退出。
2. 从 [Releases](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/releases/latest) 下载 `CodexDreamSkinYuuka-Setup-v1.9.2.exe` 和 `SHA256SUMS.txt`，核对安装包的 SHA-256。
3. 双击安装器并完成向导。
4. 从开始菜单打开 **Codex Dream Skin Yuuka**，右键托盘图标选择应用主题。Codex 已运行时，按提示保存输入并确认重启。

### SmartScreen 提示

当前安装包尚未代码签名，下载后可能显示“Windows 已保护你的电脑”。核对文件名、仓库来源和 SHA-256 后，选择“更多信息 → 仍要运行”。组织策略限制运行时，请联系管理员或使用组织批准的分发方式，并保持系统防护开启。

安装器按当前用户运行；遇到意外的管理员密码提示时，取消并核对下载来源。

## 从旧定制版迁移

此前本机定制版可能使用 `%LOCALAPPDATA%\CodexDreamSkin`。先保存输入并完全退出 Codex，用**旧版**的自动接管脚本关闭监控，再用旧版恢复入口恢复原生外观；脚本入口分别是旧目录中的 `engine\scripts\manage-auto-launch-dream-skin.ps1 -Disable` 和 `engine\scripts\restore-dream-skin.ps1 -RestoreBaseTheme -NoRelaunch`。

新版不覆盖旧安装。仅在新数据目录尚不存在、旧活动主题为优香时，自动复制校验通过的主题、动效、透明度、语言等偏好；没有 Safe CSS 的旧超天酱内置预设留在原目录。旧目录保留，不复制引擎、登录资料、聊天、进程状态、浏览器 profile 或配置备份。若新目录已存在，迁移不会覆盖它。无效主题或偏好会报错，应先修复源数据再重试。

旧版仍有外观备份或自动接管启动项时，安装会停止并提示。两版可保留各自文件，但同一 Codex 同时只使用一个主题引擎。详细步骤见 [优香使用与迁移](../YUUKA-README.md)。

## 日常使用

| 入口 | 操作 |
| --- | --- |
| 开始菜单或桌面的 Codex Dream Skin Yuuka | 打开原生主题管理器 |
| 双击托盘图标 | 打开同一管理器 |
| 右键托盘图标 | 应用主题、换图、导入 ZIP、保存与切换主题、动态效果、暂停和恢复 |

管理器支持当前主题的背景透明度设置，以及将非活动主题移到回收站。主题、图片和设置位于 `%LOCALAPPDATA%\CodexDreamSkinYuuka`。

优香安装器不注册 `dreamskin://` 协议，网站的一键换肤不会由此版本接管。导入时选择“导入主题 ZIP…”，成功后从“已保存主题”选择应用。包格式、图片大小和手动目录操作见 [主题管理](theme-management.md)，动画选项见 [动态效果](theme-motion.md)。

## 继续使用原版任务栏入口

自动接管默认关闭。安装后执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexDreamSkinYuuka\engine\scripts\manage-auto-launch-dream-skin.ps1" -Enable -ProtectCurrentSession
```

启用时已打开的会话受到保护。该会话结束后，从原版 Codex 任务栏图标新启动时，监控器会识别并重启一次以加载主题；请等接管完成后再输入。同一脚本使用 `-Status` 查看状态、`-Disable` 关闭接管。安装向导中的“登录时启动”只启动优香托盘，与接管设置是两回事。

## 更新

1. 下载新版 Setup.exe 和 `SHA256SUMS.txt`，核对摘要。
2. 保存输入，关闭 Codex 并退出优香托盘和主题管理器。
3. 运行新版安装器，覆盖现有安装。
4. 重新打开 Codex Dream Skin Yuuka，从托盘应用主题。

更新保留活动主题、主题库、图片和配置备份。Setup 会在维护前停止当前优香监控器，完成或失败后恢复此前启用设置；恢复失败会报错。**源码更新**需自行先关闭接管，见 [源码说明](../windows/README.md)。新下载的安装包可能再次触发 SmartScreen。

托盘的“检查更新”只访问 `longly-boat/Codex-Dream-Skin-Yuuka` 的 GitHub Releases；没有发布版本时显示“暂无发布版本”，不会跳回上游下载。下载与安装由用户完成。

## 恢复与卸载

右键托盘图标选择恢复，按提示关闭并重新打开 Codex，即可恢复官方外观并结束调试会话。暂停皮肤会保留调试会话，CDP 的本机访问说明见 [SECURITY.md](../SECURITY.md)。

在“设置 → 应用 → 已安装的应用”卸载 Codex Dream Skin Yuuka。卸载器先恢复外观并关闭受管会话；恢复失败时会停止并保留运行文件供重试。主题和图片默认保留。确认已备份且不再需要后，可手动删除 `%LOCALAPPDATA%\CodexDreamSkinYuuka`。

## 常见问题

| 情况 | 处理 |
| --- | --- |
| SmartScreen 没有“仍要运行” | 联系管理员或改用组织批准的分发渠道；报告问题时附 Windows 版本、提示内容和安装包摘要 |
| 提示找不到 Node.js 或管理器 | 重新运行最新 Release Setup，并保留安装日志 |
| 官方 Store 包缺失或身份无法验证 | 确认 Codex 来自 Microsoft Store、注册在当前用户下，并已成功启动一次 |
| `config.toml` 语法报错 | 备份后修正提示的 TOML 语法；合法多行数组受支持 |
| Codex 更新后主题失效 | 退出托盘、重新运行最新 Setup，再从托盘应用主题 |

源码安装、端口与 Acrylic 设置见 [Windows 开发与使用说明](../windows/README.md)。提交 [Bug](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/issues/new/choose) 时，请附版本、复现步骤和已去除凭据及私人内容的日志。

本版本基于超天酱版和更早的 Dream Skin 上游，保留软件许可与作者致谢，见 [CREDITS](../CREDITS.md)。
