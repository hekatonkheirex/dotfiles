#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf '%s\n' 'This helper must be executed as root.' >&2
  exit 1
fi

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s <light|dark> <material3|neo-brutalism|nothing|ghost>\n' "$0" >&2
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
  ghost)
    # Ghost recovered one dark-only greeter. Keep it selected for both desktop
    # modes; the greeter itself owns its fixed HUD palette.
    theme_name="Ghost-SDDM"
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

# /etc/sddm.conf.d/*.conf is NOT honored by the installed sddm build (Current=
# in /etc/sddm.conf wins regardless of drop-in files). Patch the base config's
# [Theme] Current= line directly so the change actually takes effect.
main_conf=/etc/sddm.conf
if [[ -f "$main_conf" ]] && grep -q '^Current=' "$main_conf"; then
  sed -i "s/^Current=.*/Current=$theme_name/" "$main_conf"
else
  printf 'Warning: could not find "Current=" in %s; SDDM base config left unchanged.\n' "$main_conf" >&2
fi

printf 'SDDM theme set to %s for %s mode.\n' "$theme_name" "$mode"
