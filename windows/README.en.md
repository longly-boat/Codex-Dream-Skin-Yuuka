# Codex Dream Skin Yuuka for Windows · v1.9.2

[中文](README.md) · [English](README.en.md)

The first independent Windows Yuuka release brings a Blue Archive-inspired home wallpaper, blinking and hair motion, four task cards, Yuuka messages, and a persistent daily checklist. Task conversations use a solid background. Themes load through local CDP; projects, conversations, the sidebar, and the composer remain native Codex controls.

## Requirements

- Windows 10 or newer, x64.
- Official `OpenAI.Codex` installed from Microsoft Store, registered for the current user, and launched successfully at least once.
- Windows PowerShell 5.1 or newer.
- Release Setup includes Node.js; source installation requires Node.js 22+ and .NET SDK 8+.

## Release installation

Download `CodexDreamSkinYuuka-Setup-v1.9.2.exe` and `SHA256SUMS.txt` from [Releases](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/releases/latest), verify the checksum, and run the installer. Installation is per user. See the [Windows installation guide](../docs/install-windows.en.md) for first launch, SmartScreen prompts, updates, and removal.

Open **Codex Dream Skin Yuuka** to enter the native theme manager. Right-click the tray icon to apply a theme, switch saved themes, or restore the appearance. Double-clicking the icon also opens the manager.

## Source installation

If migrating from an earlier custom build, complete the migration section below first. Before replacing an existing Yuuka runtime from source, disable takeover using the **installed engine**, then exit Codex, the Yuuka tray, and the theme manager:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexDreamSkinYuuka\engine\scripts\manage-auto-launch-dream-skin.ps1" -Disable
```

Skip that stop command on a fresh installation without an engine. Then run from the repository root:

```powershell
node .\tools\build-theme-manager.mjs
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

The installer validates the official Store package and runtime, backs up managed appearance settings, and initializes the theme library. It creates these entries by default:

| Entry | Purpose |
| --- | --- |
| `Codex Dream Skin Yuuka` | Open the native theme manager and tray |
| `Codex Dream Skin Yuuka - Tray` | Open tray controls |
| `Codex Dream Skin Yuuka - Restore` | Restore the stock appearance and close the managed CDP session |

The default port search starts at `9335`. Add `-Port 9444` to the installation command to specify a port in `1024–65535`. Scripts use `RemoteSigned`, and deployment validates the managed runtime checksums.

For source updates, repeat the stop, exit, build, and installation steps. Personal themes, images, and preferences are preserved; re-enable takeover afterward if previously enabled. Release Setup upgrades automatically save, stop, and restore the existing Yuuka takeover preference.

## Launch and verification

Right-click the tray icon and apply the theme, or run from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\start-dream-skin.ps1 -PromptRestart
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\verify-dream-skin.ps1 `
  -ScreenshotPath "$env:TEMP\codex-dream-skin.png"
```

The launcher asks before restarting a running Codex session. Verification checks the CDP identity, skin version, native controls, and decorative layers. Use the screenshot to check overflow and contrast. See the [QA checklist](references/qa-inventory.md) for interaction checks.

### Windows notification compatibility

On supported x64 Store builds, Dream Skin can use the normal Codex profile so Windows activation reaches the same app instance. Quit Codex from its tray menu and run the following from the repository root.

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\start-dream-skin.ps1 -UseOfficialProfile
```

For an installed copy, use `"$env:LOCALAPPDATA\CodexDreamSkinYuuka\engine\scripts\start-dream-skin.ps1"` as the script path. Specify the option each time you start a new session. Your regular Codex session is accessible through local CDP while the app is running in this mode. See [Runtime notes](references/runtime-notes.md) and [SECURITY.md](../SECURITY.md) for supported builds and the local access boundary.

## Themes and motion

The tray provides background replacement, ZIP import, theme saving and switching, motion settings, pause, reapply, and restore. The default is the light Yuuka Seminar theme; Saved Themes also includes Yuuka Night Accounting. Your selection and custom transparency are preserved.

The native manager adjusts the current theme's background transparency and moves inactive themes to the Recycle Bin. See the [theme manager guide](theme-manager/README.en.md).

- Backgrounds support PNG, JPEG, and WebP, up to 10 MiB, 16384 pixels per edge, and 50 million pixels total.
- Use **Import Theme ZIP…** to add a pack to the library, then apply it from **Saved Themes**. See [theme management](../docs/theme-management.en.md) for formats and limits.
- Motion offers System, Off, Subtle, and Full modes plus five effect switches. See [motion settings](../docs/theme-motion.en.md).
- The Yuuka installer does not register or take over the `dreamskin://` protocol. Download an ordinary theme ZIP and import it from the tray instead of using the website's apply link.
- Choose Full motion and enable character effects. Reduced motion, hidden windows, and pause can limit animation; character effects only match the bundled artwork.
- Daily Plan supports adding, checking, and deleting items in the current Codex local storage, including after restart. It does not create actual Codex goals or send messages. A separate desktop pet is not included.

## Acrylic window material

Desktop Acrylic is available on Windows 11 22621+ with system transparency effects enabled. The setting takes effect on the next Dream Skin launch:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\manage-window-effects.ps1 -Set Acrylic
```

Use `-Status` to inspect the setting or `-Set System` to restore the system material.

## Automatic handoff from the official shortcut

This option is off by default. After installation, use the managed engine command below to enable the per-user watcher while protecting the already-open Codex session.

After that session ends, keep using the original Codex taskbar icon. The watcher identifies a newly started official instance and restarts it once to load the theme. This does not inject before the official process starts or guarantee zero delay. Wait for handoff to finish before entering new content.

**Installed copies should use the managed engine command**, keeping login startup independent of the source checkout:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexDreamSkinYuuka\engine\scripts\manage-auto-launch-dream-skin.ps1" -Enable -ProtectCurrentSession
```

Each Windows user can own one watcher and one live managed session, including across Fast User Switching and RDP. Use the same script with `-Status` to inspect the watcher or `-Disable` to stop it and remove its Startup entry. Upstream and Yuuka share operation and takeover locks; use only one theme engine with Codex at a time.

## Migrate from the earlier custom build

Earlier custom builds may use `%LOCALAPPDATA%\CodexDreamSkin`. This edition installs its program under `%LOCALAPPDATA%\Programs\CodexDreamSkinYuuka` and runtime data under `%LOCALAPPDATA%\CodexDreamSkinYuuka`.

1. Save input and fully exit Codex. Disable the old watcher using its manager script with `-Disable`, then restore the stock appearance using the old installation. Its script accepts `engine\scripts\restore-dream-skin.ps1 -RestoreBaseTheme -NoRelaunch`.
2. Install Yuuka. If the old product still owns an appearance backup or takeover startup entry, installation stops and asks you to disable it first.
3. Only when the new data directory does not exist and the old active theme ID is `yuuka-seminar` or `yuuka-seminar-night`, validated themes and preferences are copied. The old directory is retained unchanged; an existing new directory is never overwritten by migration.
4. The old bundled Internet Angel preset without Safe CSS stays in the old directory. Other incomplete or invalid migration files produce an error. Repair or back up and organize the old library before retrying; do not delete data just to bypass validation.
5. Check the new theme, then enable Yuuka takeover as described above.

Migration excludes the old engine, process/port state, login information, chats, browser profiles, and appearance backup. The new installation captures its own recovery backup. Daily Plan keeps the existing Codex local-storage key. See the [Yuuka usage and migration guide](../YUUKA-README.md) (Chinese).

## Restore

Choose restore from the tray menu, or run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\restore-dream-skin.ps1 `
  -RestoreBaseTheme -PromptRestart
```

Add `-Uninstall` to remove shortcuts created by source installation. `-RecoverConfigBackup` saves the current configuration before restoring the complete pre-install `config.toml`; use it for configuration damage that normal appearance recovery cannot resolve.

End the debug session with a full restore and restart, or quit all Codex processes and reopen through the official entry. Pausing the theme keeps the debug session open. See [SECURITY.md](../SECURITY.md) for local CDP access details.

## Files and logs

| Purpose | Path |
| --- | --- |
| Runtime | `%LOCALAPPDATA%\CodexDreamSkinYuuka\engine` |
| Active theme | `%LOCALAPPDATA%\CodexDreamSkinYuuka\active-theme` |
| Theme library | `%LOCALAPPDATA%\CodexDreamSkinYuuka\themes` |
| Image archive | `%LOCALAPPDATA%\CodexDreamSkinYuuka\images` |
| Session state | `%LOCALAPPDATA%\CodexDreamSkinYuuka\state.json` |
| Logs | `%LOCALAPPDATA%\CodexDreamSkinYuuka\injector.log`, `injector-error.log`, `verify.log` |
| Codex configuration | `%USERPROFILE%\.codex\config.toml` |

## Troubleshooting and development

| Situation | Action |
| --- | --- |
| Source installation cannot find Node.js | Confirm 22+ with `node --version`, then reopen PowerShell |
| Store package missing | Check the current user's installation with `Get-AppxPackage -Name OpenAI.Codex` |
| Theme manager missing | Rebuild and reinstall the manager, or rerun Release Setup |
| Specified port occupied | Choose another available port |
| Theme fails after a Codex update | Update and reinstall Dream Skin, then apply from the tray |
| CDP endpoint missing | Apply from the tray, retry, and retain launch and verification logs |

This guide and the [installation guide](../docs/install-windows.en.md) describe the current Yuuka paths and recovery process; retained cross-platform historical documents may describe upstream defaults. When filing a [bug](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/issues/new/choose), include Windows, Codex, and Dream Skin versions, reproduction steps, and logs with credentials and private content removed.

Run regression checks from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\tests\run-tests.ps1
node .\tools\internet-angel-extension.test.mjs
node .\windows\scripts\injector.mjs --check-payload
```

See the [native manager guide](theme-manager/README.en.md) for its build and tests, and [SKILL.md](SKILL.md) for maintainer constraints.

## Credits

Built on [EmiyaKatuz's Internet Angel fork](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose), retaining the original MIT software copyright. Special thanks to its maintainers and earlier upstream contributors. Character and game material is excluded from the software license; see [Credits](../CREDITS.md).
