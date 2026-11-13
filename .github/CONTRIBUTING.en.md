# Contributing guide

<p align="center">
  <a href="./CONTRIBUTING.md">中文</a> · <strong>English</strong>
</p>

Thanks for contributing to Codex Dream Skin Yuuka. The project loads Yuuka themes into the official Codex desktop app through loopback CDP. v1.9.2 is this fork's first Windows x64 release. The macOS and Linux sources are inherited from upstream, have not completed native Yuuka acceptance testing, and have no Yuuka release packages. Identify whether your change affects Windows, the shared runtime, or an inherited platform before editing.

## Before you start

1. Read the [project README](../README.en.md), [platform reference](../docs/platforms.en.md), [Windows guide](../windows/README.en.md), and implementation constraints in [`windows/SKILL.md`](../windows/SKILL.md).
2. Search this repository's [existing issues](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/issues) and [open pull requests](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/pulls). If an active change already touches the same files, add to that discussion or split out a smaller change with no overlap.
3. Create a branch from the latest `main` in `longly-boat/Codex-Dream-Skin-Yuuka`. Keep each pull request focused on one problem. Do not mix a new theme, a runtime fix, and unrelated cleanup.

## Filing an issue

Use the repository's [bug or feature request forms](./ISSUE_TEMPLATE/) and search for duplicates first.

A bug report should include:

- The target platform, operating system version, and Codex installation source.
- Stable reproduction steps, plus the expected and actual results.
- Relevant logs or screenshots. Remove keys, `auth.json`, relay tokens, user-specific paths, and private conversations.
- The last known working version or commit, when you can identify it.

A feature request should explain the use case, expected behavior, alternatives considered, and whether it targets Windows, shared code, or an inherited platform. Reports about inherited platforms can inform future porting work; they do not imply current Yuuka support.

## Development and verification

Fork this repository and base your branch on the latest Yuuka `main`. Reuse existing scripts and platform helpers where possible. A small change should not require a new dependency.

### Inherited macOS code (when affected)

Run the full test suite:

```bash
(cd macos && npm test)
```

Check the environment and installation:

```bash
macos/scripts/doctor-macos.sh
```

For injection, CSS, launch, or restore changes, also run `macos/scripts/verify-dream-skin-macos.sh` and inspect both the home and normal task routes.

### Windows (current release platform)

Run the Windows regression suite:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\tests\run-tests.ps1
```

For install, launch, injection, or restore changes, exercise the affected scripts and `windows/scripts/verify-dream-skin.ps1`. Include the Windows version and Codex source in the pull request.

### Shared runtime

After editing `runtime/`, synchronize the platform copies with `node tools/sync-runtime-assets.mjs`. Run `node tools/sync-runtime-assets.mjs --check`, applicable Node tests, and `injector.mjs --check-payload` for all three platforms. Inherited-platform checks prevent shared-code drift. State when native UI behavior was not tested; passing CI does not establish platform support.

### Documentation or repository metadata only

Review every new or changed link and command, then run:

```bash
git diff --check
```

## Change constraints

- Use two-space indentation in shell, PowerShell, JavaScript, JSON, and CSS. Keep `set -euo pipefail` in shell entry points, use ESM for Node files, and name scripts in kebab-case.
- Add tests for affected install, start, inject, verify, pause, or restore behavior. Configuration changes must cover Chinese or other non-ASCII project names and preserve unrelated TOML content.
- Read `config.toml` as strict UTF-8, write it atomically, and keep a recoverable backup. Do not rewrite it through an API that depends on the system's default encoding.
- CDP must bind only to loopback. Do not modify the official `.app`, WindowsApps, `app.asar`, code signatures, API keys, or Base URLs.
- Commit only files required by the change. Keep logs, temporary directories, build output, private screenshots, and local configuration out of the pull request.

## Opening a pull request

1. Use a `type(scope): summary` title, such as `fix(windows): preserve UTF-8 config on restore`.
2. Complete the [pull request template](./pull_request_template.md) and check only the verification you completed. If a platform check is blocked by the environment, name the specific blocker in Notes and include the available static or fixture evidence.
3. Link the issue with `Closes #123`. Visual changes need screenshots of the home and task routes with private conversations and credentials removed.
4. User-visible Windows changes should update [`windows/CHANGELOG.md`](../windows/CHANGELOG.md). Update the corresponding changelog when an inherited platform is affected. A release must follow the [release process](../docs/releases/README.md), provide complete Chinese and English notes, and synchronize all nine version fields and related assertions: `macos/VERSION`, `windows/VERSION`, `macos/package.json`, `macos/scripts/common-macos.sh`, `macos/scripts/injector.mjs`, `windows/scripts/injector.mjs`, `linux/VERSION`, `linux/scripts/common-linux.sh`, and `linux/scripts/injector.mjs`. Do not bump only one platform's version.
5. Before submitting, review the diff, test output, and branch history against this repository's `main`. Remove unrelated commits from the pull request.

Maintainers may ask for a smaller scope, more evidence, or resolution of overlap with another open pull request. Continue updating the original pull request instead of opening duplicates for the same change.

This fork inherits its engine and engineering foundation from the [Needy Girl Overdose project](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose). Preserve author copyrights, the MIT license, and historical contributions. Send Yuuka feedback and pull requests to this repository.
