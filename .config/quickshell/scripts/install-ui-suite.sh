#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
projects_dir=${UI_THEME_PROJECTS_DIR:-$HOME/Projects}
github_owner=${UI_THEME_GITHUB_OWNER:-hekatonkheirex}
sddm_theme_root=/usr/share/sddm/themes
dry_run=0
skip_sddm=0
skip_cursors=0
skip_nvim=0

usage() {
  cat <<'EOF'
Usage: install-ui-suite.sh [options]

Clone and install the four Quickshell UI style families without storing their
generated theme sources in yadm. Existing project directories are reused as-is.

Options:
  --projects-dir PATH  Theme checkout directory (default: ~/Projects)
  --github-owner NAME  GitHub owner (default: hekatonkheirex)
  --skip-sddm          Skip SDDM theme builds, bridge, and verification
  --skip-cursors       Skip the Ghost cursor build/install
  --skip-nvim          Skip the Neovim plugin-manager sync
  --dry-run            Print clones and commands without changing the system
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --projects-dir)
      [[ -n ${2:-} ]] || { printf '%s\n' 'Missing value for --projects-dir.' >&2; exit 2; }
      projects_dir=$2
      shift 2
      ;;
    --github-owner)
      [[ -n ${2:-} ]] || { printf '%s\n' 'Missing value for --github-owner.' >&2; exit 2; }
      github_owner=$2
      shift 2
      ;;
    --skip-sddm)
      skip_sddm=1
      shift
      ;;
    --skip-cursors)
      skip_cursors=1
      shift
      ;;
    --skip-nvim)
      skip_nvim=1
      shift
      ;;
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

repo_url() {
  printf 'https://github.com/%s/%s.git' "$github_owner" "$1"
}

die() {
  printf 'UI suite installation failed: %s\n' "$1" >&2
  exit 1
}

clone_repo() {
  local name=$1
  local destination="$projects_dir/$name"

  if [[ -d "$destination/.git" ]]; then
    printf 'Using existing checkout: %s\n' "$destination"
    return
  fi
  if [[ -e "$destination" ]]; then
    die "$destination exists but is not a Git checkout"
  fi
  if (( dry_run )); then
    printf '[dry-run] git clone --depth 1 %s %s\n' "$(repo_url "$name")" "$destination"
    return
  fi

  mkdir -p "$projects_dir"
  git clone --depth 1 "$(repo_url "$name")" "$destination"
}

run_step() {
  local label=$1
  local directory=$2
  shift 2

  if (( dry_run )); then
    printf '[dry-run] %s: (cd %s && ' "$label" "$directory"
    printf '%q ' "$@"
    printf ')\n'
    return
  fi

  printf '\n==> %s\n' "$label"
  (cd "$directory" && "$@")
}

install_sddm_dist() {
  local name=$1
  local dist_dir="$projects_dir/$name/dist"

  if (( dry_run )); then
    printf '[dry-run] copy %s/. -> %s/\n' "$dist_dir" "$sddm_theme_root"
    return
  fi
  [[ -d "$dist_dir" ]] || die "missing generated SDDM output: $dist_dir"
  command -v sudo >/dev/null 2>&1 || die 'sudo is required for system-wide SDDM themes'
  sudo install -d -m 0755 "$sddm_theme_root"
  sudo cp -r "$dist_dir/." "$sddm_theme_root/"
}

if (( ! dry_run )); then
  command -v git >/dev/null 2>&1 || die 'git is required'
  command -v python3 >/dev/null 2>&1 || die 'python3 is required'
fi

repos=(
  material3-expressive-shared
  material3-expressive-theme
  material3-expressive-icons
  material3-expressive-kvantum
  neo-brutalism-theme
  neo-brutalism-icons
  neo-brutalism-kvantum
  nothing-theme
  nothing-icons
  nothing-kvantum
  ghost-theme
  ghost-icons
  ghost-kvantum
)
if (( ! skip_sddm )); then
  repos+=(
    material3-expressive-sddm
    neo-brutalism-sddm
    nothing-sddm
    ghost-sddm
  )
fi
if (( ! skip_cursors )); then
  repos+=(ghost-cursors)
fi

for repo in "${repos[@]}"; do
  clone_repo "$repo"
done

# Material 3 owns the shared GTK build engine and current Matugen palette.
# Nothing, Neo, and Ghost consume that generated baseline, so keep this order.
run_step 'Material 3 GTK theme' "$projects_dir/material3-expressive-theme" python3 generate.py
run_step 'Material 3 icon themes' "$projects_dir/material3-expressive-icons" python3 generate.py
run_step 'Material 3 Kvantum themes' "$projects_dir/material3-expressive-kvantum" python3 generate.py

run_step 'Neo Brutalism GTK theme' "$projects_dir/neo-brutalism-theme" python3 generate.py
run_step 'Neo Brutalism icon themes' "$projects_dir/neo-brutalism-icons" make install
run_step 'Neo Brutalism Kvantum themes' "$projects_dir/neo-brutalism-kvantum" make install

run_step 'Nothing GTK theme' "$projects_dir/nothing-theme" python3 generate.py
run_step 'Nothing icon themes' "$projects_dir/nothing-icons" make install
run_step 'Nothing Kvantum themes' "$projects_dir/nothing-kvantum" make install

run_step 'Ghost GTK theme' "$projects_dir/ghost-theme" bash scripts/install.sh --dest "$HOME/.themes"
run_step 'Ghost icon themes' "$projects_dir/ghost-icons" bash scripts/install.sh
run_step 'Ghost Kvantum themes' "$projects_dir/ghost-kvantum" make install

if (( ! skip_cursors )); then
  run_step 'Ghost cursor build' "$projects_dir/ghost-cursors" python3 build.py
  run_step 'Ghost cursor install' "$projects_dir/ghost-cursors" bash install.sh
fi

if (( ! skip_sddm )); then
  run_step 'Material 3 SDDM themes' "$projects_dir/material3-expressive-sddm" python3 generate.py
  install_sddm_dist material3-expressive-sddm

  run_step 'Neo Brutalism SDDM themes' "$projects_dir/neo-brutalism-sddm" python3 generate.py
  install_sddm_dist neo-brutalism-sddm

  run_step 'Nothing SDDM themes' "$projects_dir/nothing-sddm" python3 generate.py --output dist
  install_sddm_dist nothing-sddm

  run_step 'Ghost SDDM theme build' "$projects_dir/ghost-sddm" make build
  if (( dry_run )); then
    printf '[dry-run] copy %s/.build/Ghost-SDDM/. -> %s/Ghost-SDDM/\n' "$projects_dir/ghost-sddm" "$sddm_theme_root"
  else
    command -v sudo >/dev/null 2>&1 || die 'sudo is required for system-wide Ghost SDDM'
    sudo install -d -m 0755 "$sddm_theme_root/Ghost-SDDM"
    sudo cp -r "$projects_dir/ghost-sddm/.build/Ghost-SDDM/." "$sddm_theme_root/Ghost-SDDM/"
  fi

  run_step 'Quickshell SDDM bridge' "$script_dir" bash "$script_dir/install-sddm-integration.sh"
  run_step 'SDDM integration verification' "$script_dir" bash "$script_dir/verify-sddm-integration.sh"
fi

if (( ! skip_nvim )); then
  if command -v nvim >/dev/null 2>&1; then
    run_step 'Neovim plugin sync' "$HOME" nvim --headless '+Lazy! sync' +qa
  else
    printf 'Warning: nvim not found; skipping Neovim plugin sync.\n' >&2
  fi
fi

sync_script="$HOME/.local/bin/sync-theme-mode.sh"
if [[ -x "$sync_script" ]]; then
  if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} || -n ${WAYLAND_DISPLAY:-} ]]; then
    if (( skip_sddm )); then
      run_step 'Active theme synchronization' "$HOME" bash "$sync_script" auto --quiet
    else
      run_step 'Active theme and SDDM synchronization' "$HOME" bash "$sync_script" auto --quiet '' --sync-sddm
    fi
  else
    printf 'Warning: no graphical session detected; run %s after login.\n' "$sync_script"
  fi
else
  printf 'Warning: theme synchronizer not found: %s\n' "$sync_script" >&2
fi

if (( dry_run )); then
  printf '[dry-run] UI suite verification\n'
else
  verification_args=()
  (( skip_sddm )) && verification_args+=(--skip-sddm)
  (( skip_cursors )) && verification_args+=(--skip-cursors)
  (( skip_nvim )) && verification_args+=(--skip-nvim)
  run_step 'UI suite verification' "$script_dir" bash "$script_dir/verify-ui-suite.sh" "${verification_args[@]}"
fi

printf '\nUI suite installation completed. Theme sources remain in %s and are not stored in yadm.\n' "$projects_dir"
