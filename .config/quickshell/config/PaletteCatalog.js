.pragma library

// Fixed palettes are kept as semantic role maps. Components consume the same
// Material role names regardless of whether the source is Live (Matugen) or a
// curated palette below.

var familyList = [
  { value: "material3", label: "Material 3", icon: "auto_awesome" },
  { value: "catppuccin", label: "Catppuccin", icon: "palette" },
  { value: "gruvbox", label: "Gruvbox", icon: "tonality" },
  { value: "tokyonight", label: "TokyoNight", icon: "nights_stay" }
]

var variantLists = {
  material3: [
    { value: "auto", label: "Expressive", icon: "auto_awesome" }
  ],
  catppuccin: [
    { value: "auto", label: "Auto", icon: "brightness_auto" },
    { value: "latte", label: "Latte", icon: "light_mode" },
    { value: "frappe", label: "Frappé", icon: "cloud" },
    { value: "macchiato", label: "Macchiato", icon: "nights_stay" },
    { value: "mocha", label: "Mocha", icon: "dark_mode" }
  ],
  gruvbox: [
    { value: "auto", label: "Auto", icon: "brightness_auto" },
    { value: "light-soft", label: "Light Soft", icon: "light_mode" },
    { value: "light", label: "Light", icon: "light_mode" },
    { value: "light-hard", label: "Light Hard", icon: "contrast" },
    { value: "dark-soft", label: "Dark Soft", icon: "dark_mode" },
    { value: "dark", label: "Dark", icon: "dark_mode" },
    { value: "dark-hard", label: "Dark Hard", icon: "contrast" }
  ],
  tokyonight: [
    { value: "auto", label: "Auto", icon: "brightness_auto" },
    { value: "day", label: "Day", icon: "light_mode" },
    { value: "storm", label: "Storm", icon: "cloud" },
    { value: "moon", label: "Moon", icon: "brightness_2" },
    { value: "night", label: "Night", icon: "dark_mode" }
  ]
}

function sourceOptions() {
  return [
    { value: "live", label: "Live", description: "Wallpaper-generated", icon: "wallpaper" },
    { value: "fixed", label: "Fixed", description: "Curated palette", icon: "palette" }
  ]
}

function contrastOptions() {
  return [
    { value: "standard", label: "Standard", icon: "contrast" },
    { value: "medium", label: "Medium", icon: "contrast" },
    { value: "high", label: "High", icon: "contrast" }
  ]
}

function familyOptions() {
  return familyList
}

function fixedFamilyOptions() {
  return [familyList[1], familyList[2], familyList[3]]
}

function variantOptions(family) {
  return variantLists[family] || variantLists.material3
}

function familyLabel(family) {
  var options = familyOptions()
  for (var i = 0; i < options.length; i++) {
    if (options[i].value === family) return options[i].label
  }
  return "Material 3"
}

function variantLabel(family, variant) {
  var options = variantOptions(family)
  for (var i = 0; i < options.length; i++) {
    if (options[i].value === variant) return options[i].label
  }
  return options[0].label
}

function resolveVariant(family, variant, darkMode) {
  if (family === "catppuccin") {
    if (variant === "auto") return darkMode ? "mocha" : "latte"
    return ["latte", "frappe", "macchiato", "mocha"].indexOf(variant) >= 0
      ? variant
      : (darkMode ? "mocha" : "latte")
  }
  if (family === "gruvbox") {
    if (variant === "auto") return darkMode ? "dark" : "light"
    return ["light-soft", "light", "light-hard", "dark-soft", "dark", "dark-hard"].indexOf(variant) >= 0
      ? variant
      : (darkMode ? "dark" : "light")
  }
  if (family === "tokyonight") {
    if (variant === "auto") return darkMode ? "night" : "day"
    return ["day", "storm", "moon", "night"].indexOf(variant) >= 0
      ? variant
      : (darkMode ? "night" : "day")
  }
  return "expressive"
}

function displayName(family, variant, darkMode) {
  var resolved = resolveVariant(family, variant, darkMode)
  return familyLabel(family) + " · " + variantLabel(family, resolved)
}

function semanticPalette(surface, accents) {
  var primaryContainer = accents.primaryContainer || surface.container
  var secondaryContainer = accents.secondaryContainer || surface.container
  var tertiaryContainer = accents.tertiaryContainer || surface.container
  var errorContainer = accents.errorContainer || surface.container
  var palette = {
    background: surface.base,
    surface: surface.base,
    surface_dim: surface.dim,
    surface_bright: surface.bright,
    surface_container_lowest: surface.lowest,
    surface_container_low: surface.low,
    surface_container: surface.container,
    surface_container_high: surface.high,
    surface_container_highest: surface.highest,
    surface_variant: surface.variant,
    primary: accents.primary,
    on_primary: accents.onPrimary,
    primary_container: primaryContainer,
    on_primary_container: accents.onPrimaryContainer,
    secondary: accents.secondary,
    on_secondary: accents.onSecondary,
    secondary_container: secondaryContainer,
    on_secondary_container: accents.onSecondaryContainer,
    tertiary: accents.tertiary,
    on_tertiary: accents.onTertiary,
    tertiary_container: tertiaryContainer,
    on_tertiary_container: accents.onTertiaryContainer,
    error: accents.error,
    on_error: accents.onError,
    error_container: errorContainer,
    on_error_container: accents.onErrorContainer,
    on_background: surface.text,
    on_surface: surface.text,
    on_surface_variant: surface.subtext,
    outline: surface.outline,
    outline_variant: surface.outlineVariant,
    inverse_surface: surface.text,
    inverse_on_surface: surface.base,
    inverse_primary: accents.inversePrimary || accents.primary,
    source_color: accents.primary,
    surface_tint: accents.primary,
    shadow: "#000000",
    scrim: "#000000"
  }

  // M3 fixed roles are useful for controls that need a stable tone while the
  // surrounding surface changes between light and dark variants.
  palette.primary_fixed = accents.primary
  palette.primary_fixed_dim = primaryContainer
  palette.on_primary_fixed = accents.onPrimary
  palette.on_primary_fixed_variant = accents.onPrimaryContainer
  palette.secondary_fixed = accents.secondary
  palette.secondary_fixed_dim = secondaryContainer
  palette.on_secondary_fixed = accents.onSecondary
  palette.on_secondary_fixed_variant = accents.onSecondaryContainer
  palette.tertiary_fixed = accents.tertiary
  palette.tertiary_fixed_dim = tertiaryContainer
  palette.on_tertiary_fixed = accents.onTertiary
  palette.on_tertiary_fixed_variant = accents.onTertiaryContainer
  return palette
}

function catppuccinPalette(flavor) {
  var s
  var a

  if (flavor === "latte") {
    s = {
      base: "#eff1f5", dim: "#dce0e8", bright: "#ffffff", lowest: "#ffffff",
      low: "#e6e9ef", container: "#ccd0da", high: "#bcc0cc", highest: "#acb0be",
      variant: "#ccd0da", text: "#4c4f69", subtext: "#4c4f69", outline: "#8c8fa1", outlineVariant: "#bcc0cc"
    }
    a = {
      primary: "#8839ef", onPrimary: "#ffffff", primaryContainer: "#e6e9ef", onPrimaryContainer: "#4c4f69",
      secondary: "#1e66f5", onSecondary: "#ffffff", secondaryContainer: "#ccd0da", onSecondaryContainer: "#4c4f69",
      tertiary: "#179299", onTertiary: "#000000", tertiaryContainer: "#ccd0da", onTertiaryContainer: "#4c4f69",
      error: "#d20f39", onError: "#ffffff", errorContainer: "#ccd0da", onErrorContainer: "#4c4f69",
      inversePrimary: "#7287fd"
    }
  } else if (flavor === "frappe") {
    s = {
      base: "#303446", dim: "#232634", bright: "#414559", lowest: "#232634",
      low: "#292c3c", container: "#414559", high: "#51576d", highest: "#626880",
      variant: "#51576d", text: "#c6d0f5", subtext: "#c6d0f5", outline: "#838ba7", outlineVariant: "#626880"
    }
    a = {
      primary: "#ca9ee6", onPrimary: "#303446", primaryContainer: "#51576d", onPrimaryContainer: "#c6d0f5",
      secondary: "#8caaee", onSecondary: "#303446", secondaryContainer: "#51576d", onSecondaryContainer: "#c6d0f5",
      tertiary: "#81c8be", onTertiary: "#303446", tertiaryContainer: "#51576d", onTertiaryContainer: "#c6d0f5",
      error: "#e78284", onError: "#303446", errorContainer: "#51576d", onErrorContainer: "#c6d0f5",
      inversePrimary: "#8caaee"
    }
  } else if (flavor === "macchiato") {
    s = {
      base: "#24273a", dim: "#181926", bright: "#363a4f", lowest: "#181926",
      low: "#1e2030", container: "#363a4f", high: "#494d64", highest: "#5b6078",
      variant: "#494d64", text: "#cad3f5", subtext: "#cad3f5", outline: "#8087a2", outlineVariant: "#5b6078"
    }
    a = {
      primary: "#c6a0f6", onPrimary: "#24273a", primaryContainer: "#494d64", onPrimaryContainer: "#cad3f5",
      secondary: "#8aadf4", onSecondary: "#24273a", secondaryContainer: "#494d64", onSecondaryContainer: "#cad3f5",
      tertiary: "#8bd5ca", onTertiary: "#24273a", tertiaryContainer: "#494d64", onTertiaryContainer: "#cad3f5",
      error: "#ed8796", onError: "#24273a", errorContainer: "#494d64", onErrorContainer: "#cad3f5",
      inversePrimary: "#8aadf4"
    }
  } else {
    s = {
      base: "#1e1e2e", dim: "#11111b", bright: "#313244", lowest: "#11111b",
      low: "#181825", container: "#313244", high: "#45475a", highest: "#585b70",
      variant: "#45475a", text: "#cdd6f4", subtext: "#cdd6f4", outline: "#7f849c", outlineVariant: "#585b70"
    }
    a = {
      primary: "#cba6f7", onPrimary: "#1e1e2e", primaryContainer: "#45475a", onPrimaryContainer: "#cdd6f4",
      secondary: "#89b4fa", onSecondary: "#1e1e2e", secondaryContainer: "#45475a", onSecondaryContainer: "#cdd6f4",
      tertiary: "#94e2d5", onTertiary: "#1e1e2e", tertiaryContainer: "#45475a", onTertiaryContainer: "#cdd6f4",
      error: "#f38ba8", onError: "#1e1e2e", errorContainer: "#45475a", onErrorContainer: "#cdd6f4",
      inversePrimary: "#89b4fa"
    }
  }
  return semanticPalette(s, a)
}

function gruvboxPalette(variant) {
  var dark = variant.indexOf("dark") === 0
  var hard = variant.indexOf("hard") >= 0
  var soft = variant.indexOf("soft") >= 0
  var base = dark
    ? (hard ? "#1d2021" : (soft ? "#32302f" : "#282828"))
    : (hard ? "#f9f5d7" : (soft ? "#f2e5bc" : "#fbf1c7"))
  var s = dark ? {
    base: base, dim: dark && hard ? "#1d2021" : "#282828", bright: "#3c3836", lowest: base,
    low: "#282828", container: "#3c3836", high: "#504945", highest: "#665c54",
    variant: "#504945", text: "#ebdbb2", subtext: "#d5c4a1", outline: "#a89984", outlineVariant: "#665c54"
  } : {
    base: base, dim: "#ebdbb2", bright: "#ffffff", lowest: "#ffffff",
    low: "#fbf1c7", container: "#ebdbb2", high: "#d5c4a1", highest: "#bdae93",
    variant: "#d5c4a1", text: "#3c3836", subtext: "#504945", outline: "#7c6f64", outlineVariant: "#bdae93"
  }
  var a = dark ? {
    primary: "#d3869b", onPrimary: base, primaryContainer: "#504945", onPrimaryContainer: "#ebdbb2",
    secondary: "#83a598", onSecondary: base, secondaryContainer: "#504945", onSecondaryContainer: "#ebdbb2",
    tertiary: "#8ec07c", onTertiary: base, tertiaryContainer: "#504945", onTertiaryContainer: "#ebdbb2",
    error: "#fb4934", onError: "#000000", errorContainer: "#504945", onErrorContainer: "#ebdbb2",
    inversePrimary: "#b16286"
  } : {
    primary: "#8f3f71", onPrimary: base, primaryContainer: "#d5c4a1", onPrimaryContainer: "#3c3836",
    secondary: "#076678", onSecondary: "#fbf1c7", secondaryContainer: "#d5c4a1", onSecondaryContainer: "#3c3836",
    tertiary: "#427b58", onTertiary: "#ffffff", tertiaryContainer: "#d5c4a1", onTertiaryContainer: "#3c3836",
    error: "#9d0006", onError: "#fbf1c7", errorContainer: "#d5c4a1", onErrorContainer: "#3c3836",
    inversePrimary: "#d3869b"
  }
  return semanticPalette(s, a)
}

function tokyonightPalette(variant) {
  var s
  var a
  if (variant === "day") {
    s = {
      base: "#e1e2e7", dim: "#d0d5e3", bright: "#ffffff", lowest: "#ffffff",
      low: "#d5d6db", container: "#c4c8da", high: "#a8aecb", highest: "#9699a3",
      variant: "#a8aecb", text: "#1a1b26", subtext: "#1a1b26", outline: "#848cb5", outlineVariant: "#a8aecb"
    }
    a = {
      primary: "#9854f1", onPrimary: "#000000", primaryContainer: "#c4c8da", onPrimaryContainer: "#1a1b26",
      secondary: "#2e7de9", onSecondary: "#000000", secondaryContainer: "#c4c8da", onSecondaryContainer: "#1a1b26",
      tertiary: "#007197", onTertiary: "#ffffff", tertiaryContainer: "#c4c8da", onTertiaryContainer: "#1a1b26",
      error: "#f52a65", onError: "#000000", errorContainer: "#c4c8da", onErrorContainer: "#1a1b26",
      inversePrimary: "#7aa2f7"
    }
  } else if (variant === "storm") {
    s = {
      base: "#24283b", dim: "#1f2335", bright: "#292e42", lowest: "#1f2335",
      low: "#1f2335", container: "#292e42", high: "#3b4261", highest: "#414868",
      variant: "#3b4261", text: "#a9b1d6", subtext: "#a9b1d6", outline: "#7982a9", outlineVariant: "#565f89"
    }
    a = {
      primary: "#bb9af7", onPrimary: "#24283b", primaryContainer: "#3b4261", onPrimaryContainer: "#c0caf5",
      secondary: "#7aa2f7", onSecondary: "#24283b", secondaryContainer: "#3b4261", onSecondaryContainer: "#c0caf5",
      tertiary: "#7dcfff", onTertiary: "#24283b", tertiaryContainer: "#3b4261", onTertiaryContainer: "#c0caf5",
      error: "#f7768e", onError: "#24283b", errorContainer: "#3b4261", onErrorContainer: "#c0caf5",
      inversePrimary: "#7aa2f7"
    }
  } else if (variant === "moon") {
    s = {
      base: "#222436", dim: "#1e2030", bright: "#2d3f76", lowest: "#1e2030",
      low: "#1e2030", container: "#2d3f76", high: "#3b4261", highest: "#444a73",
      variant: "#3b4261", text: "#c8d3f5", subtext: "#a9b8e8", outline: "#7a88cf", outlineVariant: "#545c7e"
    }
    a = {
      primary: "#c099ff", onPrimary: "#222436", primaryContainer: "#3b4261", onPrimaryContainer: "#c8d3f5",
      secondary: "#82aaff", onSecondary: "#222436", secondaryContainer: "#3b4261", onSecondaryContainer: "#c8d3f5",
      tertiary: "#86e1fc", onTertiary: "#222436", tertiaryContainer: "#3b4261", onTertiaryContainer: "#c8d3f5",
      error: "#ff8d94", onError: "#222436", errorContainer: "#3b4261", onErrorContainer: "#c8d3f5",
      inversePrimary: "#82aaff"
    }
  } else {
    s = {
      base: "#1a1b26", dim: "#16161e", bright: "#292e42", lowest: "#16161e",
      low: "#1f2335", container: "#292e42", high: "#3b4261", highest: "#414868",
      variant: "#3b4261", text: "#c0caf5", subtext: "#a9b1d6", outline: "#7982a9", outlineVariant: "#565f89"
    }
    a = {
      primary: "#bb9af7", onPrimary: "#1a1b26", primaryContainer: "#3b4261", onPrimaryContainer: "#c0caf5",
      secondary: "#7aa2f7", onSecondary: "#1a1b26", secondaryContainer: "#3b4261", onSecondaryContainer: "#c0caf5",
      tertiary: "#7dcfff", onTertiary: "#1a1b26", tertiaryContainer: "#3b4261", onTertiaryContainer: "#c0caf5",
      error: "#f7768e", onError: "#1a1b26", errorContainer: "#3b4261", onErrorContainer: "#c0caf5",
      inversePrimary: "#7aa2f7"
    }
  }
  return semanticPalette(s, a)
}

function palette(family, variant, darkMode) {
  var resolved = resolveVariant(family, variant, darkMode)
  if (family === "catppuccin") return catppuccinPalette(resolved)
  if (family === "gruvbox") return gruvboxPalette(resolved)
  if (family === "tokyonight") return tokyonightPalette(resolved)
  return null
}
