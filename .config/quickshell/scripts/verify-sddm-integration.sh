#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
helper_source="$script_dir/sync-sddm-theme-root.sh"
policy_source="$script_dir/org.quickshell.sddm-theme.policy"
helper_target=/usr/local/libexec/quickshell-sync-sddm-theme
policy_target=/usr/share/polkit-1/actions/org.quickshell.sddm-theme.policy
theme_root=/usr/share/sddm/themes
bridge_only=0

usage() {
  cat <<'EOF'
Usage: verify-sddm-integration.sh [--theme-root PATH] [--bridge-only]

Verify the root-owned Quickshell SDDM bridge, its polkit policy, and the
required files for every supported SDDM theme. --theme-root is useful for
checking a staged theme directory before copying it system-wide.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --theme-root)
      [[ -n ${2:-} ]] || { printf '%s\n' 'Missing value for --theme-root.' >&2; exit 2; }
      theme_root=$2
      shift 2
      ;;
    --bridge-only)
      bridge_only=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

failures=0
pass_check() {
  printf 'OK   %s\n' "$1"
}
fail_check() {
  printf 'FAIL %s\n' "$1" >&2
  failures=$((failures + 1))
}

if [[ -f "$helper_source" ]] && grep -Fq 'ghost)' "$helper_source" && grep -Fq 'theme_name="Ghost-SDDM"' "$helper_source"; then
  pass_check 'source bridge contains Ghost support'
else
  fail_check "source bridge contains Ghost support ($helper_source)"
fi

if [[ -f "$policy_source" ]] && grep -Fq '<annotate key="org.freedesktop.policykit.exec.path">/usr/local/libexec/quickshell-sync-sddm-theme</annotate>' "$policy_source"; then
  pass_check 'source polkit policy points at the installed bridge'
else
  fail_check "source polkit policy points at the installed bridge ($policy_source)"
fi

if [[ -x "$helper_target" ]]; then
  pass_check "installed bridge is executable ($helper_target)"
else
  fail_check "installed bridge is executable ($helper_target)"
fi

if [[ -f "$helper_target" && -f "$helper_source" ]] && cmp -s "$helper_source" "$helper_target"; then
  pass_check 'installed bridge matches the source bridge'
else
  fail_check 'installed bridge matches the source bridge'
fi

if [[ -f "$policy_target" ]] && grep -Fq '<annotate key="org.freedesktop.policykit.exec.path">/usr/local/libexec/quickshell-sync-sddm-theme</annotate>' "$policy_target"; then
  pass_check "installed polkit policy points at the bridge ($policy_target)"
else
  fail_check "installed polkit policy points at the bridge ($policy_target)"
fi

if (( ! bridge_only )); then
  themes=(
    Material3-Expressive-Dynamic-SDDM
    Material3-Expressive-Dynamic-Dark-SDDM
    Neo-Brutalism-SDDM
    Neo-Brutalism-Dark-SDDM
    Nothing-OS-SDDM
    Nothing-OS-Dark-SDDM
    Ghost-SDDM
  )
  for theme in "${themes[@]}"; do
    missing=()
    for required_file in Main.qml metadata.desktop theme.conf; do
      [[ -f "$theme_root/$theme/$required_file" ]] || missing+=("$required_file")
    done
    if (( ${#missing[@]} == 0 )); then
      pass_check "$theme is complete in $theme_root"
    else
      fail_check "$theme is missing ${missing[*]} in $theme_root"
    fi
  done
else
  printf 'SKIP theme asset checks (--bridge-only)\n'
fi

if (( failures > 0 )); then
  printf '\nSDDM integration verification failed (%d check(s)).\n' "$failures" >&2
  exit 1
fi

printf '\nSDDM integration verification passed.\n'
