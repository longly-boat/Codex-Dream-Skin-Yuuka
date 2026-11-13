# Platforms and development

[中文](./platforms.md) · [English](./platforms.en.md)

## Platform support

**Codex Dream Skin Yuuka v1.9.2 ships for Windows x64 only.** macOS and Linux retain upstream sources and checks but have not completed Yuuka product isolation or native UI acceptance testing. No Yuuka DMG or Linux package is released. The inherited-platform columns below are development references, not current support commitments.

| Item | Windows | macOS | Linux |
| --- | --- | --- | --- |
| Yuuka status | First Windows x64 release | Inherited source, no release | Inherited source, no release |
| Installation | Yuuka Setup.exe, source scripts | Upstream DMG / source build workflow | Upstream source / tar.gz build workflow |
| Controls | System tray, native theme manager | Menu-bar app | Shell commands |
| Codex source | Microsoft Store `OpenAI.Codex` | Official Codex app | Primarily AUR `openai-codex-desktop` |
| Runtime | Setup bundles Node.js; source requires Node.js 22+ | Uses Node.js from Codex | Node.js 20+ |
| Custom backgrounds and saved themes | Supported | Supported | Uses current configuration |
| Theme ZIP import and transparency menu | Supported | Supported | — |
| Motion settings and restore | Supported | Supported | Supported |

Windows debugging sessions use a separate managed profile, which may require signing in to Codex on first use. Yuuka Seminar is the default theme; Yuuka Night Accounting is also saved in the library. This release does not register or take over `dreamskin://`; use the theme manager to import ordinary theme ZIP files.

Supported installation and migration: [Windows guide](../windows/README.en.md) · [installation instructions](./install-windows.en.md). Inherited development references: [macOS](../macos/README.en.md) · [Linux](../linux/README.md#english). Their old branding, paths, and release links describe the upstream implementation and are not Yuuka installation instructions.

## Default paths

| Platform | Installed engine | User data and logs |
| --- | --- | --- |
| Windows Yuuka | `%LOCALAPPDATA%\CodexDreamSkinYuuka\engine` | `%LOCALAPPDATA%\CodexDreamSkinYuuka` |
| macOS (inherited source) | `~/.codex/codex-dream-skin-studio` | `~/Library/Application Support/CodexDreamSkinStudio` |
| Linux (inherited source) | `~/.codex/codex-dream-skin-linux` | `${XDG_STATE_HOME:-~/.local/state}/CodexDreamSkin` |

The Windows installer and uninstaller live in `%LOCALAPPDATA%\Programs\CodexDreamSkinYuuka`. The state directory stores the managed profile in `cdp-profile/` and saved themes in `themes/`. The original `%LOCALAPPDATA%\CodexDreamSkin` state directory is retained separately. Before migration, disable the original takeover watcher and restore its appearance. Validated migration copies only missing Yuuka themes and preferences; it does not overwrite new data or copy sign-in profiles. See the [Windows migration guide](../windows/README.en.md) for the precise scope.

## Shared runtime

The shared architecture loads styles and decorations into a verified Codex renderer over loopback CDP. `runtime/` holds the shared sources; platform scripts handle app discovery, startup, configuration, and restoration. Inherited platforms still receive synchronized assets to prevent source drift before future porting work.

After editing shared styles or scripts, synchronize assets from the repository root:

```bash
node tools/sync-runtime-assets.mjs
node tools/sync-runtime-assets.mjs --check
```

See [theme management](./theme-management.en.md) for theme formats and image settings, [motion settings](./theme-motion.en.md) for preferences, and [security information](../SECURITY.md) for CDP and path validation.

## Development checks

Node.js 22 is recommended for cross-platform Node checks. Run these commands from the repository root:

```bash
node --test macos/tests/*.test.mjs windows/tests/*.test.mjs tools/*.test.mjs
node tools/sync-runtime-assets.mjs --check
node tools/check-selector-provenance.mjs
node macos/scripts/injector.mjs --check-payload
node windows/scripts/injector.mjs --check-payload
node linux/scripts/injector.mjs --check-payload
```

Use the corresponding platform environment for native builds and tests:

- Windows: PowerShell 5.1 / 7; source installation requires .NET SDK 8+ to [build the theme manager](../windows/theme-manager/README.en.md).
- macOS (inherited): `./macos/tests/run-tests.sh`; see the [macOS guide](../macos/README.en.md) for menu-bar app and DMG builds. The current workflow retains applicable checks but does not release a Yuuka DMG.
- Linux (inherited): see the [Linux guide](../linux/README.md#english) for archive builds and desktop verification. No Yuuka Linux package is currently released.

See the [release process](./releases/README.md) and [change history](../windows/CHANGELOG.md). Current release assets are limited to `CodexDreamSkinYuuka-Setup-vX.Y.Z.exe` and `SHA256SUMS.txt`. Passing inherited-platform tests does not replace native installation and UI acceptance testing on that platform.
