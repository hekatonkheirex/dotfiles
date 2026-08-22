#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf '%s\n' 'This helper must be executed as root.' >&2
  exit 1
fi

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s <light|dark> <material3|neo-brutalism|nothing>\n' "$0" >&2
  exit 2
fi

mode=$1
ui_style=$2

case "$mode" in
  light|dark) ;;
  *)
    printf 'Unsupported SDDM mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac

case "$ui_style" in
  nothing)
    theme_name="Nothing-OS-SDDM"
    [[ "$mode" == "dark" ]] && theme_name="Nothing-OS-Dark-SDDM"
    ;;
  material3)
    theme_name="Material3-Expressive-Dynamic-SDDM"
    [[ "$mode" == "dark" ]] && theme_name="Material3-Expressive-Dynamic-Dark-SDDM"
    ;;
  neo-brutalism)
    theme_name="Neo-Brutalism-SDDM"
    [[ "$mode" == "dark" ]] && theme_name="Neo-Brutalism-Dark-SDDM"
    ;;
  *)
    printf 'Unsupported UI style for SDDM: %s\n' "$ui_style" >&2
    exit 2
    ;;
esac

theme_dir="/usr/share/sddm/themes/$theme_name"
for required_file in Main.qml metadata.desktop theme.conf; do
  if [[ ! -f "$theme_dir/$required_file" ]]; then
    printf 'Installed SDDM theme is incomplete: %s\n' "$theme_dir/$required_file" >&2
    exit 1
  fi
done

config_dir=/etc/sddm.conf.d
config_file="$config_dir/99-quickshell-theme.conf"
install -d -o root -g root -m 0755 "$config_dir"

temp_file=$(mktemp "$config_dir/.99-quickshell-theme.conf.XXXXXX")
cleanup() {
  rm -f -- "$temp_file"
}
trap cleanup EXIT

cat > "$temp_file" <<EOF
# Managed by Quickshell's appearance selector. Do not edit directly.
[Theme]
Current=$theme_name
EOF
chown root:root "$temp_file"
chmod 0644 "$temp_file"
mv -f -- "$temp_file" "$config_file"
trap - EXIT

printf 'SDDM theme set to %s for %s mode. It will apply on the next greeter start.\n' "$theme_name" "$mode"
