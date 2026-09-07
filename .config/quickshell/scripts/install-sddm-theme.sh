#!/usr/bin/env bash
set -euo pipefail

theme_name="${1:-}"
source_dir="${2:-}"

case "$theme_name" in
    Material3-Expressive-Dynamic-SDDM|Material3-Expressive-Dynamic-Dark-SDDM|\
    Material3-Expressive-Tokyo-Night-SDDM|Material3-Expressive-Tokyo-Night-Dark-SDDM)
        ;;
    *)
        printf 'Unsupported SDDM theme: %s\n' "$theme_name" >&2
        exit 64
        ;;
esac

case "$source_dir" in
    /home/*/.local/share/sddm/themes/"$theme_name")
        ;;
    *)
        printf 'Unsupported SDDM source path: %s\n' "$source_dir" >&2
        exit 64
        ;;
esac

if [[ ! -f "$source_dir/Main.qml" || ! -f "$source_dir/theme.conf" ]]; then
    printf 'Generated SDDM theme is incomplete: %s\n' "$source_dir" >&2
    exit 1
fi

target_dir="/usr/share/sddm/themes/$theme_name"
install -d -o root -g root -m 0755 "$target_dir"
cp -a --no-preserve=ownership "$source_dir/." "$target_dir/"
chown -R root:root "$target_dir"
sed -i -E "s|^Current=.*|Current=$theme_name|" /etc/sddm.conf
