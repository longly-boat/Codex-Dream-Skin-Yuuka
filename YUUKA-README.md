# 优香主题：使用与迁移

**v1.9.2 优香版首发** · [下载与校验文件](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/releases/tag/v1.9.2) · [中文版本说明](docs/releases/v1.9.2.md) · [English release and migration notes](docs/releases/v1.9.2-en.md)

安装器为 Windows x64 提供，内置 Node.js 和自包含主题管理器。下载同一 Release 的 Setup 与 `SHA256SUMS.txt`，核对摘要后运行。v1.9.2 安装器未做代码签名，Windows 可能显示未知发布者或 SmartScreen 提示。

## Windows 身份

| 项目 | 优香版 |
|---|---|
| 显示名称 | Codex Dream Skin Yuuka |
| 安装目录 | `%LOCALAPPDATA%\Programs\CodexDreamSkinYuuka` |
| 运行数据 | `%LOCALAPPDATA%\CodexDreamSkinYuuka` |
| 更新仓库 | `longly-boat/Codex-Dream-Skin-Yuuka` |
| 首发安装包 | `CodexDreamSkinYuuka-Setup-v1.9.2.exe` |

检查更新仅查询本仓库，不会回退到上游更新源。安装器不注册 `dreamskin://`，可用管理器导入本地 ZIP。原版和优香版可以保留各自安装文件，但同一 Codex 同时只使用一个主题引擎；操作锁和自动接管锁跨产品共享。

## 从此前本机优香定制版迁移

此前定制版沿用了 `%LOCALAPPDATA%\CodexDreamSkin`。新安装器不会直接覆盖它：

1. 保存当前输入并完全退出 Codex。
2. 在旧版中关闭自动接管；使用旧版恢复入口恢复原生外观。若通过脚本管理，依次运行旧目录 `engine\scripts\manage-auto-launch-dream-skin.ps1 -Disable` 和 `engine\scripts\restore-dream-skin.ps1 -RestoreBaseTheme -NoRelaunch`。
3. 安装新的 Yuuka 包。旧版仍保有外观备份或自动接管入口时，新版会停止并提示先停用旧版，不会擅自结束未知进程。
4. 新数据目录首次创建时，若旧活动主题是优香，自动复制有效的活动主题、已保存主题、动效、透明度、语言和暂停偏好；不覆盖已存在的新目录。旧目录原样保留。
5. 从「Codex Dream Skin Yuuka」打开管理器，确认主题，再启用自动接管。此后可继续从原版 Codex 任务栏入口启动；接管仍需一次重启。

迁移不复制引擎、PID、端口状态、登录配置、聊天、浏览器 profile 或配置备份。新安装会为当前 Codex 配置建立自己的恢复备份。今日计划继续使用现有 Codex 本机存储键，不因主题工具改名而清空。清除 Codex 应用数据会清除该清单。

## 首页与动效

默认启用「优香 · 千年研讨会」，「已保存主题」提供深色「夜间核算」。启动时保留所选主题、定制壁纸与透明度。

动态设置选「完整」并启用「角色反应」可查看眨眼和发丝微动。任务页保持纯色；窗口隐藏、暂停或系统减少动态效果时，动画停止或简化。角色动画以主题 ID 和壁纸哈希匹配，不会把眼睛贴到其他图片上。

- Workspace 对应原生项目，继续使用原生展开、新建和项目菜单。
- 首页四张任务卡下方显示优香同人寄语，点击「换一句」切换。
- 今日计划支持 Enter/添加、勾选、删除，即时保存，最多 100 项、每项 120 字。所有项目共用个人清单，不自动跨日清空，也不会发送聊天或创建 Codex 目标。

单独主题 ZIP 只包含 `theme.json`、`theme.css`、`background.png`；专属动效与工作台需要优香引擎。[独立优香桌宠的源图、预览与构建工具](pets/yuuka/README.md) 已单独公开，通过分享页添加到自己的桌宠库，不由主题安装包导入账号。

## 源码构建与验证

需要 Windows、Node.js 22、.NET 8 SDK 和 Inno Setup 6.7.1。运行安装包不需要这些开发依赖。原生管理器详情见 [管理器说明](windows/theme-manager/README.md)。

从源码手动覆盖现有引擎前，先关闭优香自动接管并退出管理器；正式 Setup 的升级流程会自动保存、停用并恢复原先的接管设置。

```powershell
node tools/sync-runtime-assets.mjs --check
node tools/build-theme-manager.mjs
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File windows/tests/run-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File windows/tests/installer-static.tests.ps1
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File windows/installer/build-release.ps1
```

安装包构建校验默认主题、浅深预设、图标与 Node 下载摘要。发布工作流只允许本仓库发布 Windows 包，要求九处版本一致、版本递增、对应中英版本说明和正确 tag，不覆盖既有公开 Release。macOS/Linux 保留上游代码与共享资源，未作为优香版支持平台或安装包提供。

## 来源与发布范围

特别感谢 [超天酱版的维护者与贡献者](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose) 开放主题引擎、安装与接管、动效及管理器实现。保留原有作者版权与 [LICENSE](LICENSE)，完整来源见 [CREDITS](CREDITS.md)。壁纸为 AI 同人图；角色与游戏标识权益归各自权利人。

千年徽记参考 [Blue Archive Wiki 的 Millennium 图形](https://static.wikitide.net/bluearchivewiki/2/2a/Millennium.png)，小图标采用自行绘制的光环、档案夹、计算器等图形。不会宣称游戏标识为原创或获得官方授权。

`TASK_PROGRESS.md`、`.local-evidence/`、个人桌宠配置、一次性本机修复脚本和旧 `dist/` 不属于公开发行内容。公开桌宠文件仅在 `pets/yuuka/`，不包含私人账号记录；桌宠素材版本与 Windows 安装器版本分别管理。

优香版是纯 vibe coding、AI 辅助实现的定制项目。如果遇到 bug，抱歉给你带来不便；请通过 [Issues](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/issues) 附上复现步骤、Codex 与主题版本，帮助定位问题。
