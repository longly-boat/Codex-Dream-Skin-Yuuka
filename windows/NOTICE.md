# Notices

Codex Dream Skin Studio is an **unofficial** customization project and is **not affiliated with, endorsed by, or sponsored by OpenAI**.

## Software license

The MIT License in `LICENSE` applies to the **software source code** in this repository (scripts, CSS, injectors, and docs that describe the software).

It does **not** grant rights to:

- OpenAI or Codex trademarks, product names, logos, or trade dress
- Official Codex / ChatGPT application binaries, `.app` bundles, or `app.asar`
- Any user-supplied images or third-party artwork you drop into a theme
- Character likenesses, franchise art, or celebrity imagery

## Yuuka artwork and upstream credit

This Windows Yuuka derivative builds on EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose:
https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose
Special thanks to its maintainers and contributors for the theme engine, installer,
automatic takeover, motion framework, theme manager, validation and interface design.
The earlier Fei-Away/Codex-Dream-Skin project and contributors are also acknowledged.
The original software copyright and MIT license are retained. See CREDITS.md in the source repository.

Yuuka wallpaper, closed-eye artwork and Blue Archive-inspired character marks are
fan materials excluded from the MIT software license. Character and game rights
remain with their respective owners. The Windows Yuuka installer includes the
Yuuka light/night packs, not the upstream Internet Angel wallpaper or tray images.

## Retired artwork history

Earlier revisions included Gothic Void Crusade, contributed by
[seansong-ideogram](https://github.com/seansong-ideogram) through upstream pull
request [#134](https://github.com/Fei-Away/Codex-Dream-Skin/pull/134), an abstract
demo hero, an Internet Angel PNG variant, and Arina Hashimoto reference material.
These are no longer included in the current source inventory or new installers.
Existing local user themes are preserved during upgrades. License exclusions
for third-party character and likeness material continue to apply to copies
obtained from older revisions; their former inclusion never granted likeness,
model-output, commercial-use, or redistribution rights.

## Runtime

- The macOS package does not redistribute Node.js. It validates and uses the
  Node.js executable already signed and bundled inside the user's official
  Codex desktop application.
- The Windows Setup.exe redistributes only `node.exe` and `LICENSE` from the
  pinned official Node.js v22.23.1 win-x64 archive after verifying its published
  SHA-256. Node.js is distributed under its own license; that license is kept
  beside the bundled executable in `runtime/node/LICENSE`.

## Inno Setup Simplified Chinese messages

The Windows installer is compiled with Inno Setup. Its Simplified Chinese
messages file is vendored unchanged from the official Inno Setup source tag
`is-6_7_1` at
`windows/installer/languages/ChineseSimplified.isl`, maintained by Zhenghan
Yang and distributed under the Inno Setup License. The full license is retained
at `windows/installer/languages/Inno-Setup-License.txt`.

## Security model

Themes are applied through Chromium DevTools Protocol on **loopback only**. While a themed session is running, treat the local debugging port as sensitive: do not run untrusted local software that could attach to it. Use the Restore launcher to tear down the themed session and debugging port.
