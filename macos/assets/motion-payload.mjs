// Trusted host-side composition. Motion preferences are independent of the
// strict theme ZIP contract and never insert author-supplied JavaScript/CSS.
import { createHash } from "node:crypto";
import { YUUKA_ART_KEY, YUUKA_MOTION_ART } from "./yuuka-art.mjs";
import {
  DEFAULT_MOTION_SETTINGS,
  getMotionSettingsPath,
  normalizeMotionSettings,
  readMotionSettings,
} from "./motion-settings.mjs";

export { getMotionSettingsPath };

export async function readMotionPreferences(filePath = getMotionSettingsPath()) {
  let settings;
  let rejected = false;
  try {
    settings = await readMotionSettings(filePath);
  } catch {
    // A corrupt or redirected preference file must not enable animation, nor
    // prevent the user from applying or restoring a perfectly valid theme.
    settings = normalizeMotionSettings({ ...DEFAULT_MOTION_SETTINGS, mode: "off" });
    rejected = true;
  }
  return {
    settings,
    rejected,
    signature: createHash("sha256").update(JSON.stringify(settings)).digest("hex").slice(0, 20),
  };
}

// Poll only the tiny, bounded preference file. Its directory may not exist
// when the injector starts, so an fs.watch on that directory alone would miss
// the user's first change. This never scans renderer DOM or theme images.
export function watchMotionPreferences(onChange, {
  filePath = getMotionSettingsPath(), initialSignature, intervalMs = 1000,
} = {}) {
  let signature = initialSignature;
  let closed = false;
  let reading = false;
  const timer = setInterval(async () => {
    if (closed || reading) return;
    reading = true;
    try {
      const next = await readMotionPreferences(filePath);
      if (!closed && next.signature !== signature) {
        signature = next.signature;
        onChange();
      }
    } finally { reading = false; }
  }, intervalMs);
  timer.unref?.();
  return () => { closed = true; clearInterval(timer); };
}

export function buildMotionPayload({ basePayload, extensionPayload, motionTemplate, config, artDataUrl }) {
  // Registered built-in art only: arbitrary imported themes cannot supply code,
  // external URLs, or their own animation frames through this trusted channel.
  const { yuukaClosedArt: ignoredUntrustedArt, yuukaMotionArt: ignoredUntrustedCrops, ...safeConfig } = config;
  const yuuka = ["yuuka-seminar", "yuuka-seminar-night"].includes(safeConfig.themeId)
    && safeConfig.artKey === YUUKA_ART_KEY
    && safeConfig.artMetadata?.width === 1672 && safeConfig.artMetadata?.height === 941;
  const configuration = JSON.stringify(yuuka
    ? { ...safeConfig, yuukaMotionArt: YUUKA_MOTION_ART } : safeConfig);
  const controller = motionTemplate.replace(
    "__DREAM_SKIN_MOTION_CONFIG_JSON__", () => "__dreamSkinMotionConfig",
  );
  // Preserve synchronous initial application. Only a live, prior controller
  // can request a bounded asynchronous wallpaper handoff on reinjection.
  // A newer injection or a pause invalidates a pending handoff before it can
  // bring the previous skin back after a user action.
  return `(async () => {
    const __dreamSkinMotionArt = ${JSON.stringify(artDataUrl) ?? "undefined"};
    const __dreamSkinMotionConfig = ${configuration};
    const ticket = {};
    window.__CODEX_DREAM_SKIN_MOTION_INJECTION__ = ticket;
    const previous = window.__CODEX_DREAM_SKIN_MOTION_STATE__;
    if (previous?.prepareThemeTransition) {
      try { await previous.prepareThemeTransition(__dreamSkinMotionConfig, __dreamSkinMotionArt); }
      catch (error) {
        if (error?.code === "DREAM_SKIN_IMAGE_DECODE_FAILED") throw error;
      }
    }
    if (window.__CODEX_DREAM_SKIN_MOTION_INJECTION__ !== ticket) return false;
    /* dream-skin:renderer:start */
    ${basePayload};
    /* dream-skin:renderer:end */
    ${extensionPayload};
    ${controller};
    return true;
  })()`;
}
