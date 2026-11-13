# 贡献指南

<p align="center">
  <strong>中文</strong> · <a href="./CONTRIBUTING.en.md">English</a>
</p>

感谢你为 Codex Dream Skin Yuuka 提交改进。这个项目通过本机回环 CDP 给官方 Codex 桌面应用加载优香主题。v1.9.2 是本 fork 的 Windows x64 首发；macOS 和 Linux 源码继承自上游，尚未完成优香版原生验收，也不发行对应安装包。请先确定改动属于 Windows、共享运行时还是继承平台。

## 开始之前

1. 阅读[项目 README](../README.md)、[平台对照](../docs/platforms.md)、[Windows 使用说明](../windows/README.md)与 [`windows/SKILL.md`](../windows/SKILL.md)。
2. 搜索本仓库的[现有 Issue](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/issues)和[开放 PR](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/pulls)。相同文件已有活跃改动时，优先补充原讨论，或把新方案拆成不重叠的小改动。
3. 从 `longly-boat/Codex-Dream-Skin-Yuuka` 最新的 `main` 创建分支。一个 PR 只解决一个问题，不要把新主题、运行时修复和无关整理混在一起。

## 提交 Issue

请使用仓库的 [Bug 或功能建议表单](./ISSUE_TEMPLATE/)。提交前先搜索重复项。

Bug 报告应包含：

- 目标平台、系统版本和 Codex 安装来源。
- 能稳定复现的步骤，以及期望结果和实际结果。
- 相关日志或截图。请先删除密钥、`auth.json`、中转 token、用户名路径和私人对话。
- 最近一次已知正常的版本或提交，如果能够确认。

功能建议应说明要解决的使用场景、期望行为、考虑过的替代方案，以及 Windows、共享代码或继承平台的范围。继承平台的反馈可用于后续移植，但不代表已有优香版支持承诺。

## 开发与验证

请先 fork 本仓库，并让分支基于优香仓库最新的 `main`。尽量复用现有脚本和平台 helper，不要为小改动增加新依赖。

### 继承的 macOS 代码（涉及该平台时）

运行完整测试：

```bash
(cd macos && npm test)
```

环境与安装诊断：

```bash
macos/scripts/doctor-macos.sh
```

改动注入、CSS、启动或恢复流程时，还要运行 `macos/scripts/verify-dream-skin-macos.sh`，并检查首页与普通任务页。

### Windows（当前发行平台）

运行 Windows 回归测试：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\tests\run-tests.ps1
```

改动安装、启动、注入或恢复流程时，请运行对应脚本和 `windows/scripts/verify-dream-skin.ps1`，并在 PR 中注明 Windows 版本与 Codex 来源。

### 共享运行时

修改 `runtime/` 后通过 `node tools/sync-runtime-assets.mjs` 同步平台副本，再运行 `node tools/sync-runtime-assets.mjs --check`、适用的 Node 测试与三端 `injector.mjs --check-payload`。继承平台的检查用于防止共享代码漂移；原生界面未实测时必须明确说明，不将 CI 通过写成该平台已支持。

### 仅文档或仓库元数据

检查所有新增或修改的链接与命令，并运行：

```bash
git diff --check
```

## 改动约束

- Shell、PowerShell、JavaScript、JSON 和 CSS 使用两个空格缩进。Shell 入口沿用 `set -euo pipefail`，Node 文件使用 ESM，脚本名称使用 kebab-case。
- 为受影响的安装、启动、注入、验证、暂停或恢复行为补充测试。配置变更要覆盖中文或其他非 ASCII 项目名，并保留无关 TOML 内容。
- `config.toml` 必须按严格 UTF-8 读取，原子写入，并保留可恢复备份。不要使用依赖系统默认编码的 API 重写它。
- CDP 只能绑定本机回环地址。不要修改官方 `.app`、WindowsApps、`app.asar`、代码签名、API Key 或 Base URL。
- 只提交这次改动需要的文件。不要带入日志、临时目录、构建产物、私人截图或本机配置。

## 提交 PR

1. 使用 `type(scope): summary` 标题，例如 `fix(windows): preserve UTF-8 config on restore`。
2. 填完整 [PR 模板](./pull_request_template.md)，只勾选实际完成的检查。平台检查受环境限制时，在 Notes 写清具体限制，并提供能完成的静态检查或夹具测试结果。
3. 用 `Closes #123` 关联对应 Issue。视觉改动要附首页和任务页截图，截图中不能包含私人对话或凭证。
4. 用户可见的 Windows 改动应更新 [`windows/CHANGELOG.md`](../windows/CHANGELOG.md)。涉及继承平台时更新对应平台记录。发布版本必须遵循[发布规范](../docs/releases/README.md)：提供完整中英文说明，并同步 `macos/VERSION`、`windows/VERSION`、`macos/package.json`、`macos/scripts/common-macos.sh`、`macos/scripts/injector.mjs`、`windows/scripts/injector.mjs`、`linux/VERSION`、`linux/scripts/common-linux.sh`、`linux/scripts/injector.mjs` 九处版本及相关断言；不能只提升单个平台版本。
5. 提交前重新检查 diff、测试结果和分支与本仓库 `main` 的差异，确认 PR 中没有无关提交。

维护者可能要求缩小范围、补充验证或解决与其他开放 PR 的重叠。请继续在原 PR 更新，不要为同一改动重复开多个 PR。

本 fork 继承了[超天酱项目](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose)的引擎与工程基础。保留原作者版权、MIT 许可证和历史贡献记录；优香版的反馈与 PR 提交到本仓库。
