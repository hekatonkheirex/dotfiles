#!/usr/bin/env bash
# Gate test: apply_accent_override swaps primary/on_primary in the active cache
# for both modes, ignores roles outside the shortlist, and leaves other keys.
set -euo pipefail
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp
mkdir -p "$HOME/.config/quickshell"
cache_file="$tmp/cache.json"
fixture='{"_seed":"t","scheme-expressive":{
  "light":{"primary":"#111111","on_primary":"#ffffff","tertiary":"#aa0000","on_tertiary":"#fefefe","tertiary_fixed_dim":"#bb0000","on_tertiary_fixed":"#010101"},
  "dark":{"primary":"#222222","on_primary":"#000000","tertiary":"#cc0000","on_tertiary":"#fdfdfd","tertiary_fixed_dim":"#dd0000","on_tertiary_fixed":"#020202"}}}'
# shellcheck disable=SC1090
source <(sed -n '/^apply_accent_override() {/,/^}/p' "$repo/scripts/sync-active-palette.sh")

run() { # palette active -> prints "light.primary light.on dark.primary dark.on"
  printf '{"accentPalette":"%s","accentActive":"%s"}' "$1" "$2" >"$HOME/.config/quickshell/settings.json"
  printf '%s' "$fixture" >"$cache_file"
  apply_accent_override
  jq -r '."scheme-expressive" | [.light.primary,.light.on_primary,.dark.primary,.dark.on_primary] | join(" ")' "$cache_file"
}
check() { [[ "$2" == "$3" ]] || { printf 'FAIL %s: got [%s] want [%s]\n' "$1" "$2" "$3" >&2; exit 1; }; }

check swap        "$(run primary,tertiary tertiary)"              "#aa0000 #fefefe #cc0000 #fdfdfd"
check dim-on-role "$(run tertiary_fixed_dim tertiary_fixed_dim)"  "#bb0000 #010101 #dd0000 #020202"
check not-listed  "$(run primary tertiary)"                       "#111111 #ffffff #222222 #000000"
check empty       "$(run tertiary '')"                            "#111111 #ffffff #222222 #000000"
check bogus-role  "$(run 'bogus' bogus)"                          "#111111 #ffffff #222222 #000000"
check missing-key "$(run secondary secondary)"                    "#111111 #ffffff #222222 #000000"
echo "accent override: ok"
