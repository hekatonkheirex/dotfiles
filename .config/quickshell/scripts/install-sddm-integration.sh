#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
helper_source="$script_dir/sync-sddm-theme-root.sh"
policy_source="$script_dir/org.quickshell.sddm-theme.policy"
helper_target=/usr/local/libexec/quickshell-sync-sddm-theme
policy_target=/usr/share/polkit-1/actions/org.quickshell.sddm-theme.policy

usage() {
  cat <<'EOF'
Usage: install-sddm-integration.sh [--dry-run]

Install the root-owned SDDM bridge and its polkit policy used by Quickshell's
style selector. SDDM theme assets are installed by their own theme projects.
EOF
}

dry_run=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
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

if [[ ! -f "$helper_source" ]]; then
  printf 'Missing SDDM bridge source: %s\n' "$helper_source" >&2
  exit 1
fi
if [[ ! -f "$policy_source" ]]; then
  printf 'Missing polkit policy source: %s\n' "$policy_source" >&2
  exit 1
fi
if ! grep -Fq 'ghost)' "$helper_source" || ! grep -Fq 'theme_name="Ghost-SDDM"' "$helper_source"; then
  printf 'SDDM bridge source does not contain Ghost support: %s\n' "$helper_source" >&2
  exit 1
fi
if ! grep -Fq '<annotate key="org.freedesktop.policykit.exec.path">/usr/local/libexec/quickshell-sync-sddm-theme</annotate>' "$policy_source"; then
  printf 'Polkit policy does not point at the installed SDDM bridge: %s\n' "$policy_source" >&2
  exit 1
fi

if (( dry_run )); then
  printf 'Would install %s -> %s\n' "$helper_source" "$helper_target"
  printf 'Would install %s -> %s\n' "$policy_source" "$policy_target"
  exit 0
fi

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    printf '%s\n' 'Installing the SDDM integration requires root, but sudo was not found.' >&2
    exit 1
  fi
  exec sudo -- "$0"
fi

install -D -o root -g root -m 0755 "$helper_source" "$helper_target"
install -D -o root -g root -m 0644 "$policy_source" "$policy_target"

printf 'Installed Quickshell SDDM integration.\n'
printf '  bridge: %s\n' "$helper_target"
printf '  policy: %s\n' "$policy_target"
printf '\nRun scripts/verify-sddm-integration.sh to check the bridge and theme assets.\n'
