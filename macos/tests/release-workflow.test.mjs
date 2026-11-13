import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const workflowPath = path.resolve(here, "../../.github/workflows/release.yml");
const workflow = await fs.readFile(workflowPath, "utf8");
const ciWorkflow = await fs.readFile(path.resolve(here, "../../.github/workflows/ci.yml"), "utf8");
const installerDefinition = await fs.readFile(path.resolve(here, "../../windows/installer/codex-dream-skin.iss"), "utf8");
const windowsVersion = (await fs.readFile(path.resolve(here, "../../windows/VERSION"), "utf8")).trim();

// A successful compile must be discoverable by both the PR artifact upload
// and the release workflow. Compare their names to the actual Inno output.
const setupBasename = installerDefinition.match(/^OutputBaseFilename=(.+)$/m)?.[1].trim();
assert.ok(setupBasename, "The Inno installer must declare its artifact basename.");
const installerFilename = setupBasename.replace("{#AppVersion}", windowsVersion) + ".exe";
for (const [label, source, versionToken] of [
  ["CI", ciWorkflow, "$version"],
  ["Release", workflow, "$env:VERSION"],
]) {
  const checkedArtifact = source.match(/\$artifact = Join-Path \$output "([^"]+)"/)?.[1];
  assert.ok(checkedArtifact, `${label} must check the compiled installer exists before uploading.`);
  assert.equal(checkedArtifact.replace(versionToken, windowsVersion), installerFilename,
    `${label} must look for the filename emitted by Inno Setup.`);
}
assert.match(ciWorkflow, /^\s+name: CodexDreamSkinYuuka-setup\s*$/m,
  "PR builds must expose the independent Yuuka artifact name.");
assert.doesNotMatch(ciWorkflow, /CodexDreamSkin-Setup-v|name: CodexDreamSkin-setup\b/,
  "Windows CI must not look for an upstream-branded installer after the Yuuka build.");

assert.match(
  workflow,
  /^\s+ref: \$\{\{ github\.sha \}\}\s*$/m,
  "The release guard must check out the immutable event commit.",
);
assert.doesNotMatch(
  workflow,
  /^\s+ref: main\s*$/m,
  "The release guard must not check out moving main.",
);
assert.match(
  workflow,
  /^\s+event_sha="\$\(git rev-parse HEAD\)"\s*$/m,
  "The release candidate must derive from the checked-out event commit.",
);
assert.match(workflow, /^\s+release_sha="\$event_sha"\s*$/m);
assert.doesNotMatch(
  workflow,
  /main_sha="\$\(git rev-parse origin\/main\)"/,
  "The release candidate must not be rebound to a later origin/main tip.",
);
assert.match(
  workflow,
  /if \[\[ "\$EVENT_NAME" == "workflow_dispatch" \|\| "\$version_unchanged" == "true" \]\]; then\s+release_sha="\$tag_commit"/,
  "A manual retry must resume an incomplete release from its immutable existing tag commit.",
);

assert.match(workflow, /cat "docs\/releases\/v\$\{VERSION\}\.md" > release-notes\.md/,
  "Version-specific changes and contributor credits must reach the public release notes.");

assert.match(
  workflow,
  /if \[\[ "\$previous_version" == "\$version" \]\]; then\s+version_unchanged="true"\s+should_release="false"/,
  "A main push with no version change must never rebuild or retry a release.",
);

assert.match(workflow, /if: github\.repository == 'longly-boat\/Codex-Dream-Skin-Yuuka'/,
  "Yuuka publication must target the selected repository only.");
assert.match(workflow, /CodexDreamSkinYuuka-Setup-v/,
  "The release must package the independent Yuuka installer.");
assert.doesNotMatch(workflow, /CodexDreamSkin-Setup-v|CodexDreamSkin-v[^\n]*\.dmg/,
  "The Windows-first Yuuka release must not publish upstream-branded installers or an unverified DMG.");
assert.match(workflow, /swift test --package-path macos\/menubar-app/,
  "Inherited native macOS code must retain its regression coverage.");
assert.match(workflow, /node tools\/sync-runtime-assets\.mjs --check/,
  "Release validation must detect generated Yuuka runtime drift.");
const expectedAssets = [...workflow.matchAll(/const expected = \[([\s\S]*?)\];/g)];
assert.equal(expectedAssets.length, 2, "Both draft and published assets must be verified.");
for (const [, assets] of expectedAssets) {
  assert.match(assets, /CodexDreamSkinYuuka-Setup-v/);
  assert.match(assets, /SHA256SUMS\.txt/);
  assert.equal((assets.match(/^\s*"/gm) || []).length, 2,
    "The exact Yuuka release asset set is one Windows installer plus its checksum file.");
}

console.log("PASS: Release workflow binds assets and tag to the exact event commit.");
