---
name: codex-dream-skin-yuuka
description: Apply, launch, verify, repair, update, migrate, or restore the independent Yuuka and Blue Archive theme for Windows Codex Desktop. Use for this fork's animated home, quiet task pages, theme library, local daily plan, and official-shortcut takeover. Keep official WindowsApps and app.asar unchanged.
---

# Codex Dream Skin Yuuka · Windows v1.9.2

Apply a reversible renderer skin through Chromium DevTools Protocol while launching the official Store-installed Codex executable. Never replace or take ownership of files under `WindowsApps`. This is the Windows-first Yuuka fork; installation and update assets come only from `longly-boat/Codex-Dream-Skin-Yuuka`. Preserve upstream credits and software licensing.

## Workflow

1. Prefer the Yuuka Release Setup, which bundles Node.js. Source installation requires Node.js 22+ and the native manager built with `node tools/build-theme-manager.mjs`. Before replacing an existing engine from source, disable its automatic watcher and close Codex, the tray, and the manager. Run `scripts/install-dream-skin.ps1`. It preserves native appearance settings, seeds Yuuka light/night packs without resetting an existing selection, deploys to `%LOCALAPPDATA%\CodexDreamSkinYuuka\engine`, and creates independent Yuuka shortcuts. Setup upgrades stop and restore the previous Yuuka takeover setting; source updates require manual stop/re-enable.
2. Open `Codex Dream Skin Yuuka` for the manager and tray; apply from the tray or run `%LOCALAPPDATA%\CodexDreamSkinYuuka\engine\scripts\start-dream-skin.ps1 -PromptRestart`. For persistent official-taskbar takeover, run the deployed `manage-auto-launch-dream-skin.ps1 -Enable -ProtectCurrentSession`. Do not bind login startup to a temporary source checkout. Automatic takeover still restarts a newly opened stock instance once; enabling protection leaves the current session alone.
3. Run `scripts/verify-dream-skin.ps1 -ScreenshotPath <absolute-path>` after launch, and inspect both routes. The home has wallpaper, character motion, four themed task cards, Memo and Daily Plan; a normal task uses a solid background. Preserve native suggestions and the composer. Check narrow and wide windows, project switching, and reduced-motion behavior without sending test messages or altering real tasks.
4. To add a complete downloaded pack, use the tray's “导入主题 ZIP…”. Accept ordinary `.zip` only. Every new official Studio pack contains `manifest.json`, non-empty `theme.json`, non-empty locally validated `theme.css`, exactly one registered background, and optional license/signature files; the trusted local simplified format contains exactly `theme.json`, `theme.css`, and its referenced image. Import into saved themes without changing the active theme. A manually extracted complete three-file directory may instead be moved into the saved themes folder. Previously saved legacy themes without CSS remain switchable but inject no extra CSS.
5. This installer deliberately does not register or remove the upstream `dreamskin://` protocol. Use ordinary ZIP import; do not promise website one-click activation. The retained community-handler code must still enforce fixed-origin metadata, native confirmation, integrity checks, and strict import if called explicitly.
6. Inspect the screenshot against `references/qa-inventory.md`. Verify both the home screen and a normal task before signing off.
7. Run `scripts/restore-dream-skin.ps1` to remove the live skin, close the saved CDP session, and reopen Codex normally. Add `-RestoreBaseTheme` to restore only saved appearance keys, `-RecoverConfigBackup` for explicit byte-for-byte recovery of a damaged config, or `-Uninstall` to delete shortcuts. A completed config restore archives that install's backup so a later install captures a fresh baseline.

## Migration from the earlier custom build

- New program files use `%LOCALAPPDATA%\Programs\CodexDreamSkinYuuka`; state uses `%LOCALAPPDATA%\CodexDreamSkinYuuka`. Never redirect this product back to the upstream `CodexDreamSkin` directory.
- Existing custom builds may use `%LOCALAPPDATA%\CodexDreamSkin`. First stop the old watcher with its `manage-auto-launch-dream-skin.ps1 -Disable`, then restore the old appearance with its `restore-dream-skin.ps1 -RestoreBaseTheme -NoRelaunch`. Save input and close Codex before migration. A remaining old backup or takeover startup entry intentionally blocks the new install/start.
- First-install migration is copy-only and only runs when the new root does not exist and the old active ID is `yuuka-seminar` or `yuuka-seminar-night`. It validates active/saved packs and preferences, retains all old files, and leaves the known legacy Internet Angel preset without CSS in the old library. Other invalid candidates fail before committing migration. Never delete the destination or bypass validation merely to force migration.
- Do not copy engine binaries, PIDs, CDP state, credentials, chats, browser profiles, or old configuration backups. Capture a fresh native-appearance backup for the new installation. Daily Plan stays in the existing Codex local-storage namespace; no real Codex goals or account pets are created.
- Operation, AutoLaunch and Acrylic locks remain shared with upstream for the common official app. UI and theme-store locks are Yuuka-specific. Do not globally rename all mutexes or run two theme engines against one Codex session.

## Guardrails

- Preserve the official executable, package signature, user threads, pets, plugins, and authentication state.
- Theme images must be UI-free wallpapers. Never import a README screenshot, fake window, sidebar, card, composer, logo, or text baked into the bitmap.
- Use the bundled wallpaper and matched animation only on the Yuuka home route. Keep task conversations on the intended solid background. Preserve readability, native control hit targets, and the independent home scroll area.
- `appearance: auto` follows the native computed `color-scheme` first and the system appearance only as a fallback. Image brightness may tune color and composition, but must not flip the user's shell mode; explicit `light` and `dark` remain authoritative.
- Attach the "选择项目" treatment to Codex's real project-selector toolbar and keep the current project button clickable; never draw a disconnected replacement.
- Keep decorative layers `pointer-events: none` and keep real buttons, navigation, and composer above them.
- On app updates, rerun install and launch; the scripts discover the current Appx package dynamically. Saved paths are never trusted for process control unless they still match a registered package identity.
- Keep manifest-derived package activation and the persistent isolated CDP profile as the default Windows launch. Explicit `-UseOfficialProfile` discovers the current registered Store version, revalidates its publisher/package/executable identity, and requires a fresh launch with a verified CDP owner and window in the current Windows session. Do not reintroduce a fixed build-number allowlist. An official profile launch uses one package activation and preserves running Codex processes on failure. The exact Store `app\ChatGPT.exe` fallback for the isolated profile still requires visible process arguments proving that owl encoded the CDP flag inside `codex://`, and the package identity/path checks in `common-windows.ps1`. Preserve the pre-launch PID set during isolated rollback. Treat access denial and raw arguments without a verified listener as terminal. Never change WindowsApps ACLs to make the fallback run.
- The default launcher scans for a free port when `9335` is occupied. A live unverified listener on an explicitly requested port fails closed; a stale listener whose owning process no longer exists automatically moves to the next free port.
- Keep the injection daemon running for navigation/reload resilience. Its state and logs live under `%LOCALAPPDATA%\CodexDreamSkinYuuka`.
- The watcher registers a generation-checked early payload for connected renderers so reload/navigation can paint the skin before the normal load-event fallback; unsupported CDP targets fall back safely.
- The active theme, saved themes, imported images, pause marker, and tray controls live under `%LOCALAPPDATA%\CodexDreamSkinYuuka`. Reject empty or over-10 MB images before copying or encoding them.
- Theme-pack import does not support `.dreamskin`; reject traversal, links/reparse entries, nested archives, ambiguous roots, Windows-reserved paths, size/count abuse, and packs that fail the existing theme/image payload checks.
- Community deep links accept only a canonical version ID. Reject redirects, non-approved or non-compatible metadata, mismatched IDs, non-boolean compatibility, unsafe display metadata, unexpected media types, byte/hash mismatches, and concurrent applies before changing the active theme.
- Every managed-store write rejects junctions and other reparse points in every existing path component. Imports also use the bundled Node metadata parser before copying to reject dimensions above 16384px or 50MP.
- CDP targets must use a same-port loopback WebSocket, belong to the current Store package, retain the launch-time Browser ID, and expose expected Codex renderer markers.
- Loopback prevents LAN exposure, but Chromium CDP has no same-user authentication. Run only trusted local software while the skin is active, and use restore to close the debug session when it is no longer needed.
- Preserve `config.toml` as strict UTF-8. Never use encoding-dependent whole-file PowerShell reads/writes, silently transcode UTF-16, or overwrite a file that changed after it was read. Ambiguous TOML shapes must fail before writing rather than receive a best-effort rewrite.
- Keep install/start/restore/verify serialized with the per-user operation lock in `common-windows.ps1`.
- Treat `%LOCALAPPDATA%\CodexDreamSkinYuuka\engine` as an installer-managed runtime. For source reinstallations, disable the Yuuka watcher and exit its tray and manager first so the runtime can be replaced atomically. Release Setup manages watcher maintenance itself and reports recovery failures.
- Keep installed shortcuts and tray child processes on `RemoteSigned`, never `Bypass`. Clear Internet-zone markers only from staged managed `.ps1` copies after their byte-content hashes match the selected source; never change the user's persistent execution policy or override Group Policy.

## Checks

```powershell
powershell -NoProfile -File tests\run-tests.ps1
node --check scripts\injector.mjs
node --check assets\renderer-inject.js
node --check assets\yuuka-renderer.js
```

## Resources

- `scripts/injector.mjs`: CDP connection, renderer injection, verification, screenshot, and removal.
- `scripts/common-windows.ps1`: Store-package discovery, Node validation, managed runtime installation, port ownership, state, and process identity safety.
- `scripts/config-utf8.ps1`: atomic UTF-8 configuration backup, selective restore, and explicit recovery.
- `assets/dream-skin.css`: full visual layer.
- `assets/yuuka-renderer.js`, `assets/yuuka-skin.css`, and `assets/yuuka-art.mjs`: generated Yuuka DOM integration, route-specific styling, and matched character artwork. Edit canonical `runtime/` sources, then run `tools/sync-runtime-assets.mjs`.
- `assets/background.png`, `assets/theme.json`, and `assets/theme.css`: reviewed Yuuka light default; `presets/yuuka-seminar-night/` supplies the dark pack. Preserve image hashes required by character motion.
- `assets/yuuka-tray.png`, `assets/yuuka-tray.ico`, and `assets/codex-dream-skin.ico`: Yuuka edition icons. Build and validate with `installer/build-yuuka-icons.ps1`; the last filename is retained for build compatibility.
- `scripts/yuuka-migration.ps1`: bounded, validated, copy-only legacy Yuuka migration.
- `scripts/theme-windows.ps1`: persistent active/saved theme store, safe image import, pause state, and preset seeding.
- `scripts/apply-community-theme.ps1`: fixed-origin, confirmed community download, integrity verification, strict ZIP import, apply, and rollback orchestration.
- `scripts/tray-dream-skin.ps1`: Windows Forms tray for apply, pause, import, save, switch, and complete restore.
- `references/qa-inventory.md`: required functional and visual signoff coverage.
- `references/runtime-notes.md`: troubleshooting and update behavior.
- `tests/run-tests.ps1`: managed runtime, configuration, state, recovery, payload, and CDP validation regression checks. Use `-EngineOnly` for the source-independence contract.

## Attribution

The engine and release foundation come from [EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose) and earlier Dream Skin contributors. Preserve their MIT copyright and the artwork exclusions documented in [CREDITS.md](../CREDITS.md) and [NOTICE.md](NOTICE.md).
