<!--
Thanks for contributing! Please complete this template.
感谢贡献！请填完本模板后再提交。

Docs: README.md · windows/README.md · windows/SKILL.md · docs/platforms.md
Yuuka currently ships for Windows x64. macOS and Linux sources/checks are inherited; a passing check does not establish native Yuuka support.
优香版当前仅发行 Windows x64。macOS、Linux 源码与检查来自上游继承，检查通过不代表完成优香版原生验收。
Security: loopback CDP only — do not patch official .app / asar / WindowsApps; do not rewrite API keys.
安全：仅本机 CDP；勿改官方安装包；勿静默改写 API。
-->

## Summary / 摘要

<!-- What changed and why? 1–5 bullets. 改了什么、为什么？ -->

-

## Type / 类型

- [ ] Bug fix / 缺陷修复
- [ ] Feature / 新功能
- [ ] Docs / 文档
- [ ] Theme / CSS / visual / 主题或视觉
- [ ] Scripts / install / restore / 脚本或安装恢复
- [ ] Chore / 杂项

## Platform / 平台

- [ ] Windows (current release) / Windows（当前发行平台）
- [ ] Shared runtime / 共享运行时
- [ ] macOS (inherited source) / macOS（继承源码）
- [ ] Linux (inherited source) / Linux（继承源码）
- [ ] Docs / repo only / 仅文档或仓库元数据

## Self-check / 自测

Check what you actually ran. Skip items that do not apply and say so under Notes.
请勾选**实际跑过**的项；不适用的在 Notes 说明。

### Docs-only / 仅文档

- [ ] Links and wording reviewed / 已检查链接与表述

### Inherited macOS checks (when affected) / 继承的 macOS 检查（如适用）

- [ ] `macos/tests/run-tests.sh` passed / 已通过
- [ ] Doctor (optional): `macos/scripts/doctor-macos.sh`
- [ ] Live verify (if inject/CSS/start path): `verify-dream-skin-macos.sh` or Desktop **Verify**
- [ ] Restore / re-apply smoke (if install/restore/start changed) / 若改了安装恢复启动则做过恢复再应用

### Windows (when code under `windows/` changes)

- [ ] `windows/tests/run-tests.ps1` passed / 已通过 Windows 回归测试
- [ ] Relevant `install` / `start` / `verify` / `restore` scripts exercised / 已按改动跑过对应脚本
- [ ] Environment noted below (OS build, Codex source) / 下方注明环境

### Shared runtime (when affected) / 共享运行时（如适用）

- [ ] `node tools/sync-runtime-assets.mjs --check` passed / 平台副本同步检查通过
- [ ] Applicable Node tests and all three `injector.mjs --check-payload` checks passed / 适用的 Node 测试与三端 payload 检查通过
- [ ] Untested native platforms identified under Notes / 在 Notes 中注明尚未实测的原生平台

### User-facing / 用户可见变更

- [ ] Updated `windows/CHANGELOG.md` (and the corresponding changelog for affected inherited platforms) / 已更新 Windows changelog；涉及继承平台时同步其记录
- [ ] If preparing a release, followed `docs/releases/README.md`: full Chinese/English notes and all nine version fields plus related assertions synchronized / 如准备发版，遵循发布规范，提供完整中英文说明并同步九处版本及相关断言
- [ ] N/A — no user-facing change / 无用户可见变更

<!-- Release version fields: macos/VERSION, windows/VERSION, macos/package.json,
macos/scripts/common-macos.sh, macos/scripts/injector.mjs, windows/scripts/injector.mjs,
linux/VERSION, linux/scripts/common-linux.sh, linux/scripts/injector.mjs.
Current release assets: CodexDreamSkinYuuka-Setup-vX.Y.Z.exe and SHA256SUMS.txt. -->

## Security / 安全

- [ ] Does **not** modify official Codex install / asar / signatures / 未修改官方安装与签名
- [ ] Does **not** silently write API Base URL or keys / 未静默写入 API Base URL 或 Key
- [ ] CDP remains loopback-oriented (`127.0.0.1`) where applicable / CDP 仍仅本机回环（如适用）

## Notes / 补充

<!-- Test output summary, screenshots (no private chat), follow-ups. 测试摘要、截图（勿含隐私对话）、后续事项。 -->

-
