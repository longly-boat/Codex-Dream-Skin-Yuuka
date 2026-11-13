// Canonical cross-platform renderer. Run tools/sync-runtime-assets.mjs after editing.
((cssText, artDataUrl, themeConfig) => {
  const SELECTOR_CONTRACT = __DREAM_SKIN_SELECTORS_JSON__;
  const STATE_KEY = "__CODEX_DREAM_SKIN_STATE__";
  const DISABLED_KEY = "__CODEX_DREAM_SKIN_DISABLED__";
  const STYLE_REGISTRY_KEY = "__CODEX_DREAM_SKIN_STYLE_SHEETS__";
  const STYLE_ID = "codex-dream-skin-style";
  const HOME_DECK_ID = "chatgpt-internet-angel-deck";
  const SIDEBAR_ORNAMENTS_ID = "chatgpt-internet-angel-sidebar";
  const HOME_HUD_ID = "chatgpt-internet-angel-hud";
  const SHELL_ATTR = "data-dream-shell";
  const PART_ATTR = "data-ds-part";
  const COMPOSER_BORDER_BRIDGES = [
    "border-color", "border-top-color", "border-right-color", "border-bottom-color",
    "border-left-color", "border-width", "border-top-width", "border-right-width",
    "border-bottom-width", "border-left-width", "border-style", "border-top-style",
    "border-right-style", "border-bottom-style", "border-left-style",
  ].map((property) => ({
    property,
    variable: `--ds-community-composer-${property}`,
  })).filter(({ variable }) => cssText.includes(`${variable}:`));
  const ROOT_ATTRS = [
    "data-dream-skin", SHELL_ATTR, "data-dream-theme", "data-dream-upload-alpha", "data-dream-user-transparency",
    "data-dream-art-wide", "data-dream-art-safe", "data-dream-task-mode",
    "data-dream-art-safe-area", "data-dream-art-task-mode", "data-dream-art-aspect",
    "data-dream-art-ready",
  ];
  const initialRoute = new URLSearchParams(String(location.search || ""))
    .get("initialRoute") || "";
  const pathname = String(location.pathname || "");
  const excludedPetSurface = location.protocol === "app:" && (
    pathname.endsWith("/avatar-overlay-composition-surface.html") ||
    initialRoute === "/avatar-overlay" || initialRoute.startsWith("/avatar-overlay/")
  );
  if (excludedPetSurface) {
    const previous = window[STATE_KEY];
    if (typeof previous?.cleanup === "function") previous.cleanup();
    window[DISABLED_KEY] = true;
    return;
  }
  const VERSION = __DREAM_SKIN_VERSION_JSON__;
  const STYLE_REVISION = __DREAM_SKIN_STYLE_REVISION_JSON__;
  const PAYLOAD_REVISION = __DREAM_SKIN_PAYLOAD_REVISION_JSON__;
  const THEME = themeConfig && typeof themeConfig === "object" ? themeConfig : {};
  const INTERNET_ANGEL_THEME_IDS = new Set([
    "preset-internet-angel",
    "preset-internet-angel-default",
  ]);
  const isInternetAngelTheme = INTERNET_ANGEL_THEME_IDS.has(String(THEME.id || "").trim());
  const isYuukaTheme = ["yuuka-seminar", "yuuka-seminar-night"].includes(String(THEME.id || "").trim());
  // Only adapt declarations in the already validated community layer. Keep
  // foregrounds, borders and element opacity intact. Relative colors preserve
  // authored RGB/alpha (including percentages); local preferences replace alpha
  // rather than multiplying it. Opaque legacy literals use the same 30% default
  // as public background tokens. Explicit `transparent` remains an empty layer.
  const communityStart = cssText.indexOf("@layer dreamskin-community {");
  if (communityStart >= 0) {
    const communityCss = cssText.slice(communityStart).replace(
      /(^[ \t]*background-color:\s*)([^;]+?)(\s*!important;)/gm,
      (declaration, prefix, color, suffix) => {
        const value = color.trim();
        if (value.toLowerCase() === "transparent") return declaration;
        const hasAlpha = /^#(?:[0-9a-f]{4}|[0-9a-f]{8})$/i.test(value)
          || /^rgba\(/i.test(value) || /^var\(/i.test(value);
        return `${prefix}rgb(from ${value} r g b / var(--ds-user-surface-alpha, ${hasAlpha ? "alpha" : "0.70"}))${suffix}`;
      },
    );
    cssText = cssText.slice(0, communityStart) + communityCss;
  }
  const ART = THEME.art && typeof THEME.art === "object" ? THEME.art : {};
  const ART_METADATA = THEME.artMetadata && typeof THEME.artMetadata === "object"
    ? THEME.artMetadata : null;
  const ANALYSIS_CACHE_KEY = "__CODEX_DREAM_SKIN_ANALYSIS_CACHE__";
  const THEME_VARIABLES = [
    "--ds-upload-panel-alpha", "--ds-upload-bg-alpha", "--ds-upload-panel-alt-alpha",
    "--ds-user-surface-alpha",
    "--ds-bg", "--ds-panel", "--ds-panel-2", "--ds-green", "--ds-lime", "--ds-on-accent",
    "--ds-cyan", "--ds-purple", "--ds-text", "--ds-muted", "--ds-line",
    "--ds-bg-rgb", "--ds-panel-rgb", "--ds-panel-2-rgb", "--ds-accent-rgb",
    "--ds-accent-alt-rgb", "--ds-secondary-rgb", "--ds-highlight-rgb",
    "--ds-text-rgb", "--ds-muted-rgb", "--ds-line-rgb",
    "--dream-art-focus-x", "--dream-art-focus-y", "--dream-art-position",
    "--dream-skin-focus-x", "--dream-skin-focus-y", "--dream-skin-art-position",
    "--dream-skin-name", "--dream-skin-tagline", "--dream-skin-project-prefix",
    "--dream-skin-project-label", "--dream-skin-brand-subtitle", "--dream-skin-status",
    "--dream-skin-quote", "--dream-skin-art",
    "--ds-theme-color-background", "--ds-theme-color-panel",
    "--ds-theme-color-panel-alt", "--ds-theme-color-accent",
    "--ds-theme-color-accent-alt", "--ds-theme-color-secondary",
    "--ds-theme-color-highlight", "--ds-theme-color-text",
    "--ds-theme-color-muted", "--ds-theme-color-line",
    "--ds-theme-font-family", "--ds-theme-font-scale",
    "--ds-theme-surface-radius", "--ds-theme-surface-opacity",
    "--ds-theme-surface-blur", "--ds-theme-surface-border-alpha",
    "--ds-theme-surface-shadow", "--ds-theme-image-focus-x",
    "--ds-theme-image-focus-y", "--ds-theme-image-zoom",
    "--ds-theme-image-dim", "--ds-theme-image-task-intensity",
    "--ds-theme-density-scale", "--ds-theme-motion-level",
  ];
  const selectorByKey = new Map(SELECTOR_CONTRACT.selectors.map((entry) => [entry.key, entry]));
  const stableTestidSelector = (testid) => SELECTOR_CONTRACT.stableTestids?.includes(testid)
    ? `[data-testid="${testid}"]` : null;
  const installToken = {};
  const existingAnalysisCache = window[ANALYSIS_CACHE_KEY];
  const analysisCache = existingAnalysisCache && typeof existingAnalysisCache.get === "function" &&
    typeof existingAnalysisCache.set === "function" ? existingAnalysisCache : new Map();
  window[ANALYSIS_CACHE_KEY] = analysisCache;
  let artAnalysis = typeof THEME.artKey === "string" ? analysisCache.get(THEME.artKey) ?? null : null;
  let analysisTimer = null;
  let rootObserver = null;
  let partObserver = null;
  let bodyReadyHandler = null;
  let styleMode = null;
  let styleNode = null;
  let styleSheet = null;
  const now = () => typeof performance === "object" && typeof performance.now === "function"
    ? performance.now() : Date.now();
  const metrics = {
    ensureCalls: 0,
    rootPasses: 0,
    routePasses: 0,
    layoutReads: 0,
    attributeWrites: 0,
    styleWrites: 0,
    styleRepairs: 0,
    partPasses: 0,
    partWrites: 0,
    navigationEvents: 0,
    safetyPasses: 0,
    analysisRuns: 0,
    analysisCacheHits: artAnalysis ? 1 : 0,
    firstEnsureMs: null,
    analysisMs: null,
  };

  const previous = window[STATE_KEY];
  if (typeof previous?.cleanup === "function") previous.cleanup();
  window[DISABLED_KEY] = false;

  const CSS_PREDICATES = __DREAM_SKIN_CSS_PREDICATES_JSON__
    .filter((item) => cssText.includes(item.selector));
  for (const { selector, replacement } of CSS_PREDICATES) {
    cssText = cssText.replaceAll(selector, replacement);
  }
  const predicateCache = (__DREAM_CSS_PREDICATE_RUNTIME__)(document, CSS_PREDICATES);
  predicateCache.refresh();
  Object.defineProperties(metrics, {
    predicatePasses: { get: () => predicateCache.metrics.passes },
    predicateWrites: { get: () => predicateCache.metrics.writes },
    predicateMs: { get: () => predicateCache.metrics.totalMs },
  });

  const existingStyleRegistry = window[STYLE_REGISTRY_KEY];
  const styleRegistry = existingStyleRegistry instanceof Set ? existingStyleRegistry : new Set();
  window[STYLE_REGISTRY_KEY] = styleRegistry;
  const artUrl = (() => {
    const comma = artDataUrl.indexOf(",");
    const mime = /^data:([^;,]+)/.exec(artDataUrl)?.[1] || "image/png";
    const binary = atob(artDataUrl.slice(comma + 1));
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index);
    return URL.createObjectURL(new Blob([bytes], { type: mime }));
  })();

  const cssString = (value) => JSON.stringify(String(value ?? ""));

  const setStyleProperty = (root, name, value) => {
    if (root.style.getPropertyValue(name) !== value) {
      root.style.setProperty(name, value);
      metrics.styleWrites += 1;
    }
  };

  const setAttribute = (root, name, value) => {
    const normalized = String(value);
    if (root.getAttribute(name) !== normalized) {
      root.setAttribute(name, normalized);
      metrics.attributeWrites += 1;
    }
  };

  const parseRgb = (value) => {
    if (!value || value === "transparent") return null;
    const hex = String(value).trim().match(/^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i);
    if (hex) {
      const digits = hex[1];
      const rgbHex = digits.length <= 4
        ? digits.slice(0, 3).split("").map((digit) => `${digit}${digit}`).join("")
        : digits.slice(0, 6);
      const alphaHex = digits.length === 4
        ? `${digits[3]}${digits[3]}`
        : digits.length === 8 ? digits.slice(6, 8) : "ff";
      const number = Number.parseInt(rgbHex, 16);
      return {
        r: number >> 16,
        g: (number >> 8) & 255,
        b: number & 255,
        alpha: Number.parseInt(alphaHex, 16) / 255,
      };
    }
    const m = String(value).trim().match(
      /^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)$/i,
    );
    if (!m) return null;
    return {
      r: Number(m[1]),
      g: Number(m[2]),
      b: Number(m[3]),
      alpha: m[4] === undefined ? 1 : Math.min(1, Math.max(0, Number(m[4]))),
    };
  };

  const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

  const rgbString = (value) => {
    const rgb = parseRgb(value);
    return rgb ? [rgb.r, rgb.g, rgb.b]
      .map((channel) => Math.round(clamp(channel, 0, 255)))
      .join(" ") : null;
  };

  const rgbToHex = ({ r, g, b }) => `#${[r, g, b]
    .map((value) => clamp(Math.round(value), 0, 255).toString(16).padStart(2, "0"))
    .join("")}`;

  const relativeLuminance = ({ r, g, b }) => {
    const channels = [r, g, b].map((value) => {
      const normalized = clamp(value, 0, 255) / 255;
      return normalized <= 0.04045
        ? normalized / 12.92
        : ((normalized + 0.055) / 1.055) ** 2.4;
    });
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
  };

  const compositeColor = (value, background, alphaOverride = null) => {
    const foreground = parseRgb(value);
    if (!foreground) return background;
    const alpha = clamp(alphaOverride ?? foreground.alpha ?? 1, 0, 1);
    return {
      r: clamp(foreground.r, 0, 255) * alpha + background.r * (1 - alpha),
      g: clamp(foreground.g, 0, 255) * alpha + background.g * (1 - alpha),
      b: clamp(foreground.b, 0, 255) * alpha + background.b * (1 - alpha),
    };
  };

  const readableAccentInk = (accent, panel, panelAlpha = 0.94) => {
    // Match the composer background alpha and compare both possible backdrop
    // extremes so artwork cannot flip the decision.
    const luminances = [0, 255].map((backdrop) => {
      const surface = compositeColor(
        panel,
        { r: backdrop, g: backdrop, b: backdrop },
        panelAlpha,
      );
      return relativeLuminance(compositeColor(accent, surface));
    });
    const whiteContrast = Math.min(...luminances.map((value) => 1.05 / (value + 0.05)));
    const blackContrast = Math.min(...luminances.map((value) => (value + 0.05) / 0.05));
    return whiteContrast >= blackContrast ? "rgb(255 255 255)" : "rgb(0 0 0)";
  };

  const rgbToHsl = ({ r, g, b }) => {
    const values = [r, g, b].map((value) => value / 255);
    const max = Math.max(...values);
    const min = Math.min(...values);
    const lightness = (max + min) / 2;
    if (max === min) return { h: 0, s: 0, l: lightness };
    const delta = max - min;
    const saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min);
    let hue;
    if (max === values[0]) hue = (values[1] - values[2]) / delta + (values[1] < values[2] ? 6 : 0);
    else if (max === values[1]) hue = (values[2] - values[0]) / delta + 2;
    else hue = (values[0] - values[1]) / delta + 4;
    return { h: hue * 60, s: saturation, l: lightness };
  };

  const hslToRgb = ({ h, s, l }) => {
    const hue = ((h % 360) + 360) % 360 / 360;
    if (s === 0) {
      const neutral = Math.round(l * 255);
      return { r: neutral, g: neutral, b: neutral };
    }
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    const channel = (offset) => {
      let t = hue + offset;
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    };
    return { r: channel(1 / 3) * 255, g: channel(0) * 255, b: channel(-1 / 3) * 255 };
  };

  const detectShellAppearance = () => {
    const root = document.documentElement;
    const nativeTheme = root?.getAttribute("data-theme");
    if (nativeTheme === "dark" || nativeTheme === "light") return nativeTheme;
    if (root?.classList?.contains("electron-dark")) return "dark";
    if (root?.classList?.contains("electron-light")) return "light";
    try { return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"; } catch {}
    return "light";
  };

  const makeAdaptivePalette = (sample, shell) => {
    const source = sample || { r: 108, g: 126, b: 136 };
    const hsl = rgbToHsl(source);
    const hue = hsl.s < 0.12 ? 214 : hsl.h;
    const saturation = clamp(hsl.s, 0.38, 0.72);
    const accent = hslToRgb({ h: hue, s: saturation, l: shell === "light" ? 0.42 : 0.66 });
    const accentAlt = hslToRgb({ h: hue + 12, s: saturation * 0.82, l: shell === "light" ? 0.52 : 0.73 });
    const secondary = hslToRgb({ h: hue - 24, s: saturation * 0.64, l: shell === "light" ? 0.56 : 0.62 });
    const highlight = hslToRgb({ h: hue + 24, s: saturation * 0.76, l: shell === "light" ? 0.36 : 0.58 });
    const neutral = (lightness, chroma = 0.08) => rgbToHex(hslToRgb({ h: hue, s: chroma, l: lightness }));
    return shell === "light" ? {
      background: neutral(0.965, 0.07),
      panel: neutral(0.987, 0.035),
      panelAlt: neutral(0.945, 0.09),
      accent: rgbToHex(accent),
      accentAlt: rgbToHex(accentAlt),
      secondary: rgbToHex(secondary),
      highlight: rgbToHex(highlight),
      text: neutral(0.13, 0.10),
      muted: neutral(0.42, 0.08),
      line: `rgba(${Math.round(accent.r)}, ${Math.round(accent.g)}, ${Math.round(accent.b)}, .24)`,
    } : {
      background: neutral(0.055, 0.045),
      panel: neutral(0.085, 0.04),
      panelAlt: neutral(0.125, 0.05),
      accent: rgbToHex(accent),
      accentAlt: rgbToHex(accentAlt),
      secondary: rgbToHex(secondary),
      highlight: rgbToHex(highlight),
      text: neutral(0.93, 0.025),
      muted: neutral(0.69, 0.03),
      line: `rgba(${Math.round(accent.r)}, ${Math.round(accent.g)}, ${Math.round(accent.b)}, .28)`,
    };
  };

  const resolvedShell = () => {
    if (THEME.appearance === "light" || THEME.appearance === "dark") return THEME.appearance;
    // Image luminance may tune accents and scrims, but auto appearance follows
    // Codex/ChatGPT (or the OS fallback) so a bright wallpaper cannot flip a
    // native dark session back to a light shell after analysis.
    return detectShellAppearance();
  };

  const applyTheme = (root, shell) => {
    const declaredColors = THEME.colors && typeof THEME.colors === "object" ? THEME.colors : {};
    const legacyPalette = THEME.palette && typeof THEME.palette === "object" ? THEME.palette : {};
    // macOS themes use the full `colors` contract; older Windows themes used
    // `palette.accent`. Accept both while keeping one renderer source.
    const colors = Object.keys(declaredColors).length ? declaredColors : legacyPalette;
    const hasExplicitKeyList = Array.isArray(THEME.explicitColorKeys);
    const explicit = new Set(hasExplicitKeyList ? THEME.explicitColorKeys : []);
    if (!hasExplicitKeyList && (THEME.colorMode === "explicit" || !Object.hasOwn(THEME, "colorMode"))) {
      for (const key of Object.keys(declaredColors)) explicit.add(key);
    }
    if (typeof legacyPalette.accent === "string") explicit.add("accent");
    const explicitAlpha = (name) => {
      const value = declaredColors[name];
      if (!explicit.has(name) || typeof value !== "string") return null;
      const source = value.trim();
      const supplied = /^#(?:[0-9a-f]{4}|[0-9a-f]{8})$/i.test(source)
        || /^rgba?\(\s*[\d.]+\s*,\s*[\d.]+\s*,\s*[\d.]+\s*,\s*[\d.]+\s*\)$/i.test(source);
      return supplied ? parseRgb(source)?.alpha ?? null : null;
    };
    // Preferences are supplied by the local injector, never by the theme ZIP.
    // Transparency is the visible wallpaper percentage (30 => alpha .70).
    const userAlpha = typeof THEME.userTransparency === "number"
      && Number.isFinite(THEME.userTransparency)
      && THEME.userTransparency >= 0 && THEME.userTransparency <= 100
      ? (100 - THEME.userTransparency) / 100 : null;
    const panelAlpha = userAlpha ?? explicitAlpha("panel") ?? 0.70;
    const backgroundAlpha = userAlpha ?? explicitAlpha("background") ?? panelAlpha;
    const panelAltAlpha = userAlpha ?? explicitAlpha("panelAlt") ?? panelAlpha;
    if (userAlpha !== null) setStyleProperty(root, "--ds-user-surface-alpha", String(userAlpha));
    else root.style.removeProperty("--ds-user-surface-alpha");
    if (userAlpha !== null) root.setAttribute("data-dream-user-transparency", "true");
    else root.removeAttribute("data-dream-user-transparency");
    const uploadAlphas = {
      "--ds-upload-panel-alpha": panelAlpha,
      "--ds-upload-bg-alpha": backgroundAlpha,
      "--ds-upload-panel-alt-alpha": panelAltAlpha,
    };
    for (const [name, alpha] of Object.entries(uploadAlphas)) {
      if (alpha !== null) setStyleProperty(root, name, String(alpha));
      else root.style.removeProperty(name);
    }
    if (Object.values(uploadAlphas).some((alpha) => alpha !== null)) {
      setAttribute(root, "data-dream-upload-alpha", "true");
    } else root.removeAttribute("data-dream-upload-alpha");

    const adaptive = makeAdaptivePalette(artAnalysis?.accentRgb, shell);
    const legacyLight = (THEME.appearance === undefined || THEME.appearance === "auto")
      && THEME.colorMode !== "explicit" && shell === "light";
    const structural = new Set(["background", "panel", "panelAlt", "text", "muted"]);
    const pick = (name) => {
      const allowExplicit = explicit.has(name) && !(legacyLight && structural.has(name));
      return allowExplicit && typeof colors[name] === "string" ? colors[name] : adaptive[name];
    };
    const accent = pick("accent");
    const accentAlt = explicit.has("accentAlt") ? pick("accentAlt") : (explicit.has("accent") ? accent : adaptive.accentAlt);
    const variables = {
      "--ds-bg": pick("background"),
      "--ds-panel": pick("panel"),
      "--ds-panel-2": pick("panelAlt"),
      "--ds-green": accent,
      "--ds-lime": accentAlt,
      "--ds-cyan": pick("secondary"),
      "--ds-purple": pick("highlight"),
      "--ds-text": pick("text"),
      "--ds-muted": pick("muted"),
      "--ds-line": explicit.has("line") && typeof colors.line === "string" ? colors.line : adaptive.line,
    };

    for (const [name, value] of Object.entries(variables)) {
      if (typeof value === "string" && value) setStyleProperty(root, name, value);
    }
    if (explicit.has("accent")) {
      const accentInk = readableAccentInk(
        accent,
        variables["--ds-panel"],
        panelAlpha ?? 0.94,
      );
      if (accentInk) setStyleProperty(root, "--ds-on-accent", accentInk);
    }
    const publicColors = {
      "--ds-theme-color-background": `rgb(${rgbString(variables["--ds-bg"])} / ${backgroundAlpha})`,
      "--ds-theme-color-panel": `rgb(${rgbString(variables["--ds-panel"])} / ${panelAlpha})`,
      "--ds-theme-color-panel-alt": `rgb(${rgbString(variables["--ds-panel-2"])} / ${panelAltAlpha})`,
      "--ds-theme-color-accent": variables["--ds-green"],
      "--ds-theme-color-accent-alt": variables["--ds-lime"],
      "--ds-theme-color-secondary": variables["--ds-cyan"],
      "--ds-theme-color-highlight": variables["--ds-purple"],
      "--ds-theme-color-text": variables["--ds-text"],
      "--ds-theme-color-muted": variables["--ds-muted"],
      "--ds-theme-color-line": variables["--ds-line"],
    };
    for (const [name, value] of Object.entries(publicColors)) {
      if (typeof value === "string" && value) setStyleProperty(root, name, value);
    }
    setStyleProperty(root, "--ds-theme-surface-radius", "12px");
    setStyleProperty(root, "--ds-theme-surface-opacity", "1");
    setStyleProperty(root, "--ds-theme-surface-blur", "0px");
    setStyleProperty(root, "--ds-theme-font-family", "system");
    setStyleProperty(root, "--ds-theme-font-scale", "1");
    setStyleProperty(root, "--ds-theme-surface-border-alpha", "0.14");
    setStyleProperty(root, "--ds-theme-surface-shadow", "soft");
    setStyleProperty(root, "--ds-theme-image-zoom", "1");
    setStyleProperty(root, "--ds-theme-image-dim", "0");
    setStyleProperty(root, "--ds-theme-image-task-intensity", "0.35");
    setStyleProperty(root, "--ds-theme-density-scale", "standard");
    setStyleProperty(root, "--ds-theme-motion-level", "standard");
    const rgbVariables = {
      "--ds-bg-rgb": variables["--ds-bg"],
      "--ds-panel-rgb": variables["--ds-panel"],
      "--ds-panel-2-rgb": variables["--ds-panel-2"],
      "--ds-accent-rgb": variables["--ds-green"],
      "--ds-accent-alt-rgb": variables["--ds-lime"],
      "--ds-secondary-rgb": variables["--ds-cyan"],
      "--ds-highlight-rgb": variables["--ds-purple"],
      "--ds-text-rgb": variables["--ds-text"],
      "--ds-muted-rgb": variables["--ds-muted"],
      "--ds-line-rgb": variables["--ds-line"],
    };
    for (const [name, value] of Object.entries(rgbVariables)) {
      const rgb = rgbString(value);
      if (rgb) setStyleProperty(root, name, rgb);
    }
    setStyleProperty(root, "--dream-skin-name", cssString(THEME.name || "Codex Dream Skin"));
    setStyleProperty(root, "--dream-skin-tagline", cssString(THEME.tagline || "Make something wonderful."));
    setStyleProperty(root, "--dream-skin-quote", cssString(THEME.quote || "MAKE SOMETHING WONDERFUL"));
    setStyleProperty(root, "--dream-skin-brand-subtitle", cssString(
      THEME.brandSubtitle || "CODEX DREAM SKIN",
    ));
    setStyleProperty(root, "--dream-skin-status", cssString(THEME.statusText || "DREAM SKIN ONLINE"));
    setStyleProperty(root, "--dream-skin-project-prefix", cssString(THEME.projectPrefix || "选择项目 · "));
    setStyleProperty(root, "--dream-skin-project-label", cssString(THEME.projectLabel || "◉  选择项目"));
  };

  const applyArtMetadata = (root) => {
    const profile = artAnalysis || ART_METADATA;
    const inferredSafe = profile?.safeArea || "center";
    const safeArea = ART.safeArea && ART.safeArea !== "auto" ? ART.safeArea : inferredSafe;
    const canonicalSafe = ["left", "right", "center", "none"].includes(safeArea)
      ? safeArea : "center";
    const focusX = typeof ART.focusX === "number" ? ART.focusX
      : profile?.focusX ?? (safeArea === "left" ? 0.72 : safeArea === "right" ? 0.28 : 0.5);
    const focusY = typeof ART.focusY === "number" ? ART.focusY : profile?.focusY ?? 0.5;
    const taskMode = ART.taskMode && ART.taskMode !== "auto"
      ? ART.taskMode : profile?.taskMode || "ambient";
    const wide = profile?.wide || profile?.aspect === "wide" || profile?.aspect === "ultrawide";
    const aspect = profile?.aspect || "unknown";
    const focusXValue = `${(clamp(focusX, 0, 1) * 100).toFixed(2)}%`;
    const focusYValue = `${(clamp(focusY, 0, 1) * 100).toFixed(2)}%`;

    setAttribute(root, "data-dream-art-wide", wide ? "true" : "false");
    setAttribute(root, "data-dream-art-safe", canonicalSafe);
    setAttribute(root, "data-dream-task-mode", taskMode);
    setAttribute(root, "data-dream-art-safe-area", safeArea);
    setAttribute(root, "data-dream-art-task-mode", taskMode);
    setAttribute(root, "data-dream-art-aspect", aspect);
    setAttribute(root, "data-dream-art-ready", artAnalysis ? "true" : "false");
    setStyleProperty(root, "--dream-art-focus-x", focusXValue);
    setStyleProperty(root, "--dream-art-focus-y", focusYValue);
    setStyleProperty(root, "--dream-art-position", `${focusXValue} ${focusYValue}`);
    setStyleProperty(root, "--dream-skin-focus-x", focusXValue);
    setStyleProperty(root, "--dream-skin-focus-y", focusYValue);
    setStyleProperty(root, "--dream-skin-art-position", `${focusXValue} ${focusYValue}`);
    setStyleProperty(root, "--ds-theme-image-focus-x", String(Number(focusX.toFixed(4))));
    setStyleProperty(root, "--ds-theme-image-focus-y", String(Number(focusY.toFixed(4))));
  };

  const analyzeArt = () => new Promise((resolve) => {
    const startedAt = now();
    metrics.analysisRuns += 1;
    if (typeof window.Image !== "function" || !document?.createElement) {
      metrics.analysisMs = Number((now() - startedAt).toFixed(3));
      resolve(null);
      return;
    }
    const image = new window.Image();
    let settled = false;
    const finish = (value) => {
      if (settled) return;
      settled = true;
      if (analysisTimer) clearTimeout(analysisTimer);
      analysisTimer = null;
      metrics.analysisMs = Number((now() - startedAt).toFixed(3));
      resolve(value);
    };
    analysisTimer = setTimeout(() => finish(null), 6000);
    image.onerror = () => finish(null);
    image.onload = () => {
      try {
        const ratio = image.naturalWidth / image.naturalHeight;
        if (!Number.isFinite(ratio) || ratio <= 0) throw new Error("Invalid image dimensions");
        const maxDimension = 96;
        const width = Math.max(16, Math.round(ratio >= 1 ? maxDimension : maxDimension * ratio));
        const height = Math.max(16, Math.round(ratio >= 1 ? maxDimension / ratio : maxDimension));
        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const context = canvas.getContext?.("2d", { willReadFrequently: true });
        if (!context) throw new Error("Canvas is unavailable");
        context.drawImage(image, 0, 0, width, height);
        const data = context.getImageData(0, 0, width, height).data;
        const samples = new Array(width * height);
        const bins = Array.from({ length: 24 }, () => ({ weight: 0, r: 0, g: 0, b: 0 }));
        let lightTotal = 0;
        let count = 0;

        for (let y = 0; y < height; y += 1) {
          for (let x = 0; x < width; x += 1) {
            const offset = (y * width + x) * 4;
            if (data[offset + 3] < 32) continue;
            const rgb = { r: data[offset], g: data[offset + 1], b: data[offset + 2] };
            const light = (0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b) / 255;
            const hsl = rgbToHsl(rgb);
            samples[y * width + x] = { light, saturation: hsl.s };
            lightTotal += light;
            count += 1;
            if (hsl.s >= 0.16 && hsl.l >= 0.16 && hsl.l <= 0.86) {
              const bin = bins[Math.min(23, Math.floor(hsl.h / 15))];
              const weight = hsl.s * (1 - Math.abs(hsl.l - 0.52) * 0.85);
              bin.weight += weight;
              bin.r += rgb.r * weight;
              bin.g += rgb.g * weight;
              bin.b += rgb.b * weight;
            }
          }
        }
        if (!count) throw new Error("Image has no visible pixels");
        const brightness = lightTotal / count;
        const information = (start, end) => {
          let total = 0;
          let totalSquared = 0;
          let edges = 0;
          let edgeCount = 0;
          let pixels = 0;
          for (let y = 0; y < height; y += 1) {
            for (let x = start; x < end; x += 1) {
              const sample = samples[y * width + x];
              if (!sample) continue;
              total += sample.light;
              totalSquared += sample.light * sample.light;
              pixels += 1;
              const previous = x > start ? samples[y * width + x - 1] : null;
              const above = y > 0 ? samples[(y - 1) * width + x] : null;
              if (previous) { edges += Math.abs(sample.light - previous.light); edgeCount += 1; }
              if (above) { edges += Math.abs(sample.light - above.light); edgeCount += 1; }
            }
          }
          const mean = pixels ? total / pixels : 0;
          const variance = pixels ? Math.max(0, totalSquared / pixels - mean * mean) : 1;
          return Math.sqrt(variance) * 0.58 + (edgeCount ? edges / edgeCount : 1) * 0.42;
        };
        const zoneWidth = Math.max(1, Math.floor(width * 0.38));
        const leftInformation = information(0, zoneWidth);
        const rightInformation = information(width - zoneWidth, width);
        let safeArea = "center";
        if (leftInformation < rightInformation * 0.86) safeArea = "left";
        else if (rightInformation < leftInformation * 0.86) safeArea = "right";

        let saliencyTotal = 0;
        let saliencyX = 0;
        let saliencyY = 0;
        for (let y = 0; y < height; y += 1) {
          for (let x = 0; x < width; x += 1) {
            const sample = samples[y * width + x];
            if (!sample) continue;
            const previous = x > 0 ? samples[y * width + x - 1] : null;
            const above = y > 0 ? samples[(y - 1) * width + x] : null;
            const edge = (previous ? Math.abs(sample.light - previous.light) : 0) +
              (above ? Math.abs(sample.light - above.light) : 0);
            const weight = 0.01 + Math.abs(sample.light - brightness) * 0.48 +
              sample.saturation * 0.34 + edge * 0.28;
            saliencyTotal += weight;
            saliencyX += (x + 0.5) / width * weight;
            saliencyY += (y + 0.5) / height * weight;
          }
        }
        let focusX = saliencyTotal ? saliencyX / saliencyTotal : 0.5;
        let focusY = saliencyTotal ? saliencyY / saliencyTotal : 0.5;
        if (safeArea === "left") focusX = Math.max(0.64, focusX);
        if (safeArea === "right") focusX = Math.min(0.36, focusX);
        focusX = clamp(focusX, 0.12, 0.88);
        focusY = clamp(focusY, 0.18, 0.82);

        const accentBin = bins.reduce((best, candidate) => candidate.weight > best.weight ? candidate : best, bins[0]);
        const accentRgb = accentBin.weight > 0 ? {
          r: accentBin.r / accentBin.weight,
          g: accentBin.g / accentBin.weight,
          b: accentBin.b / accentBin.weight,
        } : null;
        const aspect = ratio >= 2.25 ? "ultrawide" : ratio >= 1.45 ? "wide"
          : ratio >= 1.08 ? "landscape" : ratio >= 0.9 ? "square" : "portrait";
        finish({
          width: image.naturalWidth,
          height: image.naturalHeight,
          ratio,
          wide: ratio >= 1.75,
          aspect,
          brightness,
          shell: brightness >= 0.58 ? "light" : "dark",
          safeArea,
          focusX,
          focusY,
          taskMode: ratio >= 2.25 ? "banner" : "ambient",
          accentRgb,
        });
      } catch {
        finish(null);
      }
    };
    image.src = artUrl;
  });

  const installStyle = () => {
    try {
      if (!("adoptedStyleSheets" in document) || typeof CSSStyleSheet !== "function") {
        throw new Error("Constructable stylesheets are unavailable");
      }
      const sheet = new CSSStyleSheet();
      if (typeof sheet.replaceSync !== "function") throw new Error("replaceSync is unavailable");
      sheet.replaceSync(cssText);
      const retained = [...document.adoptedStyleSheets]
        .filter((candidate) => !styleRegistry.has(candidate));
      document.adoptedStyleSheets = [...retained, sheet];
      styleRegistry.clear();
      styleRegistry.add(sheet);
      document.getElementById(STYLE_ID)?.remove();
      styleSheet = sheet;
      styleMode = "adopted";
      return;
    } catch {
      styleSheet = null;
    }

    styleNode = document.getElementById(STYLE_ID) || document.createElement("style");
    styleNode.id = STYLE_ID;
    styleNode.textContent = cssText;
    if (!styleNode.parentElement) (document.head || document.documentElement).appendChild(styleNode);
    styleMode = "style";
  };

  const ensureStyle = () => {
    if (styleMode === "adopted" && styleSheet) {
      const current = [...document.adoptedStyleSheets];
      if (!current.includes(styleSheet)) {
        document.adoptedStyleSheets = [...current, styleSheet];
        metrics.styleRepairs += 1;
      }
      return;
    }
    if (styleNode && document.getElementById(STYLE_ID) !== styleNode) {
      document.getElementById(STYLE_ID)?.remove();
      (document.head || document.documentElement).appendChild(styleNode);
      metrics.styleRepairs += 1;
    }
  };

  installStyle();

  const applyRootState = (root) => {
    metrics.rootPasses += 1;
    ensureStyle();
    const shell = resolvedShell();
    setAttribute(root, "data-dream-skin", "active");
    setAttribute(root, SHELL_ATTR, shell);
    setAttribute(root, "data-dream-theme", isInternetAngelTheme ? "internet-angel" : "standard");
    setStyleProperty(root, "--dream-skin-art", `url("${artUrl}")`);
    applyTheme(root, shell);
    applyArtMetadata(root);
    return shell;
  };

  // Codex 26.930 retains previous routes in the DOM. Their anchors must not
  // select the active scope or receive public theme-part markers.
  const queryAll = (selector) => {
    if (!selector) return [];
    try {
      return [...document.querySelectorAll(selector)]
        .filter((node) => !node.closest?.('[data-app-shell-active-page="false"]'));
    } catch { return []; }
  };
  const selectorHit = (key) => queryAll(selectorByKey.get(key)?.selector).length > 0;
  const stableTestidHit = (testid) => queryAll(stableTestidSelector(testid)).length > 0;

  const partNodes = new Set();
  const composerBorderRestores = new Map();
  const selectorNodes = (key) => queryAll(selectorByKey.get(key)?.selector);
  const genericNodes = (selector) => queryAll(selector)
    .filter((node) => node && typeof node.setAttribute === "function");
  const genericInputNodes = () => genericNodes(
    'textarea, [contenteditable="true"], [role="textbox"]',
  ).filter((node) => !node.closest?.('[role="dialog"], [aria-modal="true"]'));
  const resolvedMainNode = () => {
    const exact = selectorNodes("shell-main")[0];
    if (exact) return exact;
    for (const input of genericInputNodes()) {
      const main = input.closest?.('main, [role="main"]');
      if (main && typeof main.setAttribute === "function") return main;
    }
    return genericNodes('main, [role="main"]')
      .find((node) => !node.closest?.('[role="dialog"], [aria-modal="true"]')) ?? null;
  };
  const fallbackMainNodes = () => selectorNodes("shell-main").length
    ? [] : [resolvedMainNode()].filter(Boolean);
  const fallbackSidebarNodes = () => {
    if (selectorNodes("left-panel").length || selectorNodes("floating-left-panel").length) return [];
    const main = resolvedMainNode();
    const mainParent = main?.parentElement;
    if (!main || !mainParent) return [];
    const candidate = genericNodes('nav[aria-label]')
      .filter((node) => !main.contains?.(node))
      .filter((node) => !node.closest?.('[role="dialog"], [aria-modal="true"]'))
      .find((node) => node.parentElement === mainParent
        || node.parentElement?.parentElement === mainParent
        || node.parentElement === mainParent.parentElement);
    return candidate ? [candidate] : [];
  };
  const genericComposerRejectSelector = [
    '[data-composer-footer-responsive]',
    '[class*="ComposerLayoutFooter" i]',
    '[class*="ComposerLayoutToolbar" i]',
    '[class*="ComposerLayoutEditor" i]',
    '[class*="composer-footer" i]',
    '[class*="composer-toolbar" i]',
    '[class*="composer-editor" i]',
  ].join(", ");
  const genericComposerOwnerSelector = [
    '[data-testid*="composer" i]',
    '[data-testid*="prompt" i]',
    '[class*="composer" i]',
    '[class*="prompt" i]',
  ].join(", ");
  const fallbackComposerNodes = () => {
    const main = resolvedMainNode();
    const canonical = selectorNodes("composer-chrome");
    const leftSidebars = [
      ...selectorNodes("left-panel"),
      ...selectorNodes("floating-left-panel"),
      ...fallbackSidebarNodes(),
    ];
    const owners = new Set();
    for (const input of genericInputNodes()) {
      if (canonical.some((composer) => composer.contains?.(input))) continue;
      const root = input.closest?.('[class*="ComposerLayoutRoot" i]');
      let owner = root || input.closest?.(genericComposerOwnerSelector);
      while (!root && owner?.matches?.(genericComposerRejectSelector)) {
        owner = owner.parentElement?.closest?.(genericComposerOwnerSelector);
      }
      if (!owner ||
        leftSidebars.some((sidebar) => sidebar.contains?.(owner))) continue;
      if (!main || main.contains?.(owner) || root?.closest?.("aside")) owners.add(owner);
    }
    return [...owners];
  };
  const fallbackComposerToolbarNodes = (composerNodes) => {
    if (selectorNodes("composer-toolbar").length || !composerNodes.length) return [];
    return genericNodes(
      '[data-composer-footer-responsive], [class*="_ComposerLayoutFooter_"], [class*="_footer_"]',
    ).filter((node) => composerNodes.some((composer) =>
      composer !== node && composer.contains?.(node)));
  };
  const addPart = (desired, part, nodes) => {
    for (const node of nodes) {
      if (node && typeof node.setAttribute === "function" && !desired.has(node)) {
        desired.set(node, part);
      }
    }
  };
  const restoreComposerBorders = (node) => {
    const saved = composerBorderRestores.get(node);
    if (!saved) return;
    for (const [property, { value, priority }] of saved) {
      if (value) node.style.setProperty(property, value, priority);
      else node.style.removeProperty(property);
      metrics.styleWrites += 1;
    }
    composerBorderRestores.delete(node);
  };
  const refreshComposerBorders = (composerNodes) => {
    const desired = new Set(COMPOSER_BORDER_BRIDGES.length ? composerNodes : []);
    for (const node of composerBorderRestores.keys()) {
      if (!desired.has(node)) restoreComposerBorders(node);
    }
    for (const node of desired) {
      if (!node?.style || composerBorderRestores.has(node)) continue;
      const saved = new Map();
      for (const { property, variable } of COMPOSER_BORDER_BRIDGES) {
        saved.set(property, {
          value: node.style.getPropertyValue(property),
          priority: node.style.getPropertyPriority(property),
        });
        node.style.setProperty(property, `var(${variable})`, "important");
        metrics.styleWrites += 1;
      }
      composerBorderRestores.set(node, saved);
    }
  };
  const resolvedMessageNodes = () => selectorNodes("message").map((node) => {
    if (!node?.hasAttribute?.("data-local-conversation-user-anchor")) return node;
    // Current Codex user anchors span the conversation column. Prefer the
    // adaptive native bubble, while retaining the older anchor as a fallback.
    return node.querySelector?.(
      '[class*="max-w-"][class*="rounded-2xl"][class*="text-start"]',
    ) ?? node;
  });
  // Persistent local checklist. Keep this store independent of native chats,
  // goals and projects; only this namespaced key is ever read or written.
  const YUUKA_PLAN_KEY = "codex-dream-skin:yuuka:daily-plan:v1";
  const createYuukaPlanStore = (getStorage, makeId) => {
    const read = () => {
      let raw;
      try { raw = getStorage().getItem(YUUKA_PLAN_KEY); }
      catch { return { items: [], error: "无法读取本机计划，请稍后重试。" }; }
      if (raw === null) return { items: [], error: null };
      try {
        if (raw.length > 65536) throw new Error("size");
        const value = JSON.parse(raw);
        if (value?.version !== 1 || !Array.isArray(value.items) || value.items.length > 100) throw new Error("schema");
        const ids = new Set();
        const items = value.items.map(item => {
          if (!item || typeof item.id !== "string" || !/^[a-zA-Z0-9-]{1,80}$/.test(item.id)
            || ids.has(item.id) || typeof item.text !== "string" || !item.text.trim() || item.text.length > 120
            || typeof item.done !== "boolean") throw new Error("item");
          ids.add(item.id);
          return { id: item.id, text: item.text, done: item.done };
        });
        return { items, error: null };
      } catch { return { items: [], error: "已保存的计划格式异常，原数据已保留，暂不覆盖。" }; }
    };
    const change = (operation, value) => {
      // Re-read before every edit so other windows' completed writes survive.
      const current = read();
      if (current.error) return current;
      let items = current.items;
      if (operation === "add") {
        const text = String(value).trim();
        if (!text || text.length > 120) return { ...current, error: "请填写 1–120 字的计划。" };
        if (items.length >= 100) return { ...current, error: "最多保存 100 项，请先删除不需要的计划。" };
        const id = makeId();
        if (!/^[a-zA-Z0-9-]{1,80}$/.test(id) || items.some(item => item.id === id)) return { ...current, error: "未能创建计划，请重试。" };
        items = [...items, { id, text, done: false }];
      } else if (operation === "done") {
        items = items.map(item => item.id === value.id ? { ...item, done: Boolean(value.done) } : item);
      } else if (operation === "remove") {
        items = items.filter(item => item.id !== value);
      } else return { ...current, error: "不支持的计划操作。" };
      try { getStorage().setItem(YUUKA_PLAN_KEY, JSON.stringify({ version: 1, items })); }
      catch { return { ...current, error: "保存失败，修改未生效；请检查本机存储后重试。" }; }
      return { items, error: null };
    };
    return { read, change };
  };

  let yuukaGreetingNode = null;
  let yuukaGreetingTitle = null;
  let yuukaNativeHero = null;
  let yuukaHiddenValue = null;
  let yuukaAriaValue = null;
  const yuukaSidebarBadges = new Map();
  const yuukaProjectIcons = new Set();
  const yuukaWorkspaceTitles = new Set();
  const clearYuukaSidebar = () => {
    for (const title of yuukaWorkspaceTitles) title.removeAttribute("data-yuuka-workspace-title");
    yuukaWorkspaceTitles.clear();
    for (const icon of yuukaProjectIcons) icon.removeAttribute("data-yuuka-project-icon");
    yuukaProjectIcons.clear();
    for (const [button, badge] of yuukaSidebarBadges) {
      badge.remove();
      button.removeAttribute("data-yuuka-new-chat");
    }
    yuukaSidebarBadges.clear();
  };
  const syncYuukaSidebar = () => {
    if (!isYuukaTheme) return;
    const sidebars = [...selectorNodes("left-panel"), ...selectorNodes("floating-left-panel")];
    const buttons = sidebars.flatMap(sidebar => [...sidebar.querySelectorAll('button, [role="button"]')]);
    const workspaceTitles = buttons.filter(button => button.hasAttribute?.('data-app-action-sidebar-section-toggle')
      && /^(项目|Projects)$/i.test((button.textContent || "").trim()));
    for (const title of yuukaWorkspaceTitles) {
      if (!workspaceTitles.includes(title)) {
        title.removeAttribute("data-yuuka-workspace-title");
        yuukaWorkspaceTitles.delete(title);
      }
    }
    for (const title of workspaceTitles) {
      if (!yuukaWorkspaceTitles.has(title)) {
        title.setAttribute("data-yuuka-workspace-title", "");
        yuukaWorkspaceTitles.add(title);
      }
    }
    const projectRows = sidebars.flatMap(sidebar => [...sidebar.querySelectorAll('[class~="group/folder-row"]')]);
    for (const button of projectRows) {
      // Project rows contain their own project-actions button; chat rows do not.
      const actions = button.querySelector?.('[aria-label$="的项目操作"], [aria-label$="project actions" i]');
      const icon = actions ? button.querySelector?.('.icon-leading-slot > span:first-child') : null;
      if (icon && !actions.contains(icon) && !yuukaProjectIcons.has(icon)) {
        icon.setAttribute("data-yuuka-project-icon", "");
        yuukaProjectIcons.add(icon);
      }
    }
    for (const [button, badge] of yuukaSidebarBadges) {
      if (!buttons.includes(button) || button.clientWidth < 150) {
        badge.remove();
        button.removeAttribute("data-yuuka-new-chat");
        yuukaSidebarBadges.delete(button);
      }
    }
    for (const button of buttons) {
      if (yuukaSidebarBadges.has(button)) continue;
      const label = (button.getAttribute("aria-label") || button.textContent || "").trim();
      if (!["新聊天", "New chat"].includes(label)) continue;
      if (!(button.clientWidth >= 150)) continue;
      // Use an existing button's normal inline/flex flow. Never append to the
      // shell: its absolute-positioned children do not reserve badge space.
      const badge = document.createElement("span");
      badge.setAttribute("data-yuuka-schale", "");
      badge.setAttribute("aria-hidden", "true");
      badge.textContent = "SCHALE";
      button.setAttribute("data-yuuka-new-chat", "");
      button.appendChild(badge);
      yuukaSidebarBadges.set(button, badge);
    }
  };
  const clearYuukaGreeting = () => {
    yuukaGreetingNode?.remove?.();
    yuukaGreetingNode = null;
    yuukaGreetingTitle = null;
    if (yuukaNativeHero) {
      if (yuukaHiddenValue === null) yuukaNativeHero.removeAttribute("data-yuuka-native-hidden");
      else yuukaNativeHero.setAttribute("data-yuuka-native-hidden", yuukaHiddenValue);
      if (yuukaAriaValue === null) yuukaNativeHero.removeAttribute("aria-hidden");
      else yuukaNativeHero.setAttribute("aria-hidden", yuukaAriaValue);
    }
    yuukaNativeHero = null;
  };
  const syncYuukaGreeting = (nativeHero) => {
    // The verified game-source node is the native greeting, not the whole
    // Home route. Do not hide an unknown fallback that may own the composer.
    const exactHero = selectorNodes("game-source")[0];
    if (!isYuukaTheme || !exactHero || exactHero !== nativeHero || !exactHero.parentElement
      || exactHero.matches?.('main, [role="main"], [data-ds-part="main"], [data-ds-part="composer"]')
      || exactHero.querySelector?.('textarea, [contenteditable="true"], [role="textbox"]')) {
      clearYuukaGreeting();
      return nativeHero;
    }
    if (yuukaNativeHero !== exactHero || yuukaGreetingNode?.parentElement !== exactHero.parentElement) {
      clearYuukaGreeting();
      yuukaNativeHero = exactHero;
      yuukaHiddenValue = exactHero.getAttribute("data-yuuka-native-hidden");
      yuukaAriaValue = exactHero.getAttribute("aria-hidden");
      exactHero.setAttribute("data-yuuka-native-hidden", "true");
      exactHero.setAttribute("aria-hidden", "true");
      yuukaGreetingNode = document.createElement("section");
      yuukaGreetingNode.id = "codex-yuuka-home-greeting";
      yuukaGreetingNode.setAttribute("data-yuuka-owned", "greeting");
      const halo = document.createElement("span");
      halo.setAttribute("data-yuuka-halo", "");
      halo.setAttribute("aria-hidden", "true");
      const title = document.createElement("h1");
      yuukaGreetingTitle = title;
      // Some versions put the icon inside game-source; others keep it as a
      // separate sibling. Reuse that visible native anchor whenever possible.
      if (exactHero.contains?.(selectorNodes("home-icon")[0])) yuukaGreetingNode.appendChild(halo);
      yuukaGreetingNode.appendChild(title);
      exactHero.parentElement.appendChild(yuukaGreetingNode);
    }
    // The project name belongs to the native project button, never the full
    // question (which also contains localized prose). textContent stays text.
    const projectButton = exactHero.querySelector?.('button');
    const projectName = String(projectButton?.textContent || "").replace(/\s+/g, " ").trim();
    const greetingText = projectName
      ? `老师，一起推进「${projectName}」吧`
      : THEME.appearance === "dark"
        ? "老师，剩下的工作，我们一起完成吧。"
        : "老师，今天也一起加油吧。";
    if (yuukaGreetingTitle.textContent !== greetingText) yuukaGreetingTitle.textContent = greetingText;
    return yuukaGreetingNode;
  };
  const refreshParts = () => {
    metrics.partPasses += 1;
    syncYuukaSidebar();
    const desired = new Map();
    addPart(desired, "root", [document.documentElement]);
    addPart(desired, "sidebar", [
      ...selectorNodes("left-panel"),
      ...selectorNodes("floating-left-panel"),
      ...fallbackSidebarNodes(),
    ]);
    addPart(desired, "header", selectorNodes("header-tint"));
    // Route-specific parts win when a generic shell collapses home and main
    // onto the same element.
    addPart(desired, "home", selectorNodes("home-route"));
    addPart(desired, "main", [...selectorNodes("shell-main"), ...fallbackMainNodes()]);
    addPart(desired, "project-list", selectorNodes("project-selector"));
    addPart(desired, "thread", selectorNodes("thread-surface"));
    addPart(desired, "message", resolvedMessageNodes());
    const composerNodes = [...selectorNodes("composer-chrome"), ...fallbackComposerNodes()];
    addPart(desired, "composer", composerNodes);
    addPart(desired, "composer-toolbar", [
      ...selectorNodes("composer-toolbar"), ...fallbackComposerToolbarNodes(composerNodes),
    ]);
    addPart(desired, "dialog", selectorNodes("overlay-dialog"));
    const homeHero = selectorNodes("game-source")[0] ??
      selectorNodes("home-icon")[0]?.parentElement;
    const themedHero = syncYuukaGreeting(homeHero);
    addPart(desired, "home-hero", themedHero ? [themedHero] : []);

    for (const node of partNodes) {
      if (!desired.has(node)) {
        node.removeAttribute?.(PART_ATTR);
        metrics.partWrites += 1;
      }
    }
    partNodes.clear();
    for (const [node, part] of desired) {
      if (node.getAttribute?.(PART_ATTR) !== part) {
        node.setAttribute(PART_ATTR, part);
        metrics.partWrites += 1;
      }
      partNodes.add(node);
    }
    refreshComposerBorders(composerNodes);
  };

  const removeParts = () => {
    clearYuukaGreeting();
    clearYuukaSidebar();
    for (const node of [...composerBorderRestores.keys()]) restoreComposerBorders(node);
    for (const node of partNodes) node.removeAttribute?.(PART_ATTR);
    partNodes.clear();
    for (const node of document.querySelectorAll(`[${PART_ATTR}]`)) node.removeAttribute?.(PART_ATTR);
  };

  const scopeMatches = (scope, baseState, overlay) => {
    const active = new Set([baseState]);
    if (baseState !== "settings") active.add("all");
    if (overlay) active.add("overlay");
    const tokens = String(scope || "all").toLowerCase().match(/[a-z]+/g) || ["all"];
    return tokens.some((token) => token !== "config" && active.has(token));
  };

  const detectScope = () => {
    const overlay = selectorHit("overlay-menu") || selectorHit("overlay-dialog") ||
      selectorHit("overlay-popper");
    let baseState = "thread";
    if (selectorHit("settings-panel") || selectorHit("appearance-radio") ||
      stableTestidHit("theme-preview")) baseState = "settings";
    else if (selectorHit("home-icon") || selectorHit("home-route")) baseState = "home";
    else if (!selectorHit("shell-main") && !queryAll('main, [role="main"]').length) baseState = "settings";
    const missingL1 = SELECTOR_CONTRACT.selectors
      .filter((entry) => entry.tier === "L1" && entry.required &&
        scopeMatches(entry.scope, baseState, overlay) && !selectorHit(entry.key))
      .map((entry) => entry.key);
    return {
      state: overlay ? "overlay" : baseState,
      baseState,
      overlay,
      // Settings replaces (or partially replaces) the app shell on macOS and
      // can retain a shell on Windows.  It is therefore always an L0 scope;
      // never treat the absence of the home/thread L1 anchors as a failure.
      level: baseState === "settings" || missingL1.length ? "L0" : "L1",
      missingL1,
    };
  };

  const refreshScope = () => {
    metrics.routePasses += 1;
    const scope = detectScope();
    const state = window[STATE_KEY];
    if (state?.installToken === installToken) state.scope = scope;
    return scope;
  };

  const homePresets = [
    {
      tone: "explore",
      channel: "01 // EXPLORE",
      title: "探索并理解代码",
      detail: "READ / MAP / TRACE",
      prompt: "探索并理解当前项目的代码结构、关键模块与运行流程。",
      icon: '<path d="M5 18l3.4-1 7.7-7.7-2.4-2.4L6 14.6 5 18Z"/><path d="m12.8 7.8 2.4 2.4M16 5l3 3M7.7 15.3l1 1"/>',
    },
    {
      tone: "build",
      channel: "02 // BUILD",
      title: "构建新功能、应用或工具",
      detail: "MAKE / SHIP / GROW",
      prompt: "构建一个新功能、应用或工具：",
      icon: '<path d="m14.5 5.5 4 4-8.8 8.8H5.7v-4l8.8-8.8Z"/><path d="m12.5 7.5 4 4M4 20h16"/>',
    },
    {
      tone: "review",
      channel: "03 // REVIEW",
      title: "审查代码并提出修改建议",
      detail: "SCAN / CHECK / SIGNAL",
      prompt: "审查当前代码，并提出具体、可执行的修改建议。",
      icon: '<path d="M20 11a8 8 0 1 1-2.3-5.7"/><path d="M20 4v7h-7M8.5 12l2.2 2.2 4.8-5"/>',
    },
    {
      tone: "recover",
      channel: "04 // RECOVER",
      title: "修复问题和失败",
      detail: "DEBUG / HEAL / RETRY",
      prompt: "定位并修复当前项目中的问题、错误或失败。",
      icon: '<path d="M8 8a4 4 0 0 1 8 0v8a4 4 0 0 1-8 0V8Z"/><path d="M4 13h4m8 0h4M6 7l2 2m10-2-2 2M9 4l1.2 2m4.6-2L14 6M9.5 13h5"/>',
    },
  ];

  const writeHomePreset = (prompt) => {
    const composerRootSelector = selectorByKey.get("composer-chrome")?.selector ||
      ".composer-surface-chrome";
    const editor = [...document.querySelectorAll(
      `${composerRootSelector} .ProseMirror[contenteditable="true"], ` +
        `${composerRootSelector} [contenteditable="true"], ${composerRootSelector} textarea`,
    )].find(node => node.getBoundingClientRect().width > 0 && node.getBoundingClientRect().height > 0)
      || (isYuukaTheme ? genericInputNodes().find(node =>
      resolvedMainNode()?.contains(node) && node.getBoundingClientRect().width > 0) : null);
    if (!editor) return false;
    if (editor.tagName === "TEXTAREA") {
      editor.focus?.();
      const setter = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, "value")?.set;
      if (!setter) return false;
      setter.call(editor, prompt);
      editor.dispatchEvent(new Event("input", { bubbles: true }));
      return true;
    }
    let inserted = false;
    try {
      editor.focus?.();
      const selection = window.getSelection?.();
      const range = document.createRange?.();
      if (selection && range) {
        range.selectNodeContents(editor);
        selection.removeAllRanges();
        selection.addRange(range);
      }
      inserted = Boolean(document.execCommand?.("insertText", false, prompt));
    } catch {}
    if (!inserted || !(editor.textContent || "").includes(prompt)) {
      const paragraph = document.createElement("p");
      paragraph.textContent = prompt;
      if (typeof editor.replaceChildren !== "function") return false;
      editor.replaceChildren(paragraph);
      try {
        editor.dispatchEvent(new InputEvent("input", {
          bubbles: true,
          inputType: "insertText",
          data: prompt,
        }));
      } catch {
        try { editor.dispatchEvent(new Event("input", { bubbles: true })); } catch {}
      }
    }
    document.getElementById(HOME_DECK_ID)?.setAttribute("data-angel-composer", "open");
    editor.focus?.();
    return true;
  };

  const yuukaPlanStore = createYuukaPlanStore(() => window.localStorage,
    () => window.crypto?.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2)}`);
  const yuukaMemos = [
    "老师，今天也要认真核对，每一份努力的价值。",
    "计划我已经整理好了。接下来的工作……就一起完成吧，老师。",
    "再忙也要留一点时间休息。这、这也是为了提高效率。",
    "不必一次完成所有事。先做好眼前这一项，我会陪着老师。",
    "今天的努力，我都有记下来。老师，辛苦了。",
    "偶尔依靠我也没关系。毕竟，老师的计划也需要有人帮忙核算嘛。",
  ];
  let yuukaMemoIndex = Math.floor(Date.now() / 86400000) % yuukaMemos.length;
  let yuukaWorkdesk = null;
  let yuukaPlanDraft = "";
  const clearYuukaWorkdesk = () => {
    const input = yuukaWorkdesk?.querySelector('.yuuka-plan-form input');
    if (input) yuukaPlanDraft = input.value;
    yuukaWorkdesk?.remove();
    yuukaWorkdesk = null;
  };
  const renderYuukaPlan = (result, saved = false) => {
    if (!yuukaWorkdesk) return;
    const list = yuukaWorkdesk.querySelector('.yuuka-plan-list');
    const active = document.activeElement;
    const focusedId = list.contains(active) ? active.closest('[data-yuuka-plan-id]')?.getAttribute('data-yuuka-plan-id') : null;
    const focusDelete = active?.classList?.contains('yuuka-plan-delete');
    const scrollTop = list.scrollTop;
    const nodes = result.items.map(item => {
      const row = document.createElement('li');
      row.className = 'yuuka-plan-item';
      row.setAttribute('data-yuuka-plan-id', item.id);
      const label = document.createElement('label');
      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.checked = item.done;
      const text = document.createElement('span');
      text.className = 'yuuka-plan-text';
      text.textContent = item.text;
      label.append(checkbox, text);
      const remove = document.createElement('button');
      remove.type = 'button';
      remove.className = 'yuuka-plan-delete';
      remove.textContent = '删除';
      remove.setAttribute('aria-label', `删除计划：${item.text}`);
      row.append(label, remove);
      return row;
    });
    list.replaceChildren(...nodes);
    list.scrollTop = scrollTop;
    if (focusedId) {
      const row = [...list.children].find(node => node.getAttribute('data-yuuka-plan-id') === focusedId);
      (row?.querySelector(focusDelete ? 'button' : 'input') || yuukaWorkdesk.querySelector('.yuuka-plan-form input')).focus({ preventScroll: true });
    }
    yuukaWorkdesk.querySelector('.yuuka-plan-empty').hidden = Boolean(result.items.length || result.error);
    yuukaWorkdesk.querySelector('.yuuka-plan-count').textContent = `${result.items.filter(item => item.done).length} / ${result.items.length}`;
    const status = yuukaWorkdesk.querySelector('.yuuka-plan-status');
    status.textContent = result.error || (saved ? '已保存到本机 · 重启后保留' : '保存在本机 · 重启后保留');
    status.setAttribute('data-error', String(Boolean(result.error)));
  };
  const syncYuukaWorkdesk = (deck) => {
    if (!isYuukaTheme || !deck?.parentElement || !yuukaGreetingNode?.isConnected) {
      clearYuukaWorkdesk();
      return;
    }
    if (!yuukaWorkdesk?.isConnected) {
      clearYuukaWorkdesk();
      yuukaWorkdesk = document.createElement('section');
      yuukaWorkdesk.id = 'codex-yuuka-workdesk';
      yuukaWorkdesk.setAttribute('data-yuuka-owned', 'workdesk');
      yuukaWorkdesk.setAttribute('aria-label', '优香工作台');
      // Only constant UI markup goes through innerHTML. Plan text is always textContent.
      yuukaWorkdesk.innerHTML = `<div class="yuuka-workdesk-grid">
        <section class="yuuka-memo" aria-labelledby="yuuka-memo-title">
          <header><span class="yuuka-desk-kicker">YUUKA’S MEMO</span><h2 id="yuuka-memo-title">优香寄语</h2></header>
          <div class="yuuka-memo-copy"><p aria-live="polite"></p></div><button type="button" class="yuuka-memo-refresh">换一句</button>
        </section>
        <section class="yuuka-plan" aria-labelledby="yuuka-plan-title">
          <header><span class="yuuka-desk-kicker">DAILY PLAN</span><h2 id="yuuka-plan-title">今日计划</h2><span class="yuuka-plan-count" aria-label="已完成 / 总数"></span></header>
          <form class="yuuka-plan-form"><input type="text" maxlength="120" aria-label="新计划" placeholder="写下今天的一件小目标…" autocomplete="off"><button type="submit">添加</button></form>
          <ul class="yuuka-plan-list" aria-label="计划清单"></ul><p class="yuuka-plan-empty">还没有计划，从一件小事开始吧，老师。</p>
          <p class="yuuka-plan-status" role="status" aria-live="polite"></p>
        </section></div>`;
      yuukaWorkdesk.querySelector('.yuuka-memo-copy p').textContent = yuukaMemos[yuukaMemoIndex];
      yuukaWorkdesk.querySelector('.yuuka-memo-refresh').addEventListener('click', () => {
        yuukaMemoIndex = (yuukaMemoIndex + 1) % yuukaMemos.length;
        yuukaWorkdesk.querySelector('.yuuka-memo-copy p').textContent = yuukaMemos[yuukaMemoIndex];
      });
      const input = yuukaWorkdesk.querySelector('.yuuka-plan-form input');
      input.value = yuukaPlanDraft;
      // Enter belongs to this checklist, never the native chat composer.
      input.addEventListener('keydown', event => event.stopPropagation());
      input.addEventListener('keyup', event => event.stopPropagation());
      yuukaWorkdesk.querySelector('form').addEventListener('submit', event => {
        event.preventDefault();
        event.stopPropagation();
        if (!input.value.trim()) { input.focus(); return; }
        const result = yuukaPlanStore.change('add', input.value);
        if (!result.error) { input.value = ''; yuukaPlanDraft = ''; }
        renderYuukaPlan(result, true);
        input.focus();
      });
      const list = yuukaWorkdesk.querySelector('.yuuka-plan-list');
      list.addEventListener('change', event => {
        if (!event.target.matches('input[type="checkbox"]')) return;
        const id = event.target.closest('[data-yuuka-plan-id]').getAttribute('data-yuuka-plan-id');
        renderYuukaPlan(yuukaPlanStore.change('done', { id, done: event.target.checked }), true);
      });
      list.addEventListener('click', event => {
        const button = event.target.closest('.yuuka-plan-delete');
        if (!button) return;
        const id = button.closest('[data-yuuka-plan-id]').getAttribute('data-yuuka-plan-id');
        renderYuukaPlan(yuukaPlanStore.change('remove', id), true);
      });
      renderYuukaPlan(yuukaPlanStore.read());
    }
    if (deck.nextSibling !== yuukaWorkdesk) deck.parentElement.insertBefore(yuukaWorkdesk, deck.nextSibling);
  };
  const yuukaStorageHandler = event => {
    if (event.key === YUUKA_PLAN_KEY || event.key === null) renderYuukaPlan(yuukaPlanStore.read());
  };
  if (isYuukaTheme) window.addEventListener?.('storage', yuukaStorageHandler);

  const syncHomeDeck = () => {
    let deck = document.getElementById(HOME_DECK_ID);
    if (!isInternetAngelTheme && !isYuukaTheme) {
      deck?.remove?.();
      return null;
    }
    const homeSelector = selectorByKey.get("home-route")?.selector;
    let home = null;
    try { home = homeSelector ? document.querySelector(homeSelector) : null; } catch {}
    if (!home || typeof home.appendChild !== "function") {
      deck?.remove?.();
      return null;
    }
    if (isYuukaTheme) {
      if (deck && home.contains(deck)) {
        // The native greeting can mount after the first home scan. Reattach
        // an already-created deck once the centered welcome anchor exists.
        const greeting = home.querySelector('#codex-yuuka-home-greeting');
        if (greeting?.parentElement && (deck.parentElement !== greeting.parentElement || greeting.nextSibling !== deck)) {
          greeting.parentElement.insertBefore(deck, greeting.nextSibling);
        }
        return deck;
      }
      deck?.remove?.();
      deck = document.createElement("section");
      deck.id = HOME_DECK_ID;
      deck.className = "yuuka-task-deck";
      deck.setAttribute("aria-label", "夏莱任务委托");
      const heading = document.createElement("div");
      heading.className = "yuuka-task-heading";
      heading.setAttribute("aria-hidden", "true");
      heading.innerHTML = '<span>◇ 夏莱 · 任务委托</span><span>SEMINAR SUPPORT</span>';
      deck.appendChild(heading);
      const icons = [
        '<ellipse cx="12" cy="4" rx="6" ry="2"/><path d="M12 7v14M5 11l7-4 7 4-7 10-7-10Z"/><path d="M3 13h18M8 9l4 8 4-8"/>',
        '<path d="M3 5h12L8 19l-3-3 5-8H6ZM17 5h4v3l-7 11-3-3 6-9h-3l-7 12" stroke="none" fill="currentColor"/><path d="M3 22h18" opacity=".5"/>',
        '<rect x="5" y="2" width="14" height="20" rx="2"/><path d="M8 5h8v4H8z" fill="currentColor" fill-opacity=".18"/><path d="M8 13h1m3 0h1m3 0h1M8 17h1m3 0h1m3-1v4"/>',
        '<path d="m12 2 9 4v6c0 5-9 10-9 10S3 17 3 12V6l9-4Z" fill="currentColor" fill-opacity=".10"/><path d="m14 6-5 7h4l-3 6 7-9h-5l2-4Z" fill="currentColor" stroke="none"/>',
      ];
      const titles = ["夏莱调查", "千年工坊", "优香核算", "应急支援"];
      const descriptions = ["探索代码与项目结构", "构建功能、应用或工具", "审查代码与改进建议", "定位错误并修复问题"];
      const agencies = ["SCHALE", "MILLENNIUM", "SEMINAR", "SUPPORT"];
      const actions = ["探索代码", "构建功能", "审查代码", "修复问题"];
      for (const [index, preset] of homePresets.entries()) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "yuuka-task-card";
        button.setAttribute("data-yuuka-mission", String(index));
        button.setAttribute("aria-label", `${titles[index]}：${descriptions[index]}`);
        button.innerHTML = `<span class="yuuka-task-channel" aria-hidden="true">${agencies[index]}<b>0${index + 1}</b></span><span class="yuuka-task-sigil" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round">${icons[index]}</svg></span><span class="yuuka-task-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${icons[index]}</svg><i>◆</i></span><span class="yuuka-task-copy"><strong>${titles[index]}</strong><small>${descriptions[index]}</small></span><span class="yuuka-task-footer" aria-hidden="true"><span>${actions[index]}</span><b>›</b></span>`;
        button.addEventListener("click", () => writeHomePreset(preset.prompt));
        deck.appendChild(button);
      }
      // Keep native suggestions/repository controls intact. The task cards
      // belong to the centered welcome area, not the bottom composer slot.
      const greeting = home.querySelector('#codex-yuuka-home-greeting');
      if (greeting?.parentElement) greeting.parentElement.insertBefore(deck, greeting.nextSibling);
      else home.appendChild(deck);
      return deck;
    }
    if (deck?.parentElement === home) return deck;
    deck?.remove?.();
    if (typeof document.createElement !== "function") return null;

    deck = document.createElement("section");
    deck.id = HOME_DECK_ID;
    deck.className = "angel-command-deck";
    deck.setAttribute("aria-label", "Internet Angel task presets");
    deck.setAttribute("data-angel-ready", "true");

    const heading = document.createElement("div");
    heading.className = "angel-command-heading";
    heading.setAttribute("aria-hidden", "true");
    heading.innerHTML = "<span>♥ ANGEL COMMAND DECK</span><b>4 CHANNELS ONLINE</b>";
    deck.appendChild(heading);

    const grid = document.createElement("div");
    grid.className = "angel-preset-grid";
    for (const preset of homePresets) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = `angel-preset-card angel-preset-${preset.tone}`;
      button.setAttribute("data-dream-preset-id", preset.tone);
      button.setAttribute("aria-label", preset.title);
      button.innerHTML = `
        <span class="angel-preset-channel" aria-hidden="true">${preset.channel}</span>
        <span class="angel-preset-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${preset.icon}</svg><i>♥</i></span>
        <strong>${preset.title}</strong>
        <small>${preset.detail}</small>
        <em aria-hidden="true">LIVE</em>`;
      button.addEventListener("click", () => writeHomePreset(preset.prompt));
      grid.appendChild(button);
    }
    deck.appendChild(grid);
    home.appendChild(deck);
    return deck;
  };

  const syncInternetAngelChrome = () => {
    let sidebarOrnaments = document.getElementById(SIDEBAR_ORNAMENTS_ID);
    let homeHud = document.getElementById(HOME_HUD_ID);
    if (!isInternetAngelTheme) {
      sidebarOrnaments?.remove?.();
      homeHud?.remove?.();
      syncYuukaWorkdesk(syncHomeDeck());
      return;
    }

    const sidebarSelector = selectorByKey.get("left-panel")?.selector;
    let sidebar = null;
    try { sidebar = sidebarSelector ? document.querySelector(sidebarSelector) : null; } catch {}
    if (!sidebar || typeof sidebar.appendChild !== "function") {
      sidebarOrnaments?.remove?.();
    } else if (sidebarOrnaments?.parentElement !== sidebar) {
      sidebarOrnaments?.remove?.();
      sidebarOrnaments = document.createElement("div");
      sidebarOrnaments.id = SIDEBAR_ORNAMENTS_ID;
      sidebarOrnaments.className = "angel-sidebar-ornaments";
      sidebarOrnaments.setAttribute("aria-hidden", "true");
      sidebarOrnaments.innerHTML = `
        <i class="angel-sidebar-new-task"></i>
        <i class="angel-sidebar-signal"></i>
        <i class="angel-sidebar-halo"></i>
        <i class="angel-sidebar-pixels"></i>
        <span class="angel-sidebar-online"><b>♥</b> CHOTEN LINK / ONLINE</span>
        <span class="angel-sidebar-packet">AFFECTION 9999+</span>`;
      sidebar.appendChild(sidebarOrnaments);
    }

    const homeSelector = selectorByKey.get("home-route")?.selector;
    let home = null;
    try { home = homeSelector ? document.querySelector(homeSelector) : null; } catch {}
    if (!home || typeof home.appendChild !== "function") {
      homeHud?.remove?.();
    } else if (homeHud?.parentElement !== home) {
      homeHud?.remove?.();
      homeHud = document.createElement("section");
      homeHud.id = HOME_HUD_ID;
      homeHud.className = "angel-home-hud";
      homeHud.setAttribute("aria-hidden", "true");
      homeHud.innerHTML = `
        <i class="angel-hud-frame"></i>
        <i class="angel-hud-signal"></i>
        <i class="angel-hud-sparks"></i>
        <div class="angel-desktop-chip">♥ LIVE // CHOTEN DESKTOP 01</div>
        <div class="angel-connection-chip">♥ LIVE // CONNECTION: HEAVENLY // CHOTEN CHANNEL 01</div>
        <div class="angel-live-ticker"><b>♥ LIVE CHAT</b><span><i>CHOTEN ONLINE 9999+</i><i>BLESS YOUR CODE</i><i>INTERNET ANGEL FOREVER</i><i>推 +1 +1 +1</i></span></div>
        <div class="angel-id-chip"><b>KANGEL.SYS</b><span>STREAM ID 01</span><i>ONLINE</i></div>
        <div class="angel-telemetry">
          <div data-meter="love"><span>♥ AFFECTION</span><b><i></i></b><em>9999+</em></div>
          <div data-meter="stress"><span>! STRESS</span><b><i></i></b><em>082</em></div>
          <div data-meter="dark"><span>◉ DARK</span><b><i></i></b><em>066</em></div>
        </div>
        <div class="angel-reaction-deck"><i>♥ KAWAII</i><i>神 ANGEL</i><i>+1 LOVE</i></div>
        <div class="angel-dose-strip"><i></i><i></i><i></i><b>+ DOSE 03</b></div>`;
      home.appendChild(homeHud);
    }
    syncHomeDeck();
  };

  const ensure = ({ root: rootPass = true, scope: scopePass = false, parts: partPass = false } = {}) => {
    if (window[DISABLED_KEY]) return;
    const root = document.documentElement;
    if (!root) return;
    metrics.ensureCalls += 1;
    if (rootPass) applyRootState(root);
    predicateCache.syncLightRules(styleSheet || styleNode?.sheet);
    if (partPass) {
      refreshParts();
      predicateCache.refresh();
    }
    if (scopePass) refreshScope();
    syncInternetAngelChrome();
  };

  const cleanup = () => {
    const state = window[STATE_KEY];
    if (state?.installToken !== installToken) return false;
    window[DISABLED_KEY] = true;
    const root = document.documentElement;
    for (const name of ROOT_ATTRS) root?.removeAttribute(name);
    for (const attribute of [...(root?.attributes || [])]) {
      if (attribute.name.startsWith("data-dream-")) root.removeAttribute(attribute.name);
    }
    for (const name of THEME_VARIABLES) root?.style.removeProperty(name);
    for (const property of [...(root?.style || [])]) {
      if (property.startsWith("--dream-") || property.startsWith("--ds-")) {
        root.style.removeProperty(property);
      }
    }
    removeParts();
    clearYuukaWorkdesk();
    if (isYuukaTheme) window.removeEventListener?.('storage', yuukaStorageHandler);
    predicateCache.cleanup();
    state?.rootObserver?.disconnect();
    state?.partObserver?.disconnect();
    if (bodyReadyHandler && typeof document.removeEventListener === "function") {
      document.removeEventListener("DOMContentLoaded", bodyReadyHandler);
    }
    if (state?.timer) clearInterval(state.timer);
    if (state?.deckTimer) clearInterval(state.deckTimer);
    if (state?.scheduler?.timeout) clearTimeout(state.scheduler.timeout);
    if (analysisTimer) clearTimeout(analysisTimer);
    if (state?.mediaHandler && state?.mediaQuery) {
      try { state.mediaQuery.removeEventListener("change", state.mediaHandler); } catch {}
    }
    if (state?.navigationHandler && state?.navigation) {
      try { state.navigation.removeEventListener("navigate", state.navigationHandler); } catch {}
    }
    if (styleSheet) {
      try {
        document.adoptedStyleSheets = [...document.adoptedStyleSheets]
          .filter((candidate) => candidate !== styleSheet);
      } catch {}
      styleRegistry.delete(styleSheet);
    }
    styleNode?.remove();
    document.getElementById(HOME_DECK_ID)?.remove?.();
    document.getElementById(SIDEBAR_ORNAMENTS_ID)?.remove?.();
    document.getElementById(HOME_HUD_ID)?.remove?.();
    if (document.getElementById(STYLE_ID) === styleNode) document.getElementById(STYLE_ID)?.remove();
    if (styleRegistry.size === 0) delete window[STYLE_REGISTRY_KEY];
    if (state?.artUrl) URL.revokeObjectURL(state.artUrl);
    delete window[STATE_KEY];
    return true;
  };

  const scheduler = { timeout: null, root: false, scope: false, parts: false };
  const flushScheduledEnsure = () => {
    if (scheduler.timeout) clearTimeout(scheduler.timeout);
    scheduler.timeout = null;
    const pending = { root: scheduler.root, scope: scheduler.scope, parts: scheduler.parts };
    scheduler.root = false;
    scheduler.scope = false;
    scheduler.parts = false;
    ensure(pending);
  };
  const scheduleEnsure = ({ root = false, scope = false, parts = false } = {}, delay = 64) => {
    scheduler.root ||= root;
    scheduler.scope ||= scope;
    scheduler.parts ||= parts;
    if (scheduler.timeout) return;
    scheduler.timeout = setTimeout(flushScheduledEnsure, delay);
  };
  if (typeof MutationObserver === "function") {
    rootObserver = new MutationObserver(() => scheduleEnsure({ root: true }));
    // SPA route changes are observable as DOM mutations even when Chromium's
    // Navigation API emits no event. Keep verification scope and public parts
    // derived from the same post-mutation tree.
    const predicateClass = /main-surface|_MainContentSurface_|home-banners|_homeUtilityBar_|_ComposerHomeUtilityBar_|horizontal-scroll-fade-mask|group\/project-selector/;
    partObserver = new MutationObserver((records) => {
      const changed = records.some((record) => {
        if (record.type !== "attributes") return true;
        const current = record.target.getAttribute(record.attributeName);
        if (record.oldValue === current) return false;
        if (record.attributeName !== "class") return true;
        const structuralClasses = (value) => String(value || "").split(/\s+/)
          .filter((token) => predicateClass.test(token)).sort().join(" ");
        return structuralClasses(record.oldValue) !== structuralClasses(current);
      });
      if (changed) scheduleEnsure({ scope: true, parts: true }, 80);
    });
  }

  let mediaQuery = null;
  let mediaHandler = null;
  try {
    mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    mediaHandler = () => scheduleEnsure({ root: true });
  } catch {}

  const navigationApi = window.navigation && typeof window.navigation.addEventListener === "function"
    ? window.navigation : null;
  const navigationHandler = navigationApi ? () => {
    metrics.navigationEvents += 1;
    scheduleEnsure({ scope: true, parts: true }, 180);
  } : null;

  window[STATE_KEY] = {
    ensure,
    cleanup,
    rootObserver,
    partObserver,
    timer: null,
    deckTimer: null,
    scheduler,
    mediaQuery,
    mediaHandler,
    navigation: navigationApi,
    navigationHandler,
    artUrl,
    installToken,
    styleMode,
    styleNode,
    styleSheet,
    styleRevision: STYLE_REVISION,
    analysis: artAnalysis,
    artMetadata: ART_METADATA,
    scope: null,
    selectorsSchema: SELECTOR_CONTRACT.schema,
    metrics,
    predicateMetrics: predicateCache.metrics,
    version: VERSION,
    themeId: THEME.id || "custom",
    revision: PAYLOAD_REVISION,
    detectShellAppearance,
  };
  const firstEnsureStartedAt = now();
  ensure({ root: true, parts: true });
  const initialScope = refreshScope();
  metrics.firstEnsureMs = Number((now() - firstEnsureStartedAt).toFixed(3));

  const observeAttributes = (node) => {
    if (!rootObserver || !node) return;
    rootObserver.observe(node, {
      attributes: true,
      attributeFilter: ["class", "data-theme", "data-appearance", "data-color-mode"],
    });
  };
  const observePartTree = (node) => {
    if (!partObserver || !node) return;
    partObserver.observe(node, {
      childList: true, subtree: true,
      attributes: true, attributeOldValue: true,
      attributeFilter: [
        "class", "role", "data-testid", "data-app-shell-main-surface",
        "data-app-shell-active-page", "data-codex-composer-root", "type",
        "data-mention-list-scroll-area",
      ],
    });
  };
  observeAttributes(document.documentElement);
  const observeBody = () => {
    observeAttributes(document.body);
    observePartTree(document.body);
  };
  if (document.body) observeBody();
  else if (typeof document.addEventListener === "function") {
    bodyReadyHandler = () => {
      if (!window[DISABLED_KEY]) {
        observeBody();
        scheduleEnsure({ scope: true, parts: true }, 0);
      }
    };
    document.addEventListener("DOMContentLoaded", bodyReadyHandler, { once: true });
  }
  const timer = setInterval(() => {
    metrics.safetyPasses += 1;
    ensure({ root: true });
  }, 30000);
  window[STATE_KEY].timer = timer;
  window[STATE_KEY].deckTimer = setInterval(syncInternetAngelChrome, 850);
  if (mediaHandler && mediaQuery && typeof mediaQuery.addEventListener === "function") {
    mediaQuery.addEventListener("change", mediaHandler);
  }
  if (navigationHandler && navigationApi) {
    navigationApi.addEventListener("navigate", navigationHandler);
  }
  const analysisPromise = artAnalysis ? Promise.resolve(null) : analyzeArt();
  window[STATE_KEY].analysisTimer = analysisTimer;
  analysisPromise.then((analysis) => {
    const state = window[STATE_KEY];
    if (!analysis || state?.installToken !== installToken || window[DISABLED_KEY]) return;
    artAnalysis = analysis;
    state.analysis = analysis;
    if (typeof THEME.artKey === "string") {
      analysisCache.set(THEME.artKey, analysis);
      while (analysisCache.size > 8) analysisCache.delete(analysisCache.keys().next().value);
    }
    ensure({ root: true });
  }).catch(() => {});
  return {
    installed: true,
    version: VERSION,
    themeId: THEME.id || "custom",
    revision: PAYLOAD_REVISION,
    shell: resolvedShell(),
    scope: initialScope,
    styleMode,
    analysis: artAnalysis,
  };
})(__DREAM_SKIN_CSS_JSON__, __DREAM_SKIN_ART_JSON__, __DREAM_SKIN_THEME_JSON__)
