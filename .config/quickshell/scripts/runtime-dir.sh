#!/usr/bin/env bash

quickshell_runtime_dir() {
  if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    printf '%s/quickshell\n' "$XDG_RUNTIME_DIR"
  else
    printf '%s/.cache/quickshell/runtime\n' "$HOME"
  fi
}

ensure_quickshell_runtime_dir() {
  local runtime_dir=$1

  umask 077
  mkdir -p -- "$runtime_dir"
  if [[ "$(stat -c '%a' -- "$runtime_dir" 2>/dev/null || true)" != "700" ]]; then
    chmod 700 -- "$runtime_dir"
  fi
}
