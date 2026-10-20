.pragma library

// Fixed palettes are kept as semantic role maps. Components consume the same
// Material role names regardless of whether the source is Live (Matugen) or a
// curated palette below.

var familyList = [
  { value: "material3", label: "Material 3", icon: "auto_awesome" },
  { value: "catppuccin", label: "Catppuccin", icon: "palette" },
  { value: "gruvbox", label: "Gruvbox", icon: "tonality" },
  { value: "tokyonight", label: "TokyoNight", icon: "nights_stay" },
  { value: "elenapan", label: "Elenapan", icon: "palette" },
  { value: "nord", label: "Nord", icon: "ac_unit" },
  { value: "dracula", label: "Dracula", icon: "bedtime" },
  { value: "rosepine", label: "Rosé Pine", icon: "local_florist" },
  { value: "everforest", label: "Everforest", icon: "forest" },
  { value: "kanagawa", label: "Kanagawa", icon: "waves" },
  { value: "solarized", label: "Solarized", icon: "wb_sunny" },
  { value: "vapourwave", label: "Vapourwave", icon: "blur_on" },
  { value: "synthwave", label: "Synthwave", icon: "graphic_eq" },
  { value: "monokai", label: "Monokai", icon: "terminal" },
  { value: "oxocarbon", label: "Oxocarbon", icon: "contrast" }
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
  ],
  elenapan: [
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ],
  nord: [
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ],
  dracula: [
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ],
  rosepine: [
    { value: "auto", label: "Auto", icon: "brightness_auto" },
    { value: "dawn", label: "Dawn", icon: "light_mode" },
    { value: "main", label: "Main", icon: "dark_mode" },
    { value: "moon", label: "Moon", icon: "brightness_2" }
  ],
  everforest: [
    { value: "auto", label: "Auto", icon: "brightness_auto" },
    { value: "light", label: "Light", icon: "light_mode" },
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ],
  kanagawa: [
    { value: "wave", label: "Wave", icon: "dark_mode" }
  ],
  solarized: [
    { value: "auto", label: "Auto", icon: "brightness_auto" },
    { value: "light", label: "Light", icon: "light_mode" },
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ],
  vapourwave: [
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ],
  synthwave: [
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ],
  monokai: [
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ],
  oxocarbon: [
    { value: "dark", label: "Dark", icon: "dark_mode" }
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
  return familyList.filter(function(f) { return f.value !== "material3" })
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
  if (family === "elenapan" || family === "nord" || family === "dracula" ||
      family === "vapourwave" || family === "synthwave" || family === "monokai" ||
      family === "oxocarbon") return "dark"
  if (family === "kanagawa") return "wave"
  if (family === "rosepine") {
    if (variant === "auto") return darkMode ? "main" : "dawn"
    return ["dawn", "main", "moon"].indexOf(variant) >= 0 ? variant : (darkMode ? "main" : "dawn")
  }
  if (family === "everforest" || family === "solarized") {
    if (variant === "auto") return darkMode ? "dark" : "light"
    return ["light", "dark"].indexOf(variant) >= 0 ? variant : (darkMode ? "dark" : "light")
  }
  return "expressive"
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
      variant: "#ccd0da", text: "#303446", subtext: "#303446", outline: "#8c8fa1", outlineVariant: "#bcc0cc"
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
      variant: "#51576d", text: "#eff1f5", subtext: "#eff1f5", outline: "#838ba7", outlineVariant: "#626880"
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
      variant: "#494d64", text: "#f4dbd6", subtext: "#f4dbd6", outline: "#8087a2", outlineVariant: "#5b6078"
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
    variant: "#504945", text: "#ebdbb2", subtext: "#ebdbb2", outline: "#a89984", outlineVariant: "#665c54"
  } : {
    base: base, dim: "#ebdbb2", bright: "#ffffff", lowest: "#ffffff",
    low: "#fbf1c7", container: "#ebdbb2", high: "#d5c4a1", highest: "#bdae93",
    variant: "#d5c4a1", text: "#3c3836", subtext: "#3c3836", outline: "#7c6f64", outlineVariant: "#bdae93"
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
      variant: "#a8aecb", text: "#1a1b26", subtext: "#24283b", outline: "#848cb5", outlineVariant: "#a8aecb"
    }
    a = {
      primary: "#2e7de9", onPrimary: "#000000", primaryContainer: "#c4c8da", onPrimaryContainer: "#1a1b26",
      secondary: "#9854f1", onSecondary: "#000000", secondaryContainer: "#c4c8da", onSecondaryContainer: "#1a1b26",
      tertiary: "#007197", onTertiary: "#ffffff", tertiaryContainer: "#c4c8da", onTertiaryContainer: "#1a1b26",
      error: "#f52a65", onError: "#000000", errorContainer: "#c4c8da", onErrorContainer: "#1a1b26",
      inversePrimary: "#7aa2f7"
    }
  } else if (variant === "storm") {
    s = {
      base: "#24283b", dim: "#1f2335", bright: "#292e42", lowest: "#1f2335",
      low: "#1f2335", container: "#292e42", high: "#3b4261", highest: "#414868",
      variant: "#3b4261", text: "#c0caf5", subtext: "#c0caf5", outline: "#7982a9", outlineVariant: "#565f89"
    }
    a = {
      primary: "#7aa2f7", onPrimary: "#24283b", primaryContainer: "#3b4261", onPrimaryContainer: "#c0caf5",
      secondary: "#bb9af7", onSecondary: "#24283b", secondaryContainer: "#3b4261", onSecondaryContainer: "#c0caf5",
      tertiary: "#7dcfff", onTertiary: "#24283b", tertiaryContainer: "#3b4261", onTertiaryContainer: "#c0caf5",
      error: "#f7768e", onError: "#24283b", errorContainer: "#3b4261", onErrorContainer: "#c0caf5",
      inversePrimary: "#7aa2f7"
    }
  } else if (variant === "moon") {
    s = {
      base: "#222436", dim: "#1e2030", bright: "#2d3f76", lowest: "#1e2030",
      low: "#1e2030", container: "#2d3f76", high: "#3b4261", highest: "#444a73",
      variant: "#3b4261", text: "#c8d3f5", subtext: "#c8d3f5", outline: "#7a88cf", outlineVariant: "#545c7e"
    }
    a = {
      primary: "#82aaff", onPrimary: "#222436", primaryContainer: "#3b4261", onPrimaryContainer: "#c8d3f5",
      secondary: "#c099ff", onSecondary: "#222436", secondaryContainer: "#3b4261", onSecondaryContainer: "#c8d3f5",
      tertiary: "#86e1fc", onTertiary: "#222436", tertiaryContainer: "#3b4261", onTertiaryContainer: "#c8d3f5",
      error: "#ff757f", onError: "#222436", errorContainer: "#3b4261", onErrorContainer: "#c8d3f5",
      inversePrimary: "#82aaff"
    }
  } else {
    s = {
      base: "#1a1b26", dim: "#16161e", bright: "#292e42", lowest: "#16161e",
      low: "#1f2335", container: "#292e42", high: "#3b4261", highest: "#414868",
      variant: "#3b4261", text: "#c0caf5", subtext: "#c0caf5", outline: "#7982a9", outlineVariant: "#565f89"
    }
    a = {
      primary: "#7aa2f7", onPrimary: "#1a1b26", primaryContainer: "#3b4261", onPrimaryContainer: "#c0caf5",
      secondary: "#bb9af7", onSecondary: "#1a1b26", secondaryContainer: "#3b4261", onSecondaryContainer: "#c0caf5",
      tertiary: "#7dcfff", onTertiary: "#1a1b26", tertiaryContainer: "#3b4261", onTertiaryContainer: "#c0caf5",
      error: "#f7768e", onError: "#1a1b26", errorContainer: "#3b4261", onErrorContainer: "#c0caf5",
      inversePrimary: "#7aa2f7"
    }
  }
  return semanticPalette(s, a)
}

// elenapan: navy cards with pink, purple and cyan accents, after the older
// AwesomeWM rice by elenapan (github.com/elenapan/dotfiles; her current
// `amarena` colorscheme is the updated version of this palette). Dark only;
// light mode reuses it.
function elenapanPalette() {
  var s = {
    base: "#1a1f2b", dim: "#151922", bright: "#2a3140", lowest: "#131720",
    low: "#1e2430", container: "#232a37", high: "#2a3140", highest: "#343c4d",
    variant: "#2a3140", text: "#f2f4f8", subtext: "#a3acbd",
    outline: "#5b6578", outlineVariant: "#3a4254"
  }
  var a = {
    primary: "#c77dc8", onPrimary: "#1a1f2b", primaryContainer: "#4a2f4d", onPrimaryContainer: "#f3d4f4",
    secondary: "#f06292", onSecondary: "#1a1f2b", secondaryContainer: "#522a39", onSecondaryContainer: "#ffd6e3",
    tertiary: "#5bb8d4", onTertiary: "#1a1f2b", tertiaryContainer: "#1f4452", onTertiaryContainer: "#cfeefa",
    error: "#ff6b6b", onError: "#1a1f2b", errorContainer: "#5a2a2a", onErrorContainer: "#ffd9d9",
    inversePrimary: "#8e4f90"
  }
  return semanticPalette(s, a)
}

// Nord, Dracula and Kanagawa ship one variant each; light mode reuses it, like
// elenapan. Hex values are the upstream palettes (nordtheme.com, draculatheme.com,
// rebelot/kanagawa.nvim). Container tones step through the upstream surface
// ramp so GTK/Kvantum/kitty/nvim generators get distinct surface levels.
function nordPalette() {
  var s = {
    base: "#2e3440", dim: "#242933", bright: "#3b4252", lowest: "#242933",
    low: "#2e3440", container: "#3b4252", high: "#434c5e", highest: "#4c566a",
    variant: "#434c5e", text: "#eceff4", subtext: "#d8dee9", outline: "#616e88", outlineVariant: "#4c566a"
  }
  var a = {
    primary: "#88c0d0", onPrimary: "#2e3440", primaryContainer: "#434c5e", onPrimaryContainer: "#eceff4",
    secondary: "#81a1c1", onSecondary: "#2e3440", secondaryContainer: "#434c5e", onSecondaryContainer: "#eceff4",
    tertiary: "#a3be8c", onTertiary: "#2e3440", tertiaryContainer: "#434c5e", onTertiaryContainer: "#eceff4",
    error: "#bf616a", onError: "#eceff4", errorContainer: "#434c5e", onErrorContainer: "#eceff4",
    inversePrimary: "#5e81ac"
  }
  return semanticPalette(s, a)
}

function draculaPalette() {
  var s = {
    base: "#282a36", dim: "#21222c", bright: "#343746", lowest: "#191a21",
    low: "#21222c", container: "#343746", high: "#44475a", highest: "#6272a4",
    variant: "#44475a", text: "#f8f8f2", subtext: "#f8f8f2", outline: "#6272a4", outlineVariant: "#44475a"
  }
  var a = {
    primary: "#bd93f9", onPrimary: "#282a36", primaryContainer: "#44475a", onPrimaryContainer: "#f8f8f2",
    secondary: "#ff79c6", onSecondary: "#282a36", secondaryContainer: "#44475a", onSecondaryContainer: "#f8f8f2",
    tertiary: "#8be9fd", onTertiary: "#282a36", tertiaryContainer: "#44475a", onTertiaryContainer: "#f8f8f2",
    error: "#ff5555", onError: "#282a36", errorContainer: "#44475a", onErrorContainer: "#f8f8f2",
    inversePrimary: "#bd93f9"
  }
  return semanticPalette(s, a)
}

function kanagawaPalette() {
  var s = {
    base: "#1f1f28", dim: "#16161d", bright: "#2a2a37", lowest: "#16161d",
    low: "#1a1a22", container: "#2a2a37", high: "#363646", highest: "#54546d",
    variant: "#363646", text: "#dcd7ba", subtext: "#c8c093", outline: "#727169", outlineVariant: "#54546d"
  }
  var a = {
    primary: "#7e9cd8", onPrimary: "#1f1f28", primaryContainer: "#2d4f67", onPrimaryContainer: "#dcd7ba",
    secondary: "#957fb8", onSecondary: "#1f1f28", secondaryContainer: "#363646", onSecondaryContainer: "#dcd7ba",
    tertiary: "#7aa89f", onTertiary: "#1f1f28", tertiaryContainer: "#363646", onTertiaryContainer: "#dcd7ba",
    error: "#e46876", onError: "#1f1f28", errorContainer: "#363646", onErrorContainer: "#dcd7ba",
    inversePrimary: "#7e9cd8"
  }
  return semanticPalette(s, a)
}

function rosepinePalette(variant) {
  var s
  var a
  if (variant === "dawn") {
    s = {
      base: "#faf4ed", dim: "#f2e9e1", bright: "#fffaf3", lowest: "#fffaf3",
      low: "#fffaf3", container: "#f2e9e1", high: "#dfdad9", highest: "#cecacd",
      variant: "#dfdad9", text: "#575279", subtext: "#797593", outline: "#9893a5", outlineVariant: "#dfdad9"
    }
    a = {
      primary: "#907aa9", onPrimary: "#faf4ed", primaryContainer: "#f2e9e1", onPrimaryContainer: "#575279",
      secondary: "#286983", onSecondary: "#faf4ed", secondaryContainer: "#f2e9e1", onSecondaryContainer: "#575279",
      tertiary: "#56949f", onTertiary: "#faf4ed", tertiaryContainer: "#f2e9e1", onTertiaryContainer: "#575279",
      error: "#b4637a", onError: "#faf4ed", errorContainer: "#f2e9e1", onErrorContainer: "#575279",
      inversePrimary: "#c4a7e7"
    }
  } else if (variant === "moon") {
    s = {
      base: "#232136", dim: "#232136", bright: "#393552", lowest: "#232136",
      low: "#2a273f", container: "#393552", high: "#44415a", highest: "#56526e",
      variant: "#44415a", text: "#e0def4", subtext: "#908caa", outline: "#6e6a86", outlineVariant: "#44415a"
    }
    a = {
      primary: "#c4a7e7", onPrimary: "#232136", primaryContainer: "#44415a", onPrimaryContainer: "#e0def4",
      secondary: "#ea9a97", onSecondary: "#232136", secondaryContainer: "#44415a", onSecondaryContainer: "#e0def4",
      tertiary: "#9ccfd8", onTertiary: "#232136", tertiaryContainer: "#44415a", onTertiaryContainer: "#e0def4",
      error: "#eb6f92", onError: "#232136", errorContainer: "#44415a", onErrorContainer: "#e0def4",
      inversePrimary: "#907aa9"
    }
  } else {
    s = {
      base: "#191724", dim: "#191724", bright: "#26233a", lowest: "#191724",
      low: "#1f1d2e", container: "#26233a", high: "#403d52", highest: "#524f67",
      variant: "#403d52", text: "#e0def4", subtext: "#908caa", outline: "#6e6a86", outlineVariant: "#403d52"
    }
    a = {
      primary: "#c4a7e7", onPrimary: "#191724", primaryContainer: "#403d52", onPrimaryContainer: "#e0def4",
      secondary: "#ebbcba", onSecondary: "#191724", secondaryContainer: "#403d52", onSecondaryContainer: "#e0def4",
      tertiary: "#9ccfd8", onTertiary: "#191724", tertiaryContainer: "#403d52", onTertiaryContainer: "#e0def4",
      error: "#eb6f92", onError: "#191724", errorContainer: "#403d52", onErrorContainer: "#e0def4",
      inversePrimary: "#907aa9"
    }
  }
  return semanticPalette(s, a)
}

function everforestPalette(variant) {
  var s
  var a
  if (variant === "light") {
    s = {
      base: "#fdf6e3", dim: "#f2efdf", bright: "#fdf6e3", lowest: "#fdf6e3",
      low: "#f4f0d9", container: "#efebd4", high: "#e6e2cc", highest: "#e0dcc7",
      variant: "#e6e2cc", text: "#5c6a72", subtext: "#829181", outline: "#939f91", outlineVariant: "#bdc3af"
    }
    a = {
      primary: "#819300", onPrimary: "#fdf6e3", primaryContainer: "#e6e2cc", onPrimaryContainer: "#5c6a72",
      secondary: "#3a94c5", onSecondary: "#fdf6e3", secondaryContainer: "#e6e2cc", onSecondaryContainer: "#5c6a72",
      tertiary: "#cd60aa", onTertiary: "#fdf6e3", tertiaryContainer: "#e6e2cc", onTertiaryContainer: "#5c6a72",
      error: "#f85552", onError: "#fdf6e3", errorContainer: "#e6e2cc", onErrorContainer: "#5c6a72",
      inversePrimary: "#a7c080"
    }
  } else {
    s = {
      base: "#2d353b", dim: "#232a2e", bright: "#3d484d", lowest: "#232a2e",
      low: "#343f44", container: "#3d484d", high: "#475258", highest: "#4f585e",
      variant: "#475258", text: "#d3c6aa", subtext: "#9da9a0", outline: "#859289", outlineVariant: "#475258"
    }
    a = {
      primary: "#a7c080", onPrimary: "#2d353b", primaryContainer: "#475258", onPrimaryContainer: "#d3c6aa",
      secondary: "#7fbbb3", onSecondary: "#2d353b", secondaryContainer: "#475258", onSecondaryContainer: "#d3c6aa",
      tertiary: "#dbbc7f", onTertiary: "#2d353b", tertiaryContainer: "#475258", onTertiaryContainer: "#d3c6aa",
      error: "#e67e80", onError: "#2d353b", errorContainer: "#475258", onErrorContainer: "#d3c6aa",
      inversePrimary: "#8da101"
    }
  }
  return semanticPalette(s, a)
}

// Solarized has only two surface tones, so the high/highest steps reuse base01
// and base02. Text uses the emphasized content tones (base1 / base01) for
// readable contrast.
function solarizedPalette(variant) {
  var s
  var a
  if (variant === "light") {
    s = {
      base: "#fdf6e3", dim: "#eee8d5", bright: "#fdf6e3", lowest: "#fdf6e3",
      low: "#fdf6e3", container: "#eee8d5", high: "#eee8d5", highest: "#93a1a1",
      variant: "#eee8d5", text: "#586e75", subtext: "#657b83", outline: "#93a1a1", outlineVariant: "#93a1a1"
    }
    a = {
      primary: "#268bd2", onPrimary: "#fdf6e3", primaryContainer: "#eee8d5", onPrimaryContainer: "#586e75",
      secondary: "#6c71c4", onSecondary: "#fdf6e3", secondaryContainer: "#eee8d5", onSecondaryContainer: "#586e75",
      tertiary: "#24948b", onTertiary: "#fdf6e3", tertiaryContainer: "#eee8d5", onTertiaryContainer: "#586e75",
      error: "#dc322f", onError: "#fdf6e3", errorContainer: "#eee8d5", onErrorContainer: "#586e75",
      inversePrimary: "#268bd2"
    }
  } else {
    s = {
      base: "#002b36", dim: "#002b36", bright: "#073642", lowest: "#002b36",
      low: "#002b36", container: "#073642", high: "#073642", highest: "#586e75",
      variant: "#073642", text: "#93a1a1", subtext: "#839496", outline: "#657b83", outlineVariant: "#586e75"
    }
    a = {
      primary: "#268bd2", onPrimary: "#002b36", primaryContainer: "#073642", onPrimaryContainer: "#93a1a1",
      secondary: "#6c71c4", onSecondary: "#002b36", secondaryContainer: "#073642", onSecondaryContainer: "#93a1a1",
      tertiary: "#2aa198", onTertiary: "#002b36", tertiaryContainer: "#073642", onTertiaryContainer: "#93a1a1",
      error: "#dc322f", onError: "#002b36", errorContainer: "#073642", onErrorContainer: "#93a1a1",
      inversePrimary: "#268bd2"
    }
  }
  return semanticPalette(s, a)
}

// Vapourwave, Synthwave, Monokai and Oxocarbon are dark only; light mode reuses
// them. Synthwave follows SynthWave '84, Monokai the classic Sublime scheme,
// Oxocarbon the IBM Carbon based nyoom-engineering/oxocarbon dark ramp.
// Vapourwave uses the common pink/cyan/violet vaporwave set on a deep purple base.
function vapourwavePalette() {
  var s = {
    base: "#1b1230", dim: "#150e26", bright: "#2d1f4d", lowest: "#110a20",
    low: "#20163a", container: "#2a1d48", high: "#382862", highest: "#4a3680",
    variant: "#382862", text: "#f4eaff", subtext: "#b9a6d9", outline: "#7a66a8", outlineVariant: "#4a3680"
  }
  var a = {
    primary: "#ff71ce", onPrimary: "#1b1230", primaryContainer: "#4d2450", onPrimaryContainer: "#ffd6f1",
    secondary: "#01cdfe", onSecondary: "#1b1230", secondaryContainer: "#0f3f5a", onSecondaryContainer: "#c9f3ff",
    tertiary: "#b967ff", onTertiary: "#1b1230", tertiaryContainer: "#432a75", onTertiaryContainer: "#ecd9ff",
    error: "#ff6b8a", onError: "#1b1230", errorContainer: "#5a2036", onErrorContainer: "#ffd9e2",
    inversePrimary: "#b43e8f"
  }
  return semanticPalette(s, a)
}

function synthwavePalette() {
  var s = {
    base: "#262335", dim: "#1f1b2e", bright: "#34294f", lowest: "#1a1626",
    low: "#2a2139", container: "#34294f", high: "#463465", highest: "#495495",
    variant: "#463465", text: "#f4eeee", subtext: "#b6b1d4", outline: "#848bbd", outlineVariant: "#495495"
  }
  var a = {
    primary: "#ff7edb", onPrimary: "#262335", primaryContainer: "#5a2a63", onPrimaryContainer: "#ffd6f3",
    secondary: "#36f9f6", onSecondary: "#262335", secondaryContainer: "#1a4a58", onSecondaryContainer: "#c8fffe",
    tertiary: "#fede5d", onTertiary: "#262335", tertiaryContainer: "#5a4a1a", onTertiaryContainer: "#fff3b8",
    error: "#fe4450", onError: "#262335", errorContainer: "#5e1f2b", onErrorContainer: "#ffd6d9",
    inversePrimary: "#b8349a"
  }
  return semanticPalette(s, a)
}

function monokaiPalette() {
  var s = {
    base: "#272822", dim: "#1e1f1c", bright: "#3e3d32", lowest: "#1a1a17",
    low: "#2d2e27", container: "#3e3d32", high: "#49483e", highest: "#75715e",
    variant: "#49483e", text: "#f8f8f2", subtext: "#cfcfc2", outline: "#75715e", outlineVariant: "#49483e"
  }
  var a = {
    primary: "#a6e22e", onPrimary: "#272822", primaryContainer: "#3e4a1c", onPrimaryContainer: "#e3f7b5",
    secondary: "#66d9ef", onSecondary: "#272822", secondaryContainer: "#1f4a54", onSecondaryContainer: "#d0f4fb",
    tertiary: "#fd971f", onTertiary: "#272822", tertiaryContainer: "#5a3a10", onTertiaryContainer: "#ffe0b8",
    error: "#f92672", onError: "#272822", errorContainer: "#5e1a35", onErrorContainer: "#ffd6e4",
    inversePrimary: "#6a9a12"
  }
  return semanticPalette(s, a)
}

function oxocarbonPalette() {
  var s = {
    base: "#161616", dim: "#161616", bright: "#262626", lowest: "#0f0f0f",
    low: "#1c1c1c", container: "#262626", high: "#393939", highest: "#525252",
    variant: "#393939", text: "#f2f4f8", subtext: "#a2a9b0", outline: "#6f6f6f", outlineVariant: "#393939"
  }
  var a = {
    primary: "#78a9ff", onPrimary: "#161616", primaryContainer: "#1c3a6e", onPrimaryContainer: "#d0e2ff",
    secondary: "#be95ff", onSecondary: "#161616", secondaryContainer: "#3d2a6b", onSecondaryContainer: "#e8daff",
    tertiary: "#3ddbd9", onTertiary: "#161616", tertiaryContainer: "#0e4a4a", onTertiaryContainer: "#9ef0f0",
    error: "#ee5396", onError: "#161616", errorContainer: "#5e1a3a", onErrorContainer: "#ffd6e8",
    inversePrimary: "#0f62fe"
  }
  return semanticPalette(s, a)
}

function palette(family, variant, darkMode) {
  var resolved = resolveVariant(family, variant, darkMode)
  if (family === "catppuccin") return catppuccinPalette(resolved)
  if (family === "gruvbox") return gruvboxPalette(resolved)
  if (family === "tokyonight") return tokyonightPalette(resolved)
  if (family === "elenapan") return elenapanPalette()
  if (family === "nord") return nordPalette()
  if (family === "dracula") return draculaPalette()
  if (family === "kanagawa") return kanagawaPalette()
  if (family === "rosepine") return rosepinePalette(resolved)
  if (family === "everforest") return everforestPalette(resolved)
  if (family === "solarized") return solarizedPalette(resolved)
  if (family === "vapourwave") return vapourwavePalette()
  if (family === "synthwave") return synthwavePalette()
  if (family === "monokai") return monokaiPalette()
  if (family === "oxocarbon") return oxocarbonPalette()
  return null
}

// The palette id was spelled "elenapan" before 2026-10-13; settings written
// then still carry it. Map old ids to current ones, pass everything else through.
function migratePaletteId(id) {
  return id === "elenapam" ? "elenapan" : id
}
