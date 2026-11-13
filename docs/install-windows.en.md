# Windows Yuuka installation and updates · v1.9.2

[中文](install-windows.md) · [English](install-windows.en.md)

The first independent Windows Yuuka release supports Windows 10+ x64. Setup includes the required runtime and installs per user under `%LOCALAPPDATA%\Programs\CodexDreamSkinYuuka`. The light Yuuka Seminar theme is selected initially, with the dark Night Accounting theme also saved in the library.

## First installation

1. Install official `OpenAI.Codex` from Microsoft Store, launch it successfully once, then exit.
2. Download `CodexDreamSkinYuuka-Setup-v1.9.2.exe` and `SHA256SUMS.txt` from [Releases](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/releases/latest), and verify the installer's SHA-256.
3. Run the installer and complete the wizard.
4. Open **Codex Dream Skin Yuuka** from the Start menu, then right-click its tray icon and apply the theme. If Codex is running, save input and confirm the requested restart.

### SmartScreen prompts

Current packages are unsigned and may show **Windows protected your PC**. Verify the filename, repository source, and SHA-256, then choose **More info → Run anyway**. When organization policy restricts execution, contact an administrator or use an approved distribution method, keeping system protection enabled.

Setup runs per user. Cancel any unexpected administrator password prompt and verify the download source.

## Migrate from the earlier custom build

Earlier custom builds may use `%LOCALAPPDATA%\CodexDreamSkin`. Save input and fully exit Codex. Disable takeover using the **old** installation, then restore its stock appearance. The old scripts are `engine\scripts\manage-auto-launch-dream-skin.ps1 -Disable` and `engine\scripts\restore-dream-skin.ps1 -RestoreBaseTheme -NoRelaunch`.

The new edition does not overwrite the old installation. Only when the new data directory does not exist and the old active theme is Yuuka, validated themes, motion, transparency, language, and related preferences are copied. The old bundled Internet Angel preset without Safe CSS remains in the original directory. The old directory is preserved; engines, credentials, chats, process state, browser profiles, and configuration backups are not copied. An existing new directory is never overwritten by migration. Invalid themes or preferences must be repaired before retrying.

Installation stops if the old product still owns an appearance backup or takeover startup entry. Both products can retain their own files, but use only one theme engine with Codex at a time. See the [Yuuka migration guide](../YUUKA-README.md) (Chinese).

## Daily use

| Entry | Action |
| --- | --- |
| Codex Dream Skin Yuuka in the Start menu or on the desktop | Open the native theme manager |
| Double-click the tray icon | Open the same manager |
| Right-click the tray icon | Apply themes, replace backgrounds, import ZIPs, save and switch themes, configure motion, pause, or restore |

The manager adjusts the current theme's background transparency and moves inactive themes to the Recycle Bin. Themes, images, and preferences live under `%LOCALAPPDATA%\CodexDreamSkinYuuka`.

The Yuuka installer does not register `dreamskin://`, so website apply links are not handled by this edition. Choose **Import Theme ZIP…**, then apply the imported theme from **Saved Themes**. See [theme management](theme-management.en.md) for pack formats, image limits, and manual directory placement, and [motion settings](theme-motion.en.md) for animation options.

## Keep the original taskbar entry

Automatic takeover is off by default. After installation, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexDreamSkinYuuka\engine\scripts\manage-auto-launch-dream-skin.ps1" -Enable -ProtectCurrentSession
```

The already-open session is protected. After it ends, opening Codex from its original taskbar icon lets the watcher identify and restart the new instance once to load the theme. Wait until handoff finishes before typing. Use the same script with `-Status` to inspect it or `-Disable` to turn it off. Setup's login-startup option starts the Yuuka tray only; it is separate from takeover.

## Updates

1. Download the new Setup.exe and `SHA256SUMS.txt`, and verify the checksum.
2. Save input, close Codex, and exit the Yuuka tray and theme manager.
3. Run the new installer over the existing installation.
4. Reopen Codex Dream Skin Yuuka and apply the theme from the tray.

Updates preserve the active theme, library, images, and configuration backups. Setup stops the existing Yuuka watcher before maintenance and restores its previous enabled preference on success or failure; restoration errors are reported. **Source updates** require you to disable takeover yourself first; see the [source guide](../windows/README.en.md). A newly downloaded installer may trigger SmartScreen again.

The tray's **Check for updates** only queries `longly-boat/Codex-Dream-Skin-Yuuka` releases. It reports **No releases published yet.** when none exists and never falls back to an upstream download. Users perform the download and installation.

## Restore and uninstall

Choose restore from the tray menu, then follow the prompts to close and reopen Codex. This restores the stock appearance and ends the debug session. Pausing the skin keeps that session open. See [SECURITY.md](../SECURITY.md) for local CDP access details.

Uninstall Codex Dream Skin Yuuka through **Settings → Apps → Installed apps**. The uninstaller first restores the appearance and closes the managed session; a recovery failure stops removal and preserves runtime files for another attempt. Themes and images are kept by default. After backing up anything needed, you can manually remove `%LOCALAPPDATA%\CodexDreamSkinYuuka`.

## Troubleshooting

| Situation | Action |
| --- | --- |
| SmartScreen has no **Run anyway** option | Contact an administrator or use an approved channel; include Windows version, prompt details, and installer checksum when reporting |
| Node.js or the manager is missing | Rerun the latest Release Setup and retain installation logs |
| Official Store package missing or unverifiable | Confirm Codex came from Microsoft Store, is registered for this user, and has launched successfully once |
| `config.toml` syntax error | Back up the file and fix the reported TOML syntax; valid multiline arrays are supported |
| Theme fails after a Codex update | Exit the tray, rerun the latest Setup, and apply from the tray |

See the [Windows development and usage guide](../windows/README.en.md) for source installation, ports, and Acrylic. When filing a [bug](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/issues/new/choose), include versions, reproduction steps, and logs with credentials and private content removed.

Built on the Internet Angel fork and earlier Dream Skin contributors, retaining software licensing and attribution. See [Credits](../CREDITS.md).
