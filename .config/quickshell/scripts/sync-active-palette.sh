#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=theme-sync-lock.sh
source "$script_dir/theme-sync-lock.sh"

# Activate the selected semantic Matugen cache through the same pipeline used
# by wallpaper changes. Live and Fixed own separate inputs so changing source
# never destroys the wallpaper-generated palette.

skip_matugen=0
activate_only=0
terminal_only=0
mode=auto
palette_source=auto

usage() {
  cat <<'EOF'
Usage: sync-active-palette.sh [--source live|fixed|auto] [--skip-matugen] [--activate-only] [--terminal-only] [light|dark|auto]

Render the current Matugen cache, rebuild the installed theme outputs, and
refresh the active desktop, terminal, editor, monitor, and Niri theme state.

  --skip-matugen  Use a cache that was already rendered by matugen image.
  --source        Activate the Live or Fixed cache before rendering.
  --activate-only Select the cache without running the theme generators.
  --terminal-only Refresh the existing Matugen terminal paths from the active cache.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-matugen)
      skip_matugen=1
      shift
      ;;
    --activate-only)
      activate_only=1
      shift
      ;;
    --terminal-only)
      terminal_only=1
      shift
      ;;
    --source)
      if [[ $# -lt 2 ]]; then
        printf 'Missing value for --source.\n' >&2
        usage >&2
        exit 2
      fi
      palette_source=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    light|dark|auto)
      mode=$1
      shift
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$palette_source" != "auto" && "$palette_source" != "live" && "$palette_source" != "fixed" ]]; then
  printf 'Invalid palette source: %s\n' "$palette_source" >&2
  usage >&2
  exit 2
fi

cache_dir="$HOME/.cache/matugen"
cache_file="$HOME/.cache/matugen/current_palette.json"
live_cache_file="$cache_dir/live_palette.json"
fixed_cache_file="$cache_dir/fixed_palette.json"
matugen_bin="${MATUGEN_BIN:-/usr/bin/matugen}"
theme_generator="$HOME/.local/bin/generate-all-themes.sh"
# Route palette-triggered mode changes through the tracked wrapper so Liquid
# Glass can pair its Quickshell surfaces with the installed MacTahoe
# GTK/icons/Kvantum/cursor assets.
theme_sync="$HOME/.config/quickshell/scripts/sync-theme-mode-locked.sh"

mkdir -p "$cache_dir"

if [[ "$palette_source" == "auto" ]]; then
  palette_source=$(jq -r '.colorSource // "live"' "$HOME/.config/quickshell/settings.json" 2>/dev/null || printf 'live')
  [[ "$palette_source" == "fixed" ]] || palette_source=live
fi

# QML may serialize a color as an object with normalized r/g/b channels when
# it writes a fixed palette. Matugen's render data accepts that shape, but the
# shell generators consume the cache as hex strings. Normalize both old and
# new caches before handing them to the shared generator pipeline.
normalize_cache_file() {
  if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required to normalize the Matugen cache.\n' >&2
    return 1
  fi

  local cache_path=$1
  local normalized_cache
  normalized_cache=$(mktemp "${cache_path}.normalize.XXXXXX")
  if ! jq '
    def hex_byte:
      ((. * 255) | round) as $value
      | ($value / 16 | floor) as $high
      | ($value % 16) as $low
      | ("0123456789abcdef"[$high:($high + 1)]
        + "0123456789abcdef"[$low:($low + 1)]);
    walk(
      if type == "object"
        and (.r | type) == "number"
        and (.g | type) == "number"
        and (.b | type) == "number"
      then
        ("#" + (.r | hex_byte) + (.g | hex_byte) + (.b | hex_byte))
      else .
      end
    )
  ' "$cache_path" >"$normalized_cache"; then
    rm -f -- "$normalized_cache"
    printf 'Could not normalize Matugen cache: %s\n' "$cache_path" >&2
    return 1
  fi

  if ! cmp -s "$normalized_cache" "$cache_path"; then
    mv -f -- "$normalized_cache" "$cache_path"
  else
    rm -f -- "$normalized_cache"
  fi
}

activate_palette_cache() {
  local source_file
  case "$palette_source" in
    fixed)
      source_file=$fixed_cache_file
      if [[ ! -f "$source_file" && -f "$cache_file" ]]; then
        local seed
        seed=$(jq -r '._seed // ""' "$cache_file" 2>/dev/null || true)
        if [[ "$seed" == fixed:* ]]; then
          cp -- "$cache_file" "$source_file"
        fi
      fi
      ;;
    live)
      source_file=$live_cache_file
      if [[ ! -f "$source_file" && -f "$cache_file" ]]; then
        local seed
        seed=$(jq -r '._seed // ""' "$cache_file" 2>/dev/null || true)
        if [[ -z "$seed" || "$seed" != fixed:* ]]; then
          cp -- "$cache_file" "$source_file"
        fi
      fi
      ;;
  esac

  if [[ ! -f "$source_file" ]]; then
    printf '%s palette cache not found: %s\n' "$palette_source" "$source_file" >&2
    return 1
  fi

  normalize_cache_file "$source_file"

  local active_cache
  active_cache=$(mktemp "${cache_file}.activate.XXXXXX")
  if ! cp -- "$source_file" "$active_cache"; then
    rm -f -- "$active_cache"
    printf 'Could not activate palette cache: %s\n' "$source_file" >&2
    return 1
  fi
  mv -f -- "$active_cache" "$cache_file"
}

# Matugen's JSON command is the render step for the fixed and live caches. The
# cache already uses Matugen's two-mode render-data shape, so keep Matugen's
# normalized output as the one source consumed by Quickshell and every theme
# generator. This also updates the cache atomically, which makes FileView's
# reload deterministic while a palette is changing.
render_matugen_cache() {
  if [[ ! -x "$matugen_bin" ]]; then
    printf 'Matugen executable not found: %s\n' "$matugen_bin" >&2
    return 1
  fi

  local rendered_cache
  rendered_cache=$(mktemp "${cache_file}.render.XXXXXX")
  if ! "$matugen_bin" --quiet --type scheme-expressive --json hex json "$cache_file" >"$rendered_cache"; then
    rm -f -- "$rendered_cache"
    printf 'Matugen could not render the active cache: %s\n' "$cache_file" >&2
    return 1
  fi

  if ! jq -e '
    ."scheme-expressive".light
    and ."scheme-expressive".dark
    and (."scheme-expressive".light.primary | type == "string")
    and (."scheme-expressive".dark.primary | type == "string")
  ' "$rendered_cache" >/dev/null 2>&1; then
    rm -f -- "$rendered_cache"
    printf 'Matugen returned an invalid two-mode palette.\n' >&2
    return 1
  fi

  mv -f -- "$rendered_cache" "$cache_file"
}

# Keep the existing Matugen Kitty, Starship, and btop paths in sync with the
# active cache. These are generated in place so Kitty's existing include and
# btop's existing color_theme setting continue to work without introducing a
# second set of variant files. Liquid Glass intentionally keeps these same
# Matugen consumers; only Quickshell's own surfaces and the GTK/icon/Qt
# companion change. Neo Brutalism has its own Kitty/Starship generator, but
# still uses the shared btop path.
refresh_matugen_terminal_assets() {
  local scheme ui_style
  scheme=$(cat "$HOME/.config/quickshell/colorscheme" 2>/dev/null || printf 'matugen')
  ui_style=$(jq -r '.themeStyle // "material3"' "$HOME/.config/quickshell/settings.json" 2>/dev/null || printf 'material3')

  [[ "$scheme" == "matugen" ]] || return 0
  case "$ui_style" in
    material3|neo-brutalism|liquid-glass) ;;
    *) return 0 ;;
  esac

  if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required to refresh Matugen terminal assets.\n' >&2
    return 1
  fi

  local kitty_dir="$HOME/.config/kitty"
  local starship_dir="$HOME/.config/starship"
  local btop_file="$HOME/.config/btop/themes/catppuccin_mocha.theme"
  mkdir -p -- "$kitty_dir" "$starship_dir" "$(dirname "$btop_file")"

  palette_role() {
    local palette_mode=$1
    local role=$2
    jq -er --arg mode "$palette_mode" --arg role "$role" \
      '."scheme-expressive"[$mode][$role] // empty
       | select(type == "string" and test("^#[0-9A-Fa-f]{6}$"))' \
      "$cache_file" 2>/dev/null
  }

  write_kitty_theme() {
    local palette_mode=$1
    local background foreground selection_background selection_foreground
    local primary on_primary tertiary secondary on_surface_variant surface_container
    local primary_container tertiary_container secondary_container error outline
    background=$(palette_role "$palette_mode" background)
    foreground=$(palette_role "$palette_mode" on_surface)
    selection_background=$(palette_role "$palette_mode" surface_container_high)
    selection_foreground=$(palette_role "$palette_mode" on_surface)
    primary=$(palette_role "$palette_mode" primary)
    on_primary=$(palette_role "$palette_mode" on_primary)
    tertiary=$(palette_role "$palette_mode" tertiary)
    secondary=$(palette_role "$palette_mode" secondary)
    on_surface_variant=$(palette_role "$palette_mode" on_surface_variant)
    surface_container=$(palette_role "$palette_mode" surface_container)
    primary_container=$(palette_role "$palette_mode" primary_container)
    tertiary_container=$(palette_role "$palette_mode" tertiary_container)
    secondary_container=$(palette_role "$palette_mode" secondary_container)
    error=$(palette_role "$palette_mode" error)
    outline=$(palette_role "$palette_mode" outline)

    local output="$kitty_dir/matugen-$palette_mode.conf"
    local temporary
    temporary=$(mktemp "${output}.tmp.XXXXXX")
    if ! cat >"$temporary" <<EOF
# Material 3 Expressive $palette_mode — generated from the active Matugen palette
# ANSI role mapping: black=surface_container red=error green=tertiary
# yellow=primary blue=secondary
foreground            $foreground
background            $background
selection_foreground  $selection_foreground
selection_background  $selection_background

cursor                $primary
cursor_text_color     $on_primary

url_color             $tertiary

active_tab_foreground   $on_primary
active_tab_background   $primary
inactive_tab_foreground $on_surface_variant
inactive_tab_background $surface_container

background_opacity         1.0
dynamic_background_opacity yes

# ANSI — Normal (0-7)
color0  $surface_container
color1  $error
color2  $tertiary
color3  $primary
color4  $secondary
color5  $tertiary_container
color6  $secondary_container
color7  $on_surface_variant

# ANSI — Bright (8-15)
color8  $outline
color9  $error
color10 $tertiary
color11 $primary_container
color12 $secondary
color13 $tertiary_container
color14 $secondary_container
color15 $foreground
EOF
    then
      rm -f -- "$temporary"
      return 1
    fi
    mv -f -- "$temporary" "$output"
  }

  write_starship_theme() {
    local palette_mode=$1
    local foreground primary secondary tertiary error
    foreground=$(palette_role "$palette_mode" on_surface)
    primary=$(palette_role "$palette_mode" primary)
    secondary=$(palette_role "$palette_mode" secondary)
    tertiary=$(palette_role "$palette_mode" tertiary)
    error=$(palette_role "$palette_mode" error)

    local output="$starship_dir/matugen-$palette_mode.toml"
    local temporary
    temporary=$(mktemp "${output}.tmp.XXXXXX")
    if ! cat >"$temporary" <<EOF
# Material 3 Expressive Starship prompt — generated from the active Matugen palette
format = """
\$username\\
\$hostname\\
\$directory\\
\$git_branch\\
\$git_state\\
\$git_status\\
\$fill\\
\$cmd_duration\\
\$line_break\\
\$python\\
\$lua\\
\$c\\
\$rust\\
\$perl\\
\$php\\
\$ruby\\
\$character"""

[fill]
symbol = ' '

[directory]
read_only = " 󰌾"
style = "$foreground"

[character]
success_symbol = "[❯]($tertiary)"
error_symbol = "[❯]($error)"
vimcmd_symbol = "[❮]($secondary)"

[git_branch]
format = "[\$branch](\$style)"
style = "$secondary"

[git_status]
format = "[[(*\$conflicted\$untracked\$modified\$staged\$renamed\$deleted)](218) (\$ahead_behind\$stashed)](\$style)"
style = "$foreground"
conflicted = "​"
untracked = "​"
modified = "​"
staged = "​"
renamed = "​"
deleted = "​"
stashed = "≡"

[git_state]
format = '\\([\$state( \$progress_current/\$progress_total)](\$style)\\) '
style = "$primary"

[cmd_duration]
format = " [\$duration](\$style) "
style = "$primary"

[time]
disabled = false
time_format = "%T"
format = '\$time'

[c]
symbol = '󰙱 '
style = "$primary"

[lua]
symbol = "󰢱 "
style = "$primary"

[nodejs]
symbol = "⬢ "
style = "$primary"

[perl]
symbol = " "
style = "$primary"

[php]
symbol = " "
style = "$primary"

[python]
symbol = " "
style = "$primary"

[ruby]
symbol = " "
style = "$primary"

[rust]
symbol = " "
style = "$primary"
EOF
    then
      rm -f -- "$temporary"
      return 1
    fi
    mv -f -- "$temporary" "$output"
  }

  write_btop_theme() {
    local palette_mode=$1
    local background foreground primary secondary tertiary error outline
    local surface_container_high on_surface_variant
    background=$(palette_role "$palette_mode" background)
    foreground=$(palette_role "$palette_mode" on_surface)
    primary=$(palette_role "$palette_mode" primary)
    secondary=$(palette_role "$palette_mode" secondary)
    tertiary=$(palette_role "$palette_mode" tertiary)
    error=$(palette_role "$palette_mode" error)
    outline=$(palette_role "$palette_mode" outline)
    surface_container_high=$(palette_role "$palette_mode" surface_container_high)
    on_surface_variant=$(palette_role "$palette_mode" on_surface_variant)

    local temporary
    temporary=$(mktemp "${btop_file}.tmp.XXXXXX")
    if ! cat >"$temporary" <<EOF
# Matugen $palette_mode — generated from the active Matugen palette
theme[main_bg]="$background"
theme[main_fg]="$foreground"
theme[title]="$foreground"
theme[hi_fg]="$primary"
theme[selected_bg]="$surface_container_high"
theme[selected_fg]="$tertiary"
theme[inactive_fg]="$on_surface_variant"
theme[graph_text]="$tertiary"
theme[meter_bg]="$surface_container_high"
theme[proc_misc]="$tertiary"
theme[cpu_box]="$primary"
theme[mem_box]="$secondary"
theme[net_box]="$tertiary"
theme[proc_box]="$primary"
theme[div_line]="$outline"
theme[temp_start]="$tertiary"
theme[temp_mid]="$primary"
theme[temp_end]="$error"
theme[cpu_start]="$tertiary"
theme[cpu_mid]="$primary"
theme[cpu_end]="$error"
theme[free_start]="$tertiary"
theme[free_mid]="$primary"
theme[free_end]="$error"
theme[cached_start]="$tertiary"
theme[cached_mid]="$primary"
theme[cached_end]="$error"
theme[available_start]="$tertiary"
theme[available_mid]="$primary"
theme[available_end]="$error"
theme[used_start]="$tertiary"
theme[used_mid]="$primary"
theme[used_end]="$error"
theme[download_start]="$tertiary"
theme[download_mid]="$primary"
theme[download_end]="$error"
theme[upload_start]="$tertiary"
theme[upload_mid]="$primary"
theme[upload_end]="$error"
EOF
    then
      rm -f -- "$temporary"
      return 1
    fi
    mv -f -- "$temporary" "$btop_file"
  }

  local active_mode=$mode
  if [[ "$active_mode" == "auto" ]]; then
    active_mode=$("$HOME/.local/bin/auto-detect-theme.sh" 2>/dev/null || printf 'dark')
  fi
  [[ "$active_mode" == "light" || "$active_mode" == "dark" ]] || active_mode=dark

  if [[ "$ui_style" == "material3" || "$ui_style" == "liquid-glass" ]]; then
    write_kitty_theme light
    write_kitty_theme dark
    write_starship_theme light
    write_starship_theme dark
  fi
  write_btop_theme "$active_mode"
}

if (( terminal_only )); then
  if [[ ! -f "$cache_file" ]]; then
    printf 'Active Matugen cache not found: %s\n' "$cache_file" >&2
    exit 1
  fi
  if ! refresh_matugen_terminal_assets; then
    printf 'Matugen terminal refresh failed.\n' >&2
    exit 2
  fi
  exit 0
fi

activate_palette_cache

if (( activate_only )); then
  exit 0
fi

if (( ! skip_matugen )); then
  render_matugen_cache
fi

generation_failed=0
if [[ -x "$theme_generator" ]]; then
  if ! "$theme_generator"; then
    generation_failed=1
    printf 'Theme regeneration failed; keeping the active Matugen cache.\n' >&2
  fi
else
  generation_failed=1
  printf 'Theme generator not found: %s\n' "$theme_generator" >&2
fi

terminal_generation_failed=0
if ! refresh_matugen_terminal_assets; then
  terminal_generation_failed=1
  printf 'Matugen terminal refresh failed; keeping the previous terminal assets.\n' >&2
fi

sync_failed=0
if [[ -x "$theme_sync" ]]; then
  if ! "$theme_sync" "$mode" --quiet; then
    sync_failed=1
    printf 'Theme mode synchronization incomplete; keeping the active palette.\n' >&2
  fi
else
  sync_failed=1
  printf 'Theme synchronizer not found: %s\n' "$theme_sync" >&2
fi

# Palette activation and Matugen rendering are the hard failures. Once the
# active cache is valid, Quickshell can use the new colors even if an external
# desktop/theme refresh is incomplete, so report both secondary failures with
# the same partial-success status.
if (( sync_failed || generation_failed || terminal_generation_failed )); then
  exit 2
fi
