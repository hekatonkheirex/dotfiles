#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=theme-sync-lock.sh
source "$script_dir/theme-sync-lock.sh"

# Mode changes select already-generated assets. Palette changes are responsible
# for regenerating and refreshing terminal assets, so do not repeat that work.
exec "$HOME/.local/bin/sync-theme-mode.sh" "$@"
