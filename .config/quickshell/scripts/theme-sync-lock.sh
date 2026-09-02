# Shared lock for every Quickshell-owned theme refresh path.
# Source this file before invoking a synchronizer. Nested calls inherit the
# descriptor and skip re-locking through QS_THEME_SYNC_LOCK_HELD.

if [[ "${QS_THEME_SYNC_LOCK_HELD:-0}" != "1" ]]; then
  if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    theme_sync_runtime_dir="$XDG_RUNTIME_DIR/quickshell"
  else
    theme_sync_runtime_dir="$HOME/.cache/quickshell"
  fi
  umask 077
  if ! mkdir -p -- "$theme_sync_runtime_dir" 2>/dev/null; then
    theme_sync_runtime_dir="${TMPDIR:-/tmp}/quickshell-${UID}"
    mkdir -p -- "$theme_sync_runtime_dir"
  fi
  if [[ "$(stat -c '%a' -- "$theme_sync_runtime_dir" 2>/dev/null || true)" != "700" ]]; then
    chmod 700 -- "$theme_sync_runtime_dir"
  fi
  exec 9>"$theme_sync_runtime_dir/theme-sync.lock"
  flock -x 9
  export QS_THEME_SYNC_LOCK_HELD=1
fi
