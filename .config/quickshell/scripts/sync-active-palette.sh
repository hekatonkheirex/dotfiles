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
mode=auto
palette_source=auto

usage() {
  cat <<'EOF'
Usage: sync-active-palette.sh [--source live|fixed|auto] [--skip-matugen] [--activate-only] [light|dark|auto]

Render the current Matugen cache, rebuild the installed theme outputs, and
refresh the active desktop, terminal, editor, monitor, and Niri theme state.

  --skip-matugen  Use a cache that was already rendered by matugen image.
  --source        Activate the Live or Fixed cache before rendering.
  --activate-only Select the cache without running the theme generators.
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
theme_sync="$HOME/.local/bin/sync-theme-mode.sh"

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

activate_palette_cache

if (( activate_only )); then
  exit 0
fi

if (( ! skip_matugen )); then
  if [[ ! -x "$matugen_bin" ]]; then
    printf 'Matugen executable not found: %s\n' "$matugen_bin" >&2
    exit 1
  fi

  # `json` treats the two-mode cache as Matugen render data. This keeps fixed
  # palettes on Matugen's template/configuration path instead of maintaining
  # a second set of Kitty, Starship, or other output templates here.
  "$matugen_bin" --quiet --type scheme-expressive --json hex json "$cache_file" >/dev/null
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
if (( sync_failed || generation_failed )); then
  exit 2
fi
