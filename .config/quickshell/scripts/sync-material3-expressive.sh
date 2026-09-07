#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
settings_file="$config_home/quickshell/settings.json"
legacy_palette="$cache_home/matugen/current_palette.json"
state_dir="$state_home/quickshell"
state_file="$state_dir/material3-expressive.json"
log_file="$state_dir/material3-expressive.log"
projects_dir="$HOME/Projects"
notify_requested=false
[[ "${1:-}" == "--notify" ]] && notify_requested=true

mkdir -p -- "$state_dir"
mkdir -p -- "$cache_home/quickshell"

lock_file="$state_dir/material3-expressive.lock"
exec 9>"$lock_file"
flock -n 9 || exit 0

if [[ ! -f "$settings_file" ]]; then
    printf 'Quickshell settings not found: %s\n' "$settings_file" >&2
    exit 1
fi

palette_source=$(jq -r '.paletteSource // "builtin"' "$settings_file")
theme_mode=$(jq -r '.themeMode // "dark"' "$settings_file")
shell_mode=$(jq -r '.shellThemeMode // "follow"' "$settings_file")

mode="$shell_mode"
if [[ "$mode" == "follow" ]]; then
    mode="$theme_mode"
fi
if [[ "$mode" == "auto" ]]; then
    mode=$("$script_dir/detect-wallpaper-mode.sh" 2>/dev/null || printf 'dark')
fi
[[ "$mode" == "light" ]] || mode="dark"

replace_setting() {
    local file="$1"
    local key="$2"
    local value="$3"
    sed -i -E "s|^${key}=.*|${key}=${value}|" "$file"
}

set_kvantum_theme() {
    local theme_name="$1"
    local kvantum_dir="$config_home/Kvantum"
    local kvantum_config="$kvantum_dir/kvantum.kvconfig"

    mkdir -p -- "$kvantum_dir"
    if [[ ! -f "$kvantum_config" ]]; then
        printf '[General]\ntheme=%s\n' "$theme_name" >"$kvantum_config"
    elif grep -q '^theme=' "$kvantum_config"; then
        sed -i -E "s|^theme=.*|theme=${theme_name}|" "$kvantum_config"
    elif grep -q '^\[General\]$' "$kvantum_config"; then
        sed -i "/^\[General\]$/a theme=${theme_name}" "$kvantum_config"
    else
        printf '\n[General]\ntheme=%s\n' "$theme_name" >>"$kvantum_config"
    fi
}

generator_digest=$(
    sha256sum \
        "$projects_dir/material3-expressive-theme/generate.py" \
        "$projects_dir/material3-expressive-icons/generate.py" \
        "$projects_dir/material3-expressive-kvantum/generate.py" \
        "$projects_dir/material3-expressive-sddm/generate.py" \
        "$projects_dir/material3-expressive-shared/palette.py" \
        "$projects_dir/material3-expressive-shared/static_palette.py" \
        | sha256sum \
        | awk '{print $1}'
)

link_file() {
    local source="$1"
    local destination="$2"

    if [[ -L "$destination" || -f "$destination" ]]; then
        rm -f -- "$destination"
    elif [[ -e "$destination" ]]; then
        printf 'Cannot replace non-file theme path: %s\n' "$destination" >&2
        return 1
    fi
    ln -s -- "$source" "$destination"
}

apply_gsettings() {
    local gtk_theme="$1"
    local icon_theme="$2"
    local dark_value="$3"

    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "'prefer-${mode}'" 2>/dev/null || true

    replace_setting "$config_home/gtk-3.0/settings.ini" gtk-theme-name "$gtk_theme"
    replace_setting "$config_home/gtk-3.0/settings.ini" gtk-icon-theme-name "$icon_theme"
    replace_setting "$config_home/gtk-3.0/settings.ini" gtk-application-prefer-dark-theme "$dark_value"
    replace_setting "$config_home/gtk-4.0/settings.ini" gtk-theme-name "$gtk_theme"
    replace_setting "$config_home/gtk-4.0/settings.ini" gtk-icon-theme-name "$icon_theme"
    replace_setting "$config_home/gtk-4.0/settings.ini" gtk-application-prefer-dark-theme "$dark_value"
}

apply_generated_css() {
    local theme_dir="$1"
    local gtk4_dir="$theme_dir/gtk-4.0"

    link_file "$theme_dir/gtk-3.0/gtk.css" "$config_home/gtk-3.0/gtk.css"
    link_file "$gtk4_dir/gtk.css" "$config_home/gtk-4.0/gtk.css"
    link_file "$gtk4_dir/gtk-dark.css" "$config_home/gtk-4.0/gtk-dark.css"
    link_file "$gtk4_dir/assets" "$config_home/gtk-4.0/assets"
    link_file "$gtk4_dir/windows-assets" "$config_home/gtk-4.0/windows-assets"
}

notify_sddm_update() {
    local urgency="$1"
    local title="$2"
    local body="$3"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send \
            --app-name="Quickshell" \
            --urgency="$urgency" \
            "$title" \
            "$body" \
            >/dev/null 2>&1 || true
    fi
}

polkit_agent_available() {
    ps -eo args= 2>/dev/null \
        | grep -Eqi '[h]yprpolkitagent|[p]olkit-(gnome|kde|mate|lxqt|xfce).*agent|[p]olkit.*authentication-agent'
}

polkit_helper_socket_active() {
    [[ -S /run/polkit/agent-helper.socket ]]
}

authorize_sddm_from_terminal() {
    local theme_name="$1"
    local source_dir="$2"

    if [[ -t 0 ]]; then
        "$script_dir/authorize-sddm-theme.sh" "$theme_name" "$source_dir"
        return $?
    fi

    local kitty_bin
    if kitty_bin=$(command -v kitty 2>/dev/null); then
        notify_sddm_update normal \
            "SDDM authorization needed" \
            "A terminal was opened so you can authorize the SDDM theme with your password."
        nohup "$kitty_bin" \
            --title="Authorize SDDM theme" \
            "$script_dir/authorize-sddm-theme.sh" \
            "$theme_name" \
            "$source_dir" \
            >/dev/null 2>&1 &
        return 0
    fi

    return 1
}

generate_dynamic_themes() {
    local palette_digest="static"
    local wallpaper=""
    if [[ -f "$legacy_palette" ]]; then
        palette_digest=$(sha256sum "$legacy_palette" | awk '{print $1}')
        wallpaper=$(jq -r '._seed // ""' "$legacy_palette")
    fi
    local previous_digest
    previous_digest=$(jq -r '.paletteDigest // ""' "$state_file" 2>/dev/null || true)
    local previous_generator_digest
    previous_generator_digest=$(jq -r '.generatorDigest // ""' "$state_file" 2>/dev/null || true)

    if [[ "$palette_digest" == "$previous_digest" \
        && "$generator_digest" == "$previous_generator_digest" \
        && -d "$HOME/.themes/Material3-Expressive-Dynamic" \
        && -d "$HOME/.local/share/icons/Material3-Expressive-Dynamic-Icons" \
        && -d "$config_home/Kvantum/Material3-Expressive-Dynamic" \
        && -d "$HOME/.local/share/sddm/themes/Material3-Expressive-Dynamic-SDDM" \
        && -d "$HOME/.themes/Material3-Expressive-Tokyo-Night" \
        && -d "$HOME/.themes/Material3-Expressive-Tokyo-Night-Dark" \
        && -d "$HOME/.local/share/icons/Material3-Expressive-Tokyo-Night-Icons" \
        && -d "$HOME/.local/share/icons/Material3-Expressive-Tokyo-Night-Dark-Icons" \
        && -d "$config_home/Kvantum/Material3-Expressive-Tokyo-Night" \
        && -d "$config_home/Kvantum/Material3-Expressive-Tokyo-Night-Dark" \
        && -d "$HOME/.local/share/sddm/themes/Material3-Expressive-Tokyo-Night-SDDM" ]]; then
        return 0
    fi

    local build_root
    build_root=$(mktemp -d "$cache_home/quickshell/material3-expressive-build.XXXXXX")
    cleanup_build() {
        [[ -n "${build_root:-}" ]] && rm -rf -- "$build_root"
    }
    trap cleanup_build EXIT

    local project
    for project in material3-expressive-theme material3-expressive-icons material3-expressive-kvantum material3-expressive-sddm; do
        mkdir -p -- "$build_root/$project"
        rsync -a --no-owner --no-group --exclude='.git' --exclude='dist' \
            "$projects_dir/$project/" "$build_root/$project/"
    done
    ln -s -- "$projects_dir/material3-expressive-shared" "$build_root/material3-expressive-shared"

    : >"$log_file"
    for project in material3-expressive-theme material3-expressive-icons material3-expressive-kvantum material3-expressive-sddm; do
        printf '\n=== %s ===\n' "$project" >>"$log_file"
        python3 "$build_root/$project/generate.py" >>"$log_file" 2>&1
    done

    jq -n \
        --arg digest "$palette_digest" \
        --arg generator "$generator_digest" \
        --arg wallpaper "$wallpaper" \
        '{paletteDigest: $digest, generatorDigest: $generator, wallpaper: $wallpaper, generatedAt: (now | todateiso8601)}' \
        >"$state_file"
    trap - EXIT
    cleanup_build
}

generate_dynamic_themes

if [[ "$palette_source" == "wallpaper" ]]; then
    gtk_theme="Material3-Expressive-Dynamic"
    icon_theme="Material3-Expressive-Dynamic-Icons"
    dark_value=0
    if [[ "$mode" == "dark" ]]; then
        gtk_theme="Material3-Expressive-Dynamic-Dark"
        icon_theme="Material3-Expressive-Dynamic-Dark-Icons"
        dark_value=1
    fi

    apply_gsettings "$gtk_theme" "$icon_theme" "$dark_value"
    apply_generated_css "$HOME/.themes/$gtk_theme"
    replace_setting "$config_home/qt6ct/qt6ct.conf" custom_palette false
    replace_setting "$config_home/qt6ct/qt6ct.conf" icon_theme "$icon_theme"
    sddm_theme="Material3-Expressive-Dynamic-SDDM"
    [[ "$mode" == "dark" ]] && sddm_theme="Material3-Expressive-Dynamic-Dark-SDDM"
    printf 'Applied Material 3 Expressive Dynamic (%s).\n' "$mode"
else
    gtk_theme="Material3-Expressive-Tokyo-Night"
    icon_theme="Material3-Expressive-Tokyo-Night-Icons"
    dark_value=0
    if [[ "$mode" == "dark" ]]; then
        gtk_theme="Material3-Expressive-Tokyo-Night-Dark"
        icon_theme="Material3-Expressive-Tokyo-Night-Dark-Icons"
        dark_value=1
    fi

    apply_gsettings "$gtk_theme" "$icon_theme" "$dark_value"
    apply_generated_css "$HOME/.themes/$gtk_theme"
    replace_setting "$config_home/qt6ct/qt6ct.conf" custom_palette false
    replace_setting "$config_home/qt6ct/qt6ct.conf" icon_theme "$icon_theme"
    sddm_theme="Material3-Expressive-Tokyo-Night-SDDM"
    [[ "$mode" == "dark" ]] && sddm_theme="Material3-Expressive-Tokyo-Night-Dark-SDDM"
    printf 'Applied Material 3 Expressive Static Tokyo Night (%s).\n' "$mode"
fi

set_kvantum_theme "$gtk_theme"
replace_setting "$config_home/qt6ct/qt6ct.conf" style "kvantum"

system_sddm_theme="/usr/share/sddm/themes/$sddm_theme"
current_sddm_theme=$(sed -n 's/^Current=//p' /etc/sddm.conf | head -n 1)
sddm_update_handled=false
if [[ "$current_sddm_theme" != "$sddm_theme" || ! -f "$system_sddm_theme/Main.qml" ]]; then
    user_sddm_theme="$HOME/.local/share/sddm/themes/$sddm_theme"
    if [[ ! -f "$user_sddm_theme/Main.qml" ]]; then
        printf 'Generated SDDM theme not found: %s\n' "$user_sddm_theme" >&2
        exit 1
    fi
    if polkit_agent_available && ! polkit_helper_socket_active; then
        if ! pkexec "$script_dir/install-sddm-theme.sh" "$sddm_theme" "$user_sddm_theme"; then
            notify_sddm_update critical \
                "SDDM theme update failed" \
                "Authorization was cancelled or unavailable. The session theme was applied, but SDDM remains unchanged."
            printf 'SDDM update requires authorization; session theme was applied without changing SDDM.\n' >&2
            exit 1
        fi
        notify_sddm_update normal \
            "SDDM theme updated" \
            "$sddm_theme is now selected for the next login screen."
        sddm_update_handled=true
    elif authorize_sddm_from_terminal "$sddm_theme" "$user_sddm_theme"; then
        sddm_update_handled=true
    else
        notify_sddm_update critical \
            "SDDM theme update failed" \
            "No working polkit agent or terminal is available for authorization."
        printf 'No authorization agent or terminal was found for the SDDM update.\n' >&2
        exit 1
    fi
fi

if [[ "$notify_requested" == true && "$sddm_update_handled" == false ]]; then
    notify_sddm_update normal \
        "Theme applied" \
        "The selected session theme is active. SDDM is already set to $sddm_theme."
fi
