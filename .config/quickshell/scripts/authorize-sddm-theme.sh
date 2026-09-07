#!/usr/bin/env bash
set -u

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
theme_name="${1:-}"
source_dir="${2:-}"

if sudo "$script_dir/install-sddm-theme.sh" "$theme_name" "$source_dir"; then
    notify-send \
        --app-name="Quickshell" \
        --urgency=normal \
        "SDDM theme updated" \
        "$theme_name is now selected for the next login screen." \
        >/dev/null 2>&1 || true
    printf 'SDDM theme updated: %s\n' "$theme_name"
    exit 0
fi

notify-send \
    --app-name="Quickshell" \
    --urgency=critical \
    "SDDM theme update failed" \
    "Authorization was cancelled or the SDDM theme could not be installed." \
    >/dev/null 2>&1 || true
printf 'SDDM theme update failed.\n' >&2
exit 1
